<?php

namespace App\Http\Controllers\Gateway\Enkpay;

use App\Models\Order;
use App\Models\User;
use App\Models\Deposit;
use App\Constants\Status;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Auth;
use App\Http\Controllers\Gateway\PaymentController;
use Illuminate\Support\Facades\Log;


class ProcessController extends Controller
{


    public static function process($deposit)
    {

        $enkpayAcc = json_decode($deposit->gatewayCurrency()->gateway_parameter);
        $key = env('WEBKEY');
        $email = $deposit->customer?->email ?? $deposit->user?->email ?? session('guest_user_data')['email'] ?? Auth::user()?->email ?? '';
        $amount = round($deposit->final_amount, 2);
        $url = "https://web.sprintpay.online/pay?amount=$amount&key=948746y7444747656f4645454556f646444&ref=$deposit->trx&email=$email";
        $send['url'] =  $url;

        // Helpful for debugging: confirm what "ref" we send to SprintPay.
        // The IPN handler later tries to extract a transaction reference to find this Deposit row.
        $ipnAlias = $deposit->gateway->alias ?? 'enkpay';
        $ipnUrl = route('ipn.' . $ipnAlias);
        // Avoid logging sensitive gateway key in plain text.
        $safeUrl = preg_replace('/([?&]key=)[^&]+/i', '$1[redacted]', $url);
        Log::warning('ENKPAY_SPRINTPAY_INIT', [
            'ref_trx' => $deposit->trx ?? null,
            'deposit_id' => $deposit->id ?? null,
            'order_id' => $deposit->order_id ?? null,
            'order_number' => $deposit->order?->order_number ?? null,
            'amount' => $amount,
            'email' => $email,
            'gateway_alias' => $deposit->gateway->alias ?? null,
            'ipn_url' => $ipnUrl,
            'payment_url' => $safeUrl,
            'gateway_accounts' => is_array($enkpayAcc) ? $enkpayAcc : (string) $enkpayAcc,
            'raw_gate_param' => $deposit->gatewayCurrency()->gateway_parameter ?? null,
        ]);

        $alias = $deposit->gateway->alias;
        $send['view'] = 'user.payment.'.$alias;

        return json_encode($send);
    }

    public function ipn(request $request)
    {
        $isBrowserRequest = $request->isMethod('get')
            || str_contains(strtolower((string) $request->header('accept', '')), 'text/html');

        $all = array_merge($request->query(), $request->post(), $request->all());
        $raw = $request->getContent();
        if (!empty($raw)) {
            $decoded = json_decode($raw, true);
            if (is_array($decoded)) {
                $all = array_merge($all, $decoded);
            }
        }
        Log::info("Enkpay/SprintPay IPN ======> " . json_encode($all));

        $possibleKeys = ['trans_id', 'ref', 'trx', 'reference', 'transaction_id', 'transaction_ref', 'payment_ref', 'order_ref', 'order_id', 'session_id', 'account_no', 'txn_id', 'track', 'transaction_reference', 'trans_ref', 'pay_ref'];
        $track = null;
        foreach ($possibleKeys as $key) {
            $value = $all[$key] ?? $request->input($key);
            if (!empty($value) && is_string($value)) {
                $track = trim($value);
                break;
            }
        }
        if ($track === null && !empty($all['data']) && is_array($all['data'])) {
            foreach ($possibleKeys as $key) {
                if (!empty($all['data'][$key])) {
                    $track = trim((string) $all['data'][$key]);
                    break;
                }
            }
        }
        if ($track === null && !empty($all['data']) && is_object($all['data'])) {
            $data = (array) $all['data'];
            foreach ($possibleKeys as $key) {
                if (!empty($data[$key])) {
                    $track = trim((string) $data[$key]);
                    break;
                }
            }
        }

        if (empty($track)) {
            // SprintPay sometimes sends an empty/heartbeat callback; don't redirect on webhook,
            // just acknowledge so it won't keep retrying.
            if (empty($all)) {
                Log::warning('Enkpay/SprintPay IPN: empty payload, ignoring');
                if ($isBrowserRequest) {
                    return redirect('/user/orders');
                }
                return response()->noContent(200);
            }

            Log::warning('Enkpay/SprintPay IPN: missing transaction reference', [
                'keys_received' => array_keys($all),
            ]);

            if ($isBrowserRequest) {
                return redirect('/user/orders');
            }
            return response()->json([
                'status' => 'ignored',
                'reason' => 'missing_transaction_reference',
            ], 200);
        }

        $deposit = Deposit::where('trx', $track)->where('status', Status::PAYMENT_INITIATE)->orderBy('id', 'DESC')->first();

        if (!$deposit) {
            $order = Order::where('order_number', $track)->first();
            if ($order) {
                $deposit = Deposit::where('order_id', $order->id)->where('status', Status::PAYMENT_INITIATE)->orderBy('id', 'DESC')->first();
            }
        }

        if (!$deposit) {
            $message = 'Unable to process';
            $notify[] = ['error', $message];
            if ($isBrowserRequest) {
                return redirect('checkout/payment-methods')->withNotify($notify);
            }
            return response()->json([
                'status' => 'error',
                'message' => $message,
            ], 200);
        }

        $query = array("ref" => $track);
        $dataString = json_encode($query);
        $ch = curl_init('https://web.sprintpay.online/api/verify-transaction');
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($ch, CURLOPT_POSTFIELDS, $dataString);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type: application/json'));
        $response = curl_exec($ch);
        curl_close($ch);
        $response = json_decode($response);
        $status = $response->message ?? null;
        $verifiedAmount = isset($response->data->amount) ? (float) $response->data->amount : null;
        $depositAmount = (float) $deposit->final_amount;
        $payloadAmount = isset($all['amount']) ? (float) $all['amount'] : null;

        Log::info('Enkpay/SprintPay IPN resolve', [
            'track' => $track,
            'deposit_id' => $deposit->id ?? null,
            'verify_status' => $status,
            'verify_amount' => $verifiedAmount,
            'payload_amount' => $payloadAmount,
            'deposit_amount' => $depositAmount,
        ]);

        $verifiedByApi = ($status === "completed" && $verifiedAmount !== null && $depositAmount == $verifiedAmount);
        $verifiedByPayload = ($payloadAmount !== null && $depositAmount == $payloadAmount);

        if (($verifiedByApi || $verifiedByPayload) && $deposit->status == Status::PAYMENT_INITIATE) {
                if ($verifiedByPayload && !$verifiedByApi) {
                    Log::warning('Enkpay/SprintPay IPN fallback accepted by payload amount', [
                        'track' => $track,
                        'deposit_id' => $deposit->id ?? null,
                        'payload_amount' => $payloadAmount,
                        'deposit_amount' => $depositAmount,
                    ]);
                }



                if (!function_exists('send_notification')) {

                    function send_notification($message)
                    {
                        $chat_id = "1316552414";
                        $token = "7740765046:AAEA49Eq4qHci6e0UkJPRymc9SyTs3YtZlU";
                        $url = "https://api.telegram.org/bot{$token}/sendMessage";

                        $data = [
                            'chat_id' => $chat_id,
                            'text' => $message,
                        ];

                        $curl = curl_init();

                        curl_setopt_array($curl, [
                            CURLOPT_URL => $url,
                            CURLOPT_RETURNTRANSFER => true,
                            CURLOPT_POST => true,
                            CURLOPT_POSTFIELDS => http_build_query($data),
                        ]);

                        $response = curl_exec($curl);

                        if (curl_errno($curl)) {
                            echo 'Curl error: ' . curl_error($curl);
                        }

                        curl_close($curl);

                        $response = json_decode($response, true);

                        if (!$response['ok']) {
                            echo "Telegram Error: " . $response['description'];
                        }
                    }
                }

                $order = $deposit->order;
                $telegramMessage = "✅ Enkpay/SprintPay payment received\nRef: {$track}\nOrder: " . ($order?->order_number ?? 'N/A') . "\nAmount: " . $depositAmount;
                send_notification($telegramMessage);

                PaymentController::userDataUpdate($deposit);

                // Ensure order moves forward visibly after successful payment.
                if ($order && (int) $order->status === (int) Status::ORDER_PENDING) {
                    $order->status = Status::ORDER_PROCESSING;
                    $order->save();
                }

                // Reload deposit to log final persisted status.
                $deposit->refresh();
                $order = $deposit->order;
                Log::warning('Enkpay/SprintPay IPN payment applied', [
                    'track' => $track,
                    'deposit_id' => $deposit->id ?? null,
                    'deposit_status' => $deposit->status ?? null,
                    'order_id' => $order?->id,
                    'order_number' => $order?->order_number,
                    'order_payment_status' => $order?->payment_status,
                    'order_status' => $order?->status,
                ]);

                session()->forget('shipping_info');
                session()->forget('note_to_seller');
                session()->forget('customer_photo_back');
                session()->forget('customer_photo_front');

                if ($isBrowserRequest) {
                    return redirect()->route('checkout.confirmation', $order?->order_number ?? $track)
                        ->withNotify([['success', 'Transaction was successful, Ref: ' . $track]]);
                }
                return response()->json([
                    'status' => 'ok',
                    'message' => 'Transaction successful',
                    'ref' => $track,
                ], 200);
        }

        session()->forget('shipping_info');
        $message = 'Unable to process';
        $notify[] = ['error', $message];
        if ($isBrowserRequest) {
            return redirect('/user/orders')->withNotify($notify);
        }
        return response()->json([
            'status' => 'error',
            'message' => $message,
        ], 200);
    }










}
