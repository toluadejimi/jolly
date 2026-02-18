<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    /**
     * GET /api/dashboard (requires API key).
     * Returns order counts and latest orders for the user dashboard.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $base = Order::where('user_id', $user->id)->isValidOrder();

        $orderCounts = [
            'total' => (clone $base)->count(),
            'pending' => (clone $base)->pending()->count(),
            'processing' => (clone $base)->processing()->count(),
            'dispatched' => (clone $base)->dispatched()->count(),
            'delivered' => (clone $base)->delivered()->count(),
            'canceled' => (clone $base)->canceled()->count(),
        ];

        $latestOrders = (clone $base)
            ->with('orderDetail.product')
            ->orderByDesc('id')
            ->limit(6)
            ->get()
            ->map(fn ($order) => [
                'id' => $order->id,
                'order_number' => $order->order_number,
                'subtotal' => (float) $order->subtotal,
                'shipping_charge' => (float) $order->shipping_charge,
                'total_amount' => (float) $order->total_amount,
                'payment_status' => $order->payment_status == \App\Constants\Status::PAYMENT_SUCCESS ? 'paid' : 'unpaid',
                'status' => $this->statusLabel($order->status),
                'created_at' => $order->created_at->toIso8601String(),
            ]);

        return response()->json([
            'remark' => 'dashboard',
            'status' => 'success',
            'message' => ['success' => ['Dashboard data retrieved.']],
            'data' => [
                'order_counts' => $orderCounts,
                'latest_orders' => $latestOrders,
            ],
        ]);
    }

    private function statusLabel(int $status): string
    {
        return match ($status) {
            \App\Constants\Status::ORDER_PENDING => 'pending',
            \App\Constants\Status::ORDER_PROCESSING => 'processing',
            \App\Constants\Status::ORDER_DISPATCHED => 'dispatched',
            \App\Constants\Status::ORDER_DELIVERED => 'delivered',
            \App\Constants\Status::ORDER_CANCELED => 'canceled',
            \App\Constants\Status::ORDER_RETURNED => 'returned',
            default => 'pending',
        };
    }
}
