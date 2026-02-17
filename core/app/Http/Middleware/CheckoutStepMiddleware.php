<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class CheckoutStepMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Illuminate\Http\Response|\Illuminate\Http\RedirectResponse)  $next
     * @return \Illuminate\Http\Response|\Illuminate\Http\RedirectResponse
     */
    public function handle(Request $request, Closure $next, $module)
    {
        $checkoutData = session('shipping_info');
        $hasPhysicalProduct = cartManager()->checkPhysicalProductExistence();
        if ($module == 'shipping_info') {
            if (!cartManager()->setCartCount()) {
                return to_route('cart.page');
            }
        } elseif ($module == 'delivery_method' && !@$checkoutData) {
            return to_route('checkout.shipping.info');
        } elseif ($module == 'payment' && $hasPhysicalProduct) {
            if (!@$checkoutData) {
                return to_route('checkout.delivery.methods');
            }
            $required = ['firstname', 'lastname', 'address', 'city', 'state', 'zip', 'country', 'mobile'];
            $hasSavedId = !empty($checkoutData['shipping_address_id']) && auth()->check();
            if (!$hasSavedId) {
                foreach ($required as $key) {
                    $v = $checkoutData[$key] ?? '';
                    if (!is_string($v) || trim($v) === '') {
                        return to_route('checkout.shipping.info')->with('error', 'Please complete all shipping details (including phone) before payment.');
                    }
                }
            }
        }
        return $next($request);
    }
}
