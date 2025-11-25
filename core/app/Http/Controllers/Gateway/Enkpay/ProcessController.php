<?php

namespace App\Http\Controllers\Gateway\Enkpay;

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
        $email = session('guest_user_data')['email'] ?? Auth::user()->email;
        $amount = round($deposit->final_amount, 2);
        $url = "https://web.sprintpay.online/pay?amount=$amount&key=948746y7444747656f4645454556f646444&ref=$deposit->trx&email=$email";
        $send['url'] =  $url;

        $alias = $deposit->gateway->alias;
        $send['view'] = 'user.payment.'.$alias;

        return json_encode($send);
    }

    public function ipn(request $request)
    {


        LOG::info("payment one ======>".json_encode($request->all()));


        if($request->trans_id == null){

            LOG::info("payment two ======>".json_encode($request->order_id));
        }


        $track = $request->trans_id ?? $request->order_id;



        $deposit = Deposit::where('trx', $track)->orderBy('id', 'DESC')->first();

        if (!isset($deposit)) {

            $message = 'Unable to process';
            $notify[] = ['error', $message];

            return redirect('checkout/payment-methods')->withNotify($notify);

        }else{

            $query = array(
                "ref" => $track
            );

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

            if($status == "completed" && $deposit->final_amount == $response->data->amount && $deposit->status == Status::PAYMENT_INITIATE){





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


                PaymentController::userDataUpdate($deposit);

                session()->forget('shipping_info');
                session()->forget('note_to_seller');
                session()->forget('customer_photo_back');
                session()->forget('customer_photo_front');


                $message = 'Transaction was successful, Ref: ' . $track;
                    $notify[] = ['success', $message];
                    $notifyApi[] = $message;
                    return redirect($deposit->success_url)->withNotify($notify);
            }else{

                session()->forget('shipping_info');
                $message = 'Unable to process';
                $notify[] = ['error', $message];

                return redirect('cart')->withNotify($notify);


            }


        }


        $message = 'Unable to process';
        $notify[] = ['error', $message];

        return back()->withNotify($notify);


    }










}
