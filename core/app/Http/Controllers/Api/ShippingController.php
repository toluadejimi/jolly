<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ShippingMethod;
use Illuminate\Http\JsonResponse;

class ShippingController extends Controller
{
    /**
     * List active shipping methods for checkout.
     */
    public function index(): JsonResponse
    {
        $methods = ShippingMethod::active()->orderBy('id')->get();

        $list = $methods->map(fn ($m) => [
            'id' => $m->id,
            'name' => $m->name ?? 'Delivery',
            'charge' => (float) ($m->charge ?? 0),
        ]);

        return response()->json([
            'remark' => 'shipping_methods',
            'status' => 'success',
            'message' => ['success' => ['Shipping methods retrieved.']],
            'data' => ['shipping_methods' => $list],
        ]);
    }
}
