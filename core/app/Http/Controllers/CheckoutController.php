<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Lib\CartManager;
use App\Models\Deposit;
use App\Models\Guest;
use App\Models\Order;
use App\Models\OrderDetail;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\ShippingAddress;
use App\Models\ShippingMethod;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Facades\Storage;

class CheckoutController extends Controller
{
    private $cartManager;

    public function __construct(CartManager $cartManager)
    {
        parent::__construct();
        $this->cartManager = $cartManager;
    }


    public function storeGuestUser(Request $request)
    {


        $cartItems = $this->cartManager->getCart();

        $note = Product::where('id', $cartItems[0]['product_id'])->first()->note;
        $customised_test = Product::where('id', $cartItems[0]['product_id'])->first()->customised_test;
        $customised_short_test = Product::where('id', $cartItems[0]['product_id'])->first()->customised_short_test;
        $customer_photo = Product::where('id', $cartItems[0]['product_id'])->first()->customer_photo;


        $countryData = (array)json_decode(file_get_contents(resource_path('views/partials/country.json')));
        $countryCodes = implode(',', array_keys($countryData));
        $mobileCodes = implode(',', array_column($countryData, 'dial_code'));
        $countries = implode(',', array_column($countryData, 'country'));

        $request->validate([
            'email' => 'required|email',
            //    'mobile'       => 'required|regex:/^([0-9]*)$/',
//            'country_code' => 'required|in:' . $countryCodes,
//            'country'      => 'required|in:' . $countries,
//            'mobile_code'  => 'required|in:' . $mobileCodes,
        ]);


        $note = Product::where('id', $cartItems[0]['product_id'])->first()->note;
        $guest = Guest::where('email', $request->email)->where('mobile', $request->mobile)->where('dial_code', $request->mobile_code)->firstOrNew();
        $guest->email = $request->email;
        $guest->dial_code = 0;
        $guest->country_name = 0;
        $guest->country_code = 0;
        $guest->mobile = $request->mobile;
        $guest->session_id = getSessionId();
        $guest->save();

        session()->put('guest_user_data', $guest);
        session()->put('note', $note);
        session()->put('customised_test', $customised_test);
        session()->put('customised_short_test', $customised_short_test);
        session()->put('customer_photo', $customer_photo);


        return redirect()->route('checkout.shipping.info');
    }

    public function storeGuestShippingInfo(Request $request)
    {
        $request->validate([
            'firstname' => 'required|string|max:255',
            'lastname'  => 'required|string|max:255',
            'email'    => 'required|email',
            'address'  => 'required|string|max:500',
            'city'     => 'required|string|max:255',
            'state'    => 'required|string|max:255',
            'zip'      => 'required|string|max:40',
            'country'  => 'required|string|max:255',
        ], [
            'firstname.required' => 'Receiver first name is required.',
            'lastname.required'  => 'Receiver last name is required.',
            'address.required'   => 'Street address is required.',
            'city.required'      => 'City is required.',
            'state.required'     => 'State / County is required.',
            'zip.required'       => 'Postcode / ZIP is required.',
            'country.required'   => 'Country is required.',
        ]);

        $note_charge = !empty($request->note_to_seller) ? 5000 : 0;

        // ----- CART CHECKOUT: no product_id = checkout from cart (multiple items) -----
        if (!$request->filled('product_id')) {
            $cartItems = $this->cartManager->getCart();
            if ($cartItems->isEmpty()) {
                $notify[] = ['error', 'Your cart is empty.'];
                return to_route('cart.page')->withNotify($notify);
            }

            $shippingMethod = ShippingMethod::active()->first();
            $shippingMethodId = $shippingMethod ? $shippingMethod->id : 0;

            session()->put('shipping_info', [
                'firstname' => $request->firstname,
                'lastname' => $request->lastname,
                'mobile' => $request->mobile ?? '',
                'email' => $request->email,
                'city' => $request->city,
                'state' => $request->state,
                'apt' => $request->apt ?? '',
                'zip' => $request->zip,
                'country' => $request->country,
                'country_code' => $request->country_code ?? '',
                'dial_code' => $request->mobile_code ?? '',
                'address' => $request->address,
                'note_to_seller' => $request->note_to_seller ?? null,
                'note_charge' => $note_charge,
                'shipping_method_id' => $shippingMethodId,
                'front_picture' => null,
                'back_picture' => null,
                'customized_text' => $request->customised_test ?? null,
                'customized_short_text' => $request->customised_short_test ?? null,
            ]);

            if (!empty($request->note_to_seller)) {
                session()->put('note_to_seller', $request->note_to_seller);
            }

            return redirect()->route('checkout.payment.redirect');
        }

        // ----- SINGLE PRODUCT CHECKOUT (from product page "Buy Now") -----
        $product = Product::where('id', $request->product_id)->first();
        if (!$product) {
            $notify[] = ['error', 'Product not found.'];
            return back()->withNotify($notify);
        }

        $get_variant = ProductVariant::where('product_id', $request->product_id)->first() ?? null;
        $variant = null;

        if ($get_variant) {

            $variantAttributes = json_decode($request->variant_attributes, true);

            $selectedIds = collect($variantAttributes)
                ->pluck('id')
                ->filter()
                ->map(fn($id) => (int)$id)
                ->unique()
                ->values()
                ->toArray();

            $variant = ProductVariant::where('product_id', $request->product_id)
                ->where('attribute_values', json_encode($selectedIds)) // attributes = "[65]"
                ->first();


        }

        if ($get_variant && !$variant) {
            $notify[] = ['error', 'Please select a valid product option (variant).'];
            return back()->withNotify($notify);
        }

        if ($get_variant && $variant) {
            $price = $variant->regular_price;
        } else {
            $price = $product->regular_price ?? 0;
        }

        $order_id = "JOLFR" . random_int(0000, 9999);

        $fullShippingAddress = [
            'firstname' => $request->firstname ?? '',
            'lastname'  => $request->lastname ?? '',
            'mobile'    => $request->mobile ?? '',
            'email'     => $request->email ?? '',
            'country'   => $request->country ?? '',
            'city'      => $request->city ?? '',
            'state'     => $request->state ?? '',
            'zip'       => $request->zip ?? '',
            'address'   => $request->address ?? '',
            'apt'       => $request->apt ?? '',
        ];

        $shippingData = [
            'firstname' => $request->firstname,
            'lastname' => $request->lastname,
            'mobile' => $request->mobile,
            'email' => $request->email,
            'city' => $request->city,
            'state' => $request->state,
            'apt' => $request->apt,
            'zip' => $request->zip,
            'country_code' => $request->country_code,
            'dial_code' => $request->mobile_code,
            'country' => $request->country,
            'address' => $request->address,
            'note_to_seller' => $request->note_to_seller,
            'customised_test' => $request->customised_test,
            'customised_short_test' => $request->customised_short_test,
            'back_picture' => $backPath ?? null,
            'front_picture' => $frontPath ?? null,
            'note_charge' => $note_charge ?? 0,
            'order_number' => $order_id,
            'user_id' => Auth::id(),
            'shipping_address' => $fullShippingAddress,
            'subtotal' => $price,
            'total_amount' => $price + $note_charge,
        ];


        $order = Order::create($shippingData);

        if ($order) {


            if ($request->front_picture != null || $request->back_picture != null) {


                $request->validate([
                    'front_picture' => 'required|image|mimes:jpeg,png,jpg|max:2048',
                ]);

                $frontPath = $request->file('front_picture')->store('temp_photos', 'public');
                $backPath = $request->file('back_picture')->store('temp_photos', 'public');


            }


        }


        $order_detail = [
            'order_id' => $order->id,
            'product_id' => $product->id,
            'product_variant_id' => $variant->id ?? 0,
            'quantity' => 1,
            'price' => $price,
            'note' => $request->note_to_seller,
            'customised_test' => $request->customised_test,
            'customised_short_test' => $request->customised_short_test,
            'front_photo' => $frontPath ?? null,
            'back_photo' => $backPath ?? null,
        ];

        $order_details = OrderDetail::create($order_detail);


        if ($order_details) {

            $deposit = new Deposit();
            $deposit->user_id = Auth::id() ?? 0;
            $deposit->order_id = $order->id;
            $deposit->method_code = "127";
            $deposit->amount = $price + $note_charge;
            $deposit->method_currency = "NGN";
            $deposit->final_amount = $price + $note_charge;
            $deposit->trx = $order_id;
            $deposit->success_url = url('') . "/order-confirmation/" . $order_id;
            $deposit->failed_url = url('') . "/products/" . $order_id;
            $deposit->save();

            Log::warning('ENKPAY_SPRINTPAY_DEPOSIT_CREATED (CheckoutController)', [
                'deposit_id' => $deposit->id ?? null,
                'order_id' => $deposit->order_id ?? null,
                'trx_ref' => $deposit->trx ?? null,
                'method_code' => $deposit->method_code ?? null,
                'method_currency' => $deposit->method_currency ?? null,
                'amount' => $deposit->amount ?? null,
                'final_amount' => $deposit->final_amount ?? null,
                'success_url' => $deposit->success_url ?? null,
                'failed_url' => $deposit->failed_url ?? null,
                'user_id' => Auth::id() ?? 0,
            ]);

            if ($deposit) {

                $enkpayAcc = json_decode($deposit->gatewayCurrency()->gateway_parameter);
                $key = env('WEBKEY');
                $email = Auth::user()->email;
                $amount = round($deposit->final_amount, 2);
                $url = "https://web.sprintpay.online/pay?amount=$amount&key=948746y7444747656f4645454556f646444&ref=$deposit->trx&email=$email";
                $send['url'] = $url;


                $safeUrl = preg_replace('/([?&]key=)[^&]+/i', '$1[redacted]', $url);
                Log::warning('ENKPAY_SPRINTPAY_PAYMENT_URL (CheckoutController)', [
                    'deposit_id' => $deposit->id ?? null,
                    'trx_ref' => $deposit->trx ?? null,
                    'order_id' => $deposit->order_id ?? null,
                    'email' => $email ?? null,
                    'amount' => $amount,
                    'payment_url' => $safeUrl,
                    'enkpay_gateway_parameter' => $enkpayAcc ?? null,
                ]);

                return redirect()->away($send['url']);


            }


        }


    }


    //============= checkout step start here ===================//
    public function shippingInfo()
    {
        $pageTitle = 'Shipping Information';
        $cartItems = $this->cartManager->getCart();

        $shippingAddresses = ShippingAddress::where('user_id', auth()->id())->get();

        $cartItems = $this->cartManager->getCart();
        foreach ($cartItems as $cartItem) {
            $product = $cartItem->product;

            if ($product->categories->isNotEmpty()) {
                $categoryId = $product->categories->first()->pivot->category_id;


                if (in_array($categoryId, [4, 5, 7, 9, 11])) {
                    $countries = getusaCountries();
                } elseif ($categoryId == 6) {
                    $countries = getusacanadaCountries();
                } else {

                    $countries = getCountries();

                }
            }

        }


        if (auth()->user()) {
            // Same as guest: show receiver-details form (no saved-address selection)
            $firstItem = $cartItems->first();
            if ($firstItem && $firstItem->product) {
                $p = $firstItem->product;
                session()->put('note', $p->note);
                session()->put('customer_photo', $p->customer_photo);
                session()->put('customised_test', $p->customised_test);
                session()->put('customised_short_test', $p->customised_short_test);
            }
            $view = 'Template::checkout_steps.shipping_info_guest';
        } else {

            if (!gs('guest_checkout')) {
                abort(404);
            }
            $session = session()->get('guest_user_data');

            if (!$session) {
                $notify[] = ['error', 'Session Expired'];
                return to_route('cart.page')->withNotify($notify);
            }

            // Same as auth: set note/photo/custom from first cart item for simple checkout form
            $firstItem = $cartItems->first();
            if ($firstItem && $firstItem->product) {
                $p = $firstItem->product;
                session()->put('note', $p->note);
                session()->put('customer_photo', $p->customer_photo);
                session()->put('customised_test', $p->customised_test);
                session()->put('customised_short_test', $p->customised_short_test);
            }

            $view = 'Template::checkout_steps.shipping_info_guest';

        }


        return view($view, compact('pageTitle', 'shippingAddresses', 'countries'));


    }

    public function addShippingInfo(Request $request)
    {
        if (auth()->user()) {
            $ids = ShippingAddress::where('user_id', auth()->id())->pluck('id')->toArray();
            $request->validate([
                'shipping_address_id' => 'required|in:' . implode(',', $ids ?: [0])
            ], [
                'shipping_address_id.required' => 'Shipping address is required',
                'shipping_address_id.in' => 'Invalid address selected'
            ]);

            $checkoutData = session('shipping_info') ?? [];
            $checkoutData['shipping_address_id'] = $request->shipping_address_id;
            $defaultShipping = ShippingMethod::active()->first();
            $checkoutData['shipping_method_id'] = $defaultShipping ? $defaultShipping->id : 1;
            session()->put('shipping_info', $checkoutData);

            return to_route('checkout.payment.redirect');
        }

        $ids = ShippingAddress::where('user_id', auth()->id())->pluck('id')->toArray();
        $request->validate([
            'shipping_address_id' => 'required|in:' . implode(',', $ids)
        ], [
            'shipping_address_id.required' => 'Shipping address is required',
            'shipping_address_id.in' => 'Invalid address selected'
        ]);

        $checkoutData = session('shipping_info');
        $checkoutData['shipping_address_id'] = $request->shipping_address_id;
        session()->put('shipping_info', $checkoutData);
        return to_route('checkout.delivery.methods');
    }

    public function deliveryMethods()
    {
        $pageTitle = 'Delivery Methods';
        $shippingMethods = ShippingMethod::active()->get();
        return view('Template::checkout_steps.shipping_methods', compact('pageTitle', 'shippingMethods'));
    }

    public function addDeliveryMethod(Request $request)
    {
        $ids = ShippingMethod::active()->pluck('id')->toArray();

        $request->validate([
            'shipping_method_id' => 'required|in:' . implode(',', $ids)
        ], [
            'shipping_method_id.required' => 'Delivery type field is required',
            'shipping_method_id.in' => 'Invalid delivery type selected'
        ]);

        $checkoutData = session('shipping_info');
        $checkoutData['shipping_method_id'] = $request->shipping_method_id;


        session()->put('shipping_info', $checkoutData);
        return to_route('checkout.payment.redirect');
    }

    public function confirmation($orderNumber)
    {
        $order = Order::where('order_number', $orderNumber)->with('deposit', 'orderDetail.product', 'orderDetail.productVariant', 'appliedCoupon')->first();

        $pageTitle = 'Order Number -' . $order->order_number;

        return view('Template::checkout_steps.confirmation', compact('pageTitle', 'order'));
    }

    public function uploadPhoto(request $request)
    {

        $request->validate([
            'front_picture' => 'required|image|mimes:jpeg,png,jpg|max:2048',
            'back_picture' => 'required|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        $frontPath = $request->file('front_picture')->store('temp_photos', 'public');
        $backPath = $request->file('back_picture')->store('temp_photos', 'public');


        session([
            'customer_photo_front' => $frontPath,
            'customer_photo_back' => $backPath,
        ]);

        $notify[] = ['success', 'Photos uploaded successfully'];
        return back()->withNotify($notify);


    }

    public function uploadNote(request $request)
    {

        $request->validate([
            'note_to_seller' => 'required|string|max:250',
        ]);

        session(['note_to_seller' => $request->note_to_seller]);

        $notify[] = ['success', 'Noted successfully added'];
        return back()->withNotify($notify);

    }

    public function uploadCustomisedTest(request $request)
    {

        $request->validate([
            'customized_text' => 'required|string|max:5000',
        ]);


        session(['customized_text' => $request->customized_text]);

        $notify[] = ['success', 'Customized Text successfully added'];
        return back()->withNotify($notify);

    }


    public function uploadCustomisedShortTest(request $request)
    {

        $request->validate([
            'customized_short_text' => 'required|string|max:5000',
        ]);


        session(['customized_short_text' => $request->customized_short_text]);

        $notify[] = ['success', 'Short Customized Text successfully added'];
        return back()->withNotify($notify);

    }

    public function removePhoto($type)
    {
        if ($type === 'front' && session()->has('customer_photo_front')) {
            $path = 'public/' . session('customer_photo_front');
            if (Storage::exists($path)) {
                Storage::delete($path);
            }
            session()->forget('customer_photo_front');
        }

        if ($type === 'back' && session()->has('customer_photo_back')) {
            $path = 'public/' . session('customer_photo_back');
            if (Storage::exists($path)) {
                Storage::delete($path);
            }

            session()->forget('customer_photo_back');
        }

        return back()->with('success', 'Photo removed successfully.');
    }


    private function appliedCoupon($cartData, $subtotal)
    {
        $coupon = session('coupon');

        if (!$coupon) {
            return null;
        }

        // Match the coupon code with database and check is exists
        $coupon = $this->cartManager->getCouponByCode($coupon['code']);

        if (!$coupon) {
            return ['error' => "Applied coupon is invalid or expired"];
        }

        $checkCoupon = $this->cartManager->isValidCoupon($coupon, $subtotal, $cartData);

        if (isset($checkCoupon['error'])) {
            return $checkCoupon;
        }

        $coupon->discount_amount = $coupon->discountAmount($subtotal);
        return $coupon;
    }


    public function LoginProduct(Request $request)
    {
        $request->validate([
            'username' => 'required',   // email or username depending on your system
            'password' => 'required',
        ]);


        $credentials = [
            'email' => $request->username,
            'password' => $request->password,
        ];

        $remember = $request->filled('remember');

        // login attempt
        if (Auth::attempt($credentials, $remember)) {
            $request->session()->regenerate();

            $notify[] = ['success', 'Login successful'];

            return redirect()->back()->withNotify($notify);
        }

        $notify[] = ['error', 'Invalid login details'];
        return redirect()->back()->withNotify($notify)->withInput();
    }

    public function update(Request $request)
    {
        $cart = session()->get('cart', []);

        if(isset($cart[$request->id])) {
            if($request->action == "increase") {
                $cart[$request->id]['quantity']++;
            } elseif($request->action == "decrease" && $cart[$request->id]['quantity'] > 1) {
                $cart[$request->id]['quantity']--;
            }

            session()->put('cart', $cart);
        }

        return back();
    }
    public function add(Request $request)
    {
        $product = Product::findOrFail($request->id);

        $cart = session()->get('cart', []);

        // Unique key for product + variants
        $variantKey = $request->variant ?? 'simple';
        $cartKey = $product->id . '_' . $variantKey;

        if(isset($cart[$cartKey])) {
            $cart[$cartKey]['quantity']++;
        } else {
            $cart[$cartKey] = [
                "name" => $product->name,
                "price" => $product->salePrice(),
                "quantity" => 1,
                "image" => getImage(getFilePath('product') . '/' . $product->image),
                "variant" => $request->variant
            ];
        }

        session()->put('cart', $cart);

        return response()->json([
            'status' => 'success',
            'message' => 'Product added to cart'
        ]);
    }
}
