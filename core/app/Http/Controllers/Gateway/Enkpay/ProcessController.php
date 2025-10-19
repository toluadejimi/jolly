<?php

namespace App\Http\Controllers\Gateway\Enkpay;

use App\Models\User;
use App\Models\Deposit;
use App\Constants\Status;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Auth;
use App\Http\Controllers\Gateway\PaymentController;


class ProcessController extends Controller
{


    public static function process($deposit)
    {

        $enkpayAcc = json_decode($deposit->gatewayCurrency()->gateway_parameter);
        $key = env('WEBKEY');
        $email = session('guest_user_data')['email'] ?? Auth::user()->email;
        $amount = round($deposit->final_amount, 2);
        $url = "https://web.sprintpay.online/pay?amount=$amount&key=$key&ref=$deposit->trx&email=$email";
        $send['url'] =  $url;


        $alias = $deposit->gateway->alias;

        $send['view'] = 'user.payment.'.$alias;

        return json_encode($send);
    }

    public function ipn(request $request)
    {
        $track = $request->trans_id;


        $deposit = Deposit::where('trx', $track)->orderBy('id', 'DESC')->first();


        if (!isset($deposit)) {

            $message = 'Unable to process';
            $notify[] = ['error', $message];

            return redirect($deposit->failed_url)->withNotify($notify);

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
                PaymentController::userDataUpdate($deposit);

                session()->forget('shipping_info');


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
