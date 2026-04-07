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
        $ipnAlias = strtolower((string) ($deposit->gateway->alias ?? 'enkpay'));
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
            'gateway_accounts' => $enkpayAcc ? json_decode(json_encode($enkpayAcc), true) : null,
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

        // Mobile "direct pay" flow used order_number as SprintPay ref but never created a Deposit via /api/payment/initiate.
        if (!$deposit && !empty($all['order_id']) && is_string($all['order_id'])) {
            $on = trim($all['order_id']);
            $orderOnly = Order::where('order_number', $on)->first();
            if ($orderOnly && (int) $orderOnly->payment_status === (int) Status::PAYMENT_SUCCESS) {
                if ($isBrowserRequest) {
                    return redirect()->route('checkout.confirmation', $orderOnly->order_number);
                }
                return response()->json(['status' => 'ok', 'message' => 'already_paid'], 200);
            }
            if ($orderOnly && (int) $orderOnly->payment_status !== (int) Status::PAYMENT_SUCCESS) {
                $payloadAmount = isset($all['amount']) ? (float) $all['amount'] : null;
                $payloadEmail = isset($all['email']) ? strtolower(trim((string) $all['email'])) : '';
                $ship = $orderOnly->shipping_address;
                $orderEmail = strtolower(trim((string) ($orderOnly->user?->email ?? (is_object($ship) && isset($ship->email) ? $ship->email : ''))));
                $orderAmount = (float) $orderOnly->total_amount;
                $candidateRefs = self::collectSprintPayRefs($all, $track, $orderOnly->order_number);
                $verifyHit = self::firstCompletedSprintPayVerify($candidateRefs, $orderAmount);
                $amountVsOrder = $payloadAmount !== null && self::amountCloseEnough($payloadAmount, $orderAmount);
                $emailOk = $payloadEmail !== '' && $orderEmail !== '' && $payloadEmail === $orderEmail;
                if ($verifyHit !== null || ($amountVsOrder && $emailOk)) {
                    $orderOnly->payment_status = Status::PAYMENT_SUCCESS;
                    if ((int) $orderOnly->status === (int) Status::ORDER_PENDING) {
                        $orderOnly->status = Status::ORDER_PROCESSING;
                    }
                    $orderOnly->save();
                    if ($orderOnly->user_id) {
                        cartManager()->clearUserCart('user_id', $orderOnly->user_id);
                    }
                    if ($orderOnly->user) {
                        try {
                            sendOrderPlacedNotification($orderOnly->user, $orderOnly);
                        } catch (\Throwable $e) {
                            Log::error('Enkpay IPN order-only notify: ' . $e->getMessage());
                        }
                    }
                    Log::warning('Enkpay/SprintPay IPN: order marked paid without deposit (mobile direct-pay path)', [
                        'order_number' => $orderOnly->order_number,
                        'order_id' => $orderOnly->id,
                        'payload_amount' => $payloadAmount,
                        'verify_used_ref' => $verifyHit['ref'] ?? null,
                    ]);
                    if ($isBrowserRequest) {
                        return redirect()->route('checkout.confirmation', $orderOnly->order_number)
                            ->withNotify([['success', 'Transaction was successful']]);
                    }
                    return response()->json([
                        'status' => 'ok',
                        'message' => 'Transaction successful',
                        'order_number' => $orderOnly->order_number,
                    ], 200);
                }
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

        $depositAmount = (float) $deposit->final_amount;
        $payloadAmount = isset($all['amount']) ? (float) $all['amount'] : null;
        $candidateRefs = self::collectSprintPayRefs($all, $track, $deposit->trx, $deposit->order?->order_number);
        $verifyHit = self::firstCompletedSprintPayVerify($candidateRefs, $depositAmount);
        $response = null;
        $status = null;
        $verifiedAmount = null;
        if ($verifyHit !== null) {
            $response = $verifyHit['raw'];
            $status = $verifyHit['status'];
            $verifiedAmount = $verifyHit['amount'];
        } else {
            $response = self::sprintPayVerifyTransaction($track);
            $status = $response ? ($response->message ?? null) : null;
            $verifiedAmount = ($response && isset($response->data->amount)) ? (float) $response->data->amount : null;
        }

        Log::info('Enkpay/SprintPay IPN resolve', [
            'track' => $track,
            'deposit_id' => $deposit->id ?? null,
            'verify_status' => $status,
            'verify_amount' => $verifiedAmount,
            'payload_amount' => $payloadAmount,
            'deposit_amount' => $depositAmount,
        ]);

        $verifiedByApi = ($status === 'completed' && $verifiedAmount !== null && self::amountCloseEnough($depositAmount, $verifiedAmount));
        $verifiedByPayload = ($payloadAmount !== null && self::amountCloseEnough($depositAmount, $payloadAmount));

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

    /**
     * SprintPay amounts may be rounded (e.g. mobile paynow) or differ slightly from stored floats.
     */
    private static function amountCloseEnough(float $expected, float $actual): bool
    {
        return abs($expected - $actual) <= max(1.0, abs($expected) * 0.01);
    }

    private static function sprintPayVerifyTransaction(string $ref): ?\stdClass
    {
        $dataString = json_encode(['ref' => $ref]);
        $ch = curl_init('https://web.sprintpay.online/api/verify-transaction');
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');
        curl_setopt($ch, CURLOPT_POSTFIELDS, $dataString);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        $response = curl_exec($ch);
        curl_close($ch);
        $decoded = json_decode($response ?? '');

        return $decoded instanceof \stdClass ? $decoded : null;
    }

    /**
     * @return array{ref: string, status: string, amount: float, raw: \stdClass}|null
     */
    private static function firstCompletedSprintPayVerify(array $refs, float $expectedAmount): ?array
    {
        foreach ($refs as $ref) {
            if (!is_string($ref) || $ref === '') {
                continue;
            }
            $raw = self::sprintPayVerifyTransaction($ref);
            if (!$raw) {
                continue;
            }
            $st = $raw->message ?? null;
            $amt = isset($raw->data->amount) ? (float) $raw->data->amount : null;
            if ($st === 'completed' && $amt !== null && self::amountCloseEnough($expectedAmount, $amt)) {
                return ['ref' => $ref, 'status' => (string) $st, 'amount' => $amt, 'raw' => $raw];
            }
        }

        return null;
    }

    private static function collectSprintPayRefs(array $all, string $track, ...$extra): array
    {
        $candidates = [
            $all['session_id'] ?? null,
            $all['ref'] ?? null,
            $all['trx'] ?? null,
            $track,
            ...$extra,
        ];
        $out = [];
        foreach ($candidates as $v) {
            if (!is_string($v)) {
                continue;
            }
            $v = trim($v);
            if ($v !== '') {
                $out[] = $v;
            }
        }

        return array_values(array_unique($out));
    }






}
