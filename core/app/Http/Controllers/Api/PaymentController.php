<?php

namespace App\Http\Controllers\Api;

use App\Constants\Status;
use App\Http\Controllers\Controller;
use App\Models\Deposit;
use App\Models\GatewayCurrency;
use App\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    public function methods(Request $request): JsonResponse
    {
        $hasPhysicalProduct = true; // API orders can have physical products
        $gateways = GatewayCurrency::whereHas('method', fn ($g) => $g->where('status', Status::ENABLE))
            ->with('method:id,code,name,alias')
            ->orderBy('method_code', 'desc')
            ->get();

        $list = [];
        foreach ($gateways as $g) {
            if ($g->id == 0) {
                if (gs('cod') && $hasPhysicalProduct) {
                    $list[] = ['id' => 0, 'method_code' => 0, 'name' => 'COD', 'currency' => gs('cur_text'), 'symbol' => gs('cur_sym')];
                }
                continue;
            }
            $list[] = [
                'id' => $g->id,
                'method_code' => $g->method_code,
                'name' => $g->name ?? $g->method->name . ' ' . $g->currency,
                'currency' => $g->currency,
                'symbol' => $g->symbol ?? '$',
            ];
        }

        return response()->json([
            'remark' => 'payment_methods',
            'status' => 'success',
            'message' => ['success' => ['Payment methods retrieved.']],
            'data' => ['payment_methods' => $list],
        ]);
    }

    public function initiate(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'order_id' => 'required|integer',
            'gateway' => 'required', // method_code (e.g. stripe, paypal) or gateway_currency id
            'currency' => 'nullable|string|max:10',
        ]);

        $user = $request->user();
        $order = Order::where('user_id', $user->id)->find($validated['order_id']);
        if (!$order) {
            return response()->json([
                'remark' => 'not_found',
                'status' => 'error',
                'message' => ['error' => ['Order not found.']],
            ], 404);
        }

        if ($order->payment_status == Status::PAYMENT_SUCCESS) {
            return response()->json([
                'remark' => 'validation_error',
                'status' => 'error',
                'message' => ['error' => ['Order is already paid.']],
            ], 422);
        }

        $gatewayCurrency = null;
        if (is_numeric($validated['gateway']) && (int) $validated['gateway'] === 0 && gs('cod')) {
            $gatewayCurrency = (new GatewayCurrency())->codMethod();
        } elseif (is_numeric($validated['gateway'])) {
            $gatewayCurrency = GatewayCurrency::whereHas('method', fn ($g) => $g->where('status', Status::ENABLE))
                ->where('id', (int) $validated['gateway'])
                ->with('method')
                ->first();
        } else {
            $currency = $validated['currency'] ?? gs('cur_text');
            $gatewayCurrency = GatewayCurrency::whereHas('method', fn ($g) => $g->where('status', Status::ENABLE))
                ->where('method_code', $validated['gateway'])
                ->where('currency', $currency)
                ->with('method')
                ->first();
        }

        if (!$gatewayCurrency) {
            return response()->json([
                'remark' => 'validation_error',
                'status' => 'error',
                'message' => ['error' => ['Invalid payment method. Use GET /api/payment-methods to list available methods.']],
            ], 422);
        }

        $hasPhysicalProduct = $order->hasPhysicalProduct();
        if (!$hasPhysicalProduct && $gatewayCurrency->id == 0) {
            return response()->json([
                'remark' => 'validation_error',
                'status' => 'error',
                'message' => ['error' => ['COD is not available for this order.']],
            ], 422);
        }

        $trx = $order->initiatePayment($gatewayCurrency, $order->total_amount);
        $deposit = Deposit::where('trx', $trx)->where('status', Status::PAYMENT_INITIATE)->with('gateway')->first();
        if (!$deposit) {
            return response()->json([
                'remark' => 'server_error',
                'status' => 'error',
                'message' => ['error' => ['Failed to create payment.']],
            ], 500);
        }

        if ($deposit->method_code >= 1000) {
            return response()->json([
                'remark' => 'validation_error',
                'status' => 'error',
                'message' => ['error' => ['Manual payment is not supported via API. Complete payment offline and notify admin.']],
            ], 422);
        }

        $dirName = $deposit->gateway->alias;
        $processClass = \App\Http\Controllers\Gateway::class . '\\' . $dirName . '\\ProcessController';
        if (!class_exists($processClass)) {
            return response()->json([
                'remark' => 'server_error',
                'status' => 'error',
                'message' => ['error' => ['Payment gateway not configured.']],
            ], 500);
        }

        Log::warning(
            'API payment initiate: calling gateway process. alias=' . ($deposit->gateway->alias ?? 'unknown') .
            ', trx=' . ($trx ?? 'null') .
            ', processClass=' . $processClass
        );

        $data = $processClass::process($deposit);
        $data = json_decode($data);

        if (isset($data->error)) {
            return response()->json([
                'remark' => 'gateway_error',
                'status' => 'error',
                'message' => ['error' => [$data->message ?? 'Payment initiation failed.']],
            ], 422);
        }

        $paymentUrl = $data->redirect_url ?? $data->url ?? null;
        if (!$paymentUrl) {
            return response()->json([
                'remark' => 'gateway_error',
                'status' => 'error',
                'message' => ['error' => ['No payment URL returned from gateway.']],
            ], 500);
        }

        return response()->json([
            'remark' => 'payment_initiated',
            'status' => 'success',
            'message' => ['success' => ['Redirect customer to payment_url to complete payment.']],
            'data' => [
                'order_id' => $order->id,
                'order_number' => $order->order_number,
                'total_amount' => (float) $order->total_amount,
                'payment_url' => $paymentUrl,
                'trx' => $trx,
            ],
        ]);
    }
}
