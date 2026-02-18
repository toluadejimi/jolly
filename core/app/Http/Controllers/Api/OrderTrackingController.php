<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\JsonResponse;

class OrderTrackingController extends Controller
{
    /**
     * Public order tracking by order number (no auth required).
     * Used by the Flutter app and any client that only has the order number.
     */
    public function show(string $orderNumber): JsonResponse
    {
        $orderData = Order::isValidOrder()->where('order_number', $orderNumber)->first();

        if (!$orderData) {
            return response()->json([
                'success' => false,
                'error' => 'No order found with this order number.',
            ], 404);
        }

        $payload = [
            'success' => true,
            'order_number' => $orderData->order_number,
            'payment_status' => $orderData->payment_status,
            'status' => $orderData->status,
            'is_cod' => $orderData->is_cod,
        ];

        if ($orderData->estimated_delivery_at) {
            if ($orderData->estimated_delivery_end_at && $orderData->estimated_delivery_end_at->format('Y-m-d') != $orderData->estimated_delivery_at->format('Y-m-d')) {
                $payload['estimated_delivery_at'] = $orderData->estimated_delivery_at->format('M j, Y') . ' – ' . $orderData->estimated_delivery_end_at->format('M j, Y');
            } else {
                $payload['estimated_delivery_at'] = $orderData->estimated_delivery_at->format('l, F j, Y');
            }
        } else {
            $payload['estimated_delivery_at'] = null;
        }

        $payload['tracking_url'] = $orderData->tracking_url ?: null;
        $payload['tracking_number'] = $orderData->tracking_number ?: null;

        return response()->json($payload);
    }
}
