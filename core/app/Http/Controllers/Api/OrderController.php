<?php

namespace App\Http\Controllers\Api;

use App\Constants\Status;
use App\Http\Controllers\Controller;
use App\Lib\CartManager;
use App\Lib\ProductManager;
use App\Models\AppliedCoupon;
use App\Models\Coupon;
use App\Models\Order;
use App\Models\OrderDetail;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\ShippingMethod;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class OrderController extends Controller
{
    /**
     * Upload customer product photos (front/back). Returns storage paths to pass to orders store.
     */
    public function uploadCustomerPhotos(Request $request): JsonResponse
    {
        $request->validate([
            'front_picture' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
            'back_picture' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
        ], [
            'front_picture.image' => 'Front picture must be an image (JPG, PNG).',
            'front_picture.max' => 'Front picture must not exceed 2MB.',
            'back_picture.image' => 'Back picture must be an image (JPG, PNG).',
            'back_picture.max' => 'Back picture must not exceed 2MB.',
        ]);

        $data = [];
        if ($request->hasFile('front_picture')) {
            $data['front_path'] = $request->file('front_picture')->store('temp_photos', 'public');
        }
        if ($request->hasFile('back_picture')) {
            $data['back_path'] = $request->file('back_picture')->store('temp_photos', 'public');
        }

        return response()->json([
            'remark' => 'photos_uploaded',
            'status' => 'success',
            'message' => ['success' => ['Photos uploaded.']],
            'data' => $data,
        ]);
    }

    /**
     * Confirm payment for an order (e.g. after SprintPay returns status=paid).
     * Sets order payment_status to paid and status to processing.
     */
    public function confirmPayment(Request $request, int $orderId): JsonResponse
    {
        $user = $request->user();
        $order = Order::where('id', $orderId)->where('user_id', $user->id)->first();
        if (!$order) {
            return response()->json([
                'remark' => 'order_not_found',
                'status' => 'error',
                'message' => ['error' => ['Order not found.']],
            ], 404);
        }
        if ($order->payment_status == Status::PAYMENT_SUCCESS) {
            return response()->json([
                'remark' => 'payment_confirmed',
                'status' => 'success',
                'message' => ['success' => ['Order is already paid.']],
            ]);
        }
        $order->payment_status = Status::PAYMENT_SUCCESS;
        $order->status = Status::ORDER_PROCESSING;
        $order->save();
        return response()->json([
            'remark' => 'payment_confirmed',
            'status' => 'success',
            'message' => ['success' => ['Order marked as paid and processing.']],
        ]);
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $orders = Order::where('user_id', $user->id)
            ->isValidOrder()
            ->with('orderDetail.product', 'conversation')
            ->orderByDesc('id')
            ->when($request->filled('status'), function ($q) use ($request) {
                $status = $request->status;
                if ($status === 'pending') $q->pending();
                elseif ($status === 'processing') $q->processing();
                elseif ($status === 'dispatched') $q->dispatched();
                elseif ($status === 'delivered') $q->delivered();
                elseif ($status === 'canceled') $q->canceled();
            })
            ->paginate(min((int) $request->get('per_page', 15), 50));

        $items = $orders->getCollection()->map(function ($order) {
            $conv = $order->conversation;
            return [
                'id' => $order->id,
                'order_number' => $order->order_number,
                'subtotal' => (float) $order->subtotal,
                'shipping_charge' => (float) $order->shipping_charge,
                'total_amount' => (float) $order->total_amount,
                'payment_status' => $order->payment_status == Status::PAYMENT_SUCCESS ? 'paid' : 'unpaid',
                'status' => $this->orderStatusLabel($order->status),
                'created_at' => $order->created_at->toIso8601String(),
                'conversation' => $conv ? [
                    'conversation_id' => $conv->id,
                    'unread_count' => $conv->unreadCountForUser(),
                ] : null,
            ];
        });

        return response()->json([
            'remark' => 'orders_list',
            'status' => 'success',
            'message' => ['success' => ['Orders retrieved.']],
            'data' => [
                'orders' => $items,
                'pagination' => [
                    'current_page' => $orders->currentPage(),
                    'last_page' => $orders->lastPage(),
                    'per_page' => $orders->perPage(),
                    'total' => $orders->total(),
                ],
            ],
        ]);
    }

    public function show(Request $request, $orderRef): JsonResponse
    {
        $user = $request->user();
        $order = Order::where('user_id', $user->id)
            ->where(fn ($q) => $q->where('id', $orderRef)->orWhere('order_number', $orderRef))
            ->with(['orderDetail.product', 'orderDetail.productVariant', 'appliedCoupon', 'conversation'])
            ->firstOrFail();

        $items = $order->orderDetail->map(function ($d) {
            $product = $d->product;
            $variant = $d->productVariant;
            $imageUrl = null;
            if ($variant && $variant->main_image_id) {
                $imageUrl = $variant->mainImage(true);
            }
            if (!$imageUrl && $product) {
                $imageUrl = $product->mainImage(true);
            }
            return [
                'product_id' => $d->product_id,
                'product_name' => $product->name ?? null,
                'quantity' => $d->quantity,
                'price' => (float) $d->price,
                'subtotal' => (float) ($d->price * $d->quantity),
                'image_url' => $imageUrl,
            ];
        });

        $estimatedDelivery = null;
        if ($order->estimated_delivery_at) {
            if ($order->estimated_delivery_end_at && $order->estimated_delivery_end_at->format('Y-m-d') != $order->estimated_delivery_at->format('Y-m-d')) {
                $estimatedDelivery = $order->estimated_delivery_at->format('M j, Y') . ' – ' . $order->estimated_delivery_end_at->format('M j, Y');
            } else {
                $estimatedDelivery = $order->estimated_delivery_at->format('l, F j, Y');
            }
        }

        $conv = $order->conversation;
        return response()->json([
            'remark' => 'order_detail',
            'status' => 'success',
            'message' => ['success' => ['Order retrieved.']],
            'data' => [
                'order' => [
                    'id' => $order->id,
                    'order_number' => $order->order_number,
                    'shipping_address' => $order->shipping_address,
                    'subtotal' => (float) $order->subtotal,
                    'shipping_charge' => (float) $order->shipping_charge,
                    'total_amount' => (float) $order->total_amount,
                    'payment_status' => $order->payment_status == Status::PAYMENT_SUCCESS ? 'paid' : 'unpaid',
                    'status' => $this->orderStatusLabel($order->status),
                    'created_at' => $order->created_at->toIso8601String(),
                    'estimated_delivery_at' => $estimatedDelivery,
                    'tracking_number' => $order->tracking_number ?: null,
                    'tracking_url' => $order->tracking_url ?: null,
                    'items' => $items,
                    'conversation' => $conv ? [
                        'conversation_id' => $conv->id,
                        'unread_count' => $conv->unreadCountForUser(),
                    ] : null,
                ],
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|integer|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.product_variant_id' => 'nullable|integer|exists:product_variants,id',
            'shipping_address' => 'required|array',
            'shipping_address.firstname' => 'required|string|max:40',
            'shipping_address.lastname' => 'required|string|max:40',
            'shipping_address.mobile' => 'required|string|max:40',
            'shipping_address.email' => 'nullable|email',
            'shipping_address.country' => 'required|string|max:255',
            'shipping_address.city' => 'required|string|max:255',
            'shipping_address.state' => 'nullable|string|max:255',
            'shipping_address.zip' => 'nullable|string|max:40',
            'shipping_address.address' => 'required|string',
            'shipping_address.apt' => 'nullable|string|max:255',
            'shipping_method_id' => 'required|integer',
            'coupon_code' => 'nullable|string|max:40',
            'note_to_seller' => 'nullable|string|max:250',
            'note_charge' => 'nullable|numeric|min:0',
            'customised_test' => 'nullable|string|max:5000',
            'customised_short_test' => 'nullable|string|max:5000',
            'front_photo' => 'nullable|string|max:500',
            'back_photo' => 'nullable|string|max:500',
        ]);

        $shippingMethod = ShippingMethod::active()->find($validated['shipping_method_id']);
        if (!$shippingMethod) {
            return response()->json([
                'remark' => 'validation_error',
                'status' => 'error',
                'message' => ['error' => ['Invalid shipping method.']],
            ], 422);
        }

        $cartLike = [];
        $subtotal = 0;

        foreach ($validated['items'] as $item) {
            $product = Product::published()->with('productVariants')->find($item['product_id']);
            if (!$product) {
                return response()->json([
                    'remark' => 'validation_error',
                    'status' => 'error',
                    'message' => ['error' => ["Product #{$item['product_id']} is not available."]],
                ], 422);
            }

            $variant = null;
            if (!empty($item['product_variant_id'])) {
                $variant = ProductVariant::where('product_id', $product->id)->find($item['product_variant_id']);
                if (!$variant) {
                    return response()->json([
                        'remark' => 'validation_error',
                        'status' => 'error',
                        'message' => ['error' => ["Invalid variant for product #{$product->id}."]],
                    ], 422);
                }
            }

            $qty = (int) $item['quantity'];
            if ($product->track_inventory ?? false) {
                $stock = $product->inStock($variant);
                if ($qty > $stock) {
                    return response()->json([
                        'remark' => 'validation_error',
                        'status' => 'error',
                        'message' => ['error' => ["Insufficient stock for product: {$product->name}. Available: {$stock}."]],
                    ], 422);
                }
            }

            $prices = $product->prices($variant);
            $salePrice = $prices->sale_price ?? $prices->regular_price ?? $product->regular_price;
            $lineTotal = $salePrice * $qty;
            $subtotal += $lineTotal;

            $cartLike[] = (object) [
                'product_id' => $product->id,
                'product_variant_id' => $variant ? $variant->id : null,
                'quantity' => $qty,
                'product' => $product,
                'productVariant' => $variant,
            ];
        }

        $coupon = null;
        $couponAmount = 0;
        if (!empty($validated['coupon_code'])) {
            $coupon = Coupon::activeAndValid()->matchCode($validated['coupon_code'])
                ->with(['categories', 'products'])->withCount('appliedCoupons')
                ->withCount(['appliedCoupons as user_applied_count' => fn ($q) => $q->where('user_id', $request->user()->id)])
                ->first();
            if (!$coupon) {
                return response()->json([
                    'remark' => 'validation_error',
                    'status' => 'error',
                    'message' => ['error' => ['Invalid or expired coupon code.']],
                ], 422);
            }
            $cartManager = app(CartManager::class);
            $check = $cartManager->isValidCoupon($coupon, $subtotal, collect($cartLike));
            if (is_array($check) && isset($check['error'])) {
                return response()->json([
                    'remark' => 'validation_error',
                    'status' => 'error',
                    'message' => ['error' => [$check['error']]],
                ], 422);
            }
            $couponAmount = $coupon->discountAmount($subtotal);
            $couponAmount = min($couponAmount, $subtotal);
        }

        $shippingCharge = $shippingMethod->charge ?? 0;
        $noteCharge = (int) ($validated['note_charge'] ?? 0);
        $totalAmount = getAmount($subtotal + $shippingCharge + $noteCharge - $couponAmount);

        $order = new Order();
        $order->order_number = $this->getOrderNumber();
        $order->user_id = $request->user()->id;
        $order->guest_id = null;
        $order->shipping_address = $validated['shipping_address'];
        $order->shipping_method_id = $shippingMethod->id;
        $order->shipping_charge = $shippingCharge;
        $order->is_cod = 0;
        $order->payment_status = Status::PAYMENT_INITIATE;
        $order->status = Status::ORDER_PENDING;
        $order->subtotal = $subtotal;
        $order->total_amount = $totalAmount;
        $order->save();

        if ($coupon) {
            $applied = new AppliedCoupon();
            $applied->user_id = $request->user()->id;
            $applied->coupon_id = $coupon->id;
            $applied->order_id = $order->id;
            $applied->amount = $couponAmount;
            $applied->save();
        }

        $noteToSeller = $validated['note_to_seller'] ?? null;
        $customisedTest = $validated['customised_test'] ?? null;
        $customisedShortTest = $validated['customised_short_test'] ?? null;
        $frontPhoto = $validated['front_photo'] ?? null;
        $backPhoto = $validated['back_photo'] ?? null;

        foreach ($cartLike as $cartItem) {
            $prices = $cartItem->product->prices($cartItem->productVariant);
            $salePrice = $prices->sale_price ?? $prices->regular_price ?? $cartItem->product->regular_price;
            $regularPrice = $prices->regular_price ?? $cartItem->product->regular_price;
            $detail = new OrderDetail();
            $detail->order_id = $order->id;
            $detail->product_id = $cartItem->product_id;
            $detail->product_variant_id = $cartItem->product_variant_id ?? 0;
            $detail->quantity = $cartItem->quantity;
            $detail->price = $salePrice;
            $detail->discount = $regularPrice - $salePrice;
            $detail->note = $noteToSeller;
            $detail->customised_test = $customisedTest;
            $detail->customised_short_test = $customisedShortTest;
            $detail->front_photo = $frontPhoto;
            $detail->back_photo = $backPhoto;
            $detail->save();
            $this->updateStock($cartItem, $order->id);
        }

        // Do NOT notify Telegram on order creation only.
        // Telegram notification is sent when payment succeeds (see payment success flow).

        return response()->json([
            'remark' => 'order_created',
            'status' => 'success',
            'message' => ['success' => ['Order created. Use payment/initiate to get payment URL.']],
            'data' => [
                'order_id' => $order->id,
                'order_number' => $order->order_number,
                'subtotal' => (float) $order->subtotal,
                'shipping_charge' => (float) $order->shipping_charge,
                'total_amount' => (float) $order->total_amount,
                'payment_status' => 'unpaid',
            ],
        ], 201);
    }

    private function getOrderNumber(int $digit = 5): string
    {
        $prefix = 'OID-';
        $last = Order::max('id') + 1;
        return $prefix . str_pad((string) $last, $digit, '0', STR_PAD_LEFT);
    }

    private function updateStock(object $cartItem, int $orderId): void
    {
        $product = $cartItem->product;
        $variant = $cartItem->productVariant;
        $item = $variant ?? $product;
        if ($item->track_inventory ?? false) {
            $item->in_stock -= $cartItem->quantity;
            $item->save();
            $pm = new ProductManager();
            $pm->createStockLog($product, $cartItem->quantity, 'Sold via API', $variant, '-', $orderId);
        }
    }

    private function orderStatusLabel(int $status): string
    {
        return match ($status) {
            Status::ORDER_PENDING => 'pending',
            Status::ORDER_PROCESSING => 'processing',
            Status::ORDER_DISPATCHED => 'dispatched',
            Status::ORDER_DELIVERED => 'delivered',
            Status::ORDER_CANCELED => 'canceled',
            Status::ORDER_RETURNED => 'returned',
            default => 'pending',
        };
    }
}
