@extends('Template::layouts.master')

@section('content')
    @php
        $baseUrl = url('/api');
    @endphp
    <div class="py-60">
        <div class="container">
            <div class="row justify-content-center">
                <div class="col-lg-10">
                    <nav class="mb-3 small">
                        <a href="{{ route('home') }}">@lang('Home')</a>
                        <span class="text-muted mx-2">/</span>
                        <span class="text-muted">@lang('API Documentation')</span>
                    </nav>
                    <div class="mb-4">
                        <h1 class="mb-2">@lang('API Documentation')</h1>
                        <p class="text-muted">@lang('Connect your applications to place orders and process payments. Generate an API key from your') <a href="{{ route('user.login') }}">@lang('account')</a> @lang('dashboard (API Keys).')</p>
                    </div>

                    <section class="mb-5">
                        <h2 class="h5 mb-3">@lang('Base URL')</h2>
                        <pre class="bg-light p-3 rounded"><code>{{ $baseUrl }}</code></pre>
                    </section>

                    <section class="mb-5">
                        <h2 class="h5 mb-3">@lang('Authentication')</h2>
                        <p>@lang('Endpoints that require authentication expect your API key in one of these ways:')</p>
                        <ul>
                            <li><strong>Header:</strong> <code>X-API-Key: your_api_key</code></li>
                            <li><strong>Header:</strong> <code>Authorization: Bearer your_api_key</code></li>
                        </ul>
                        <p class="text-muted small">@lang('Replace') <code>your_api_key</code> @lang('with the key you generated from your dashboard. Keep it secret.')</p>
                    </section>

                    <section class="mb-5">
                        <h2 class="h5 mb-3">@lang('Response format')</h2>
                        <p>@lang('All responses are JSON with') <code>status</code> (@lang('success')/@lang('error')), <code>message</code>, @lang('and') <code>data</code> @lang('when applicable. Errors return HTTP 4xx/5xx with') <code>message.error</code>.</p>
                    </section>

                    <hr class="my-5">

                    <h2 class="h4 mb-4">@lang('Endpoints')</h2>

                    <div class="api-endpoint mb-5">
                        <h3 class="h6 text-primary">GET /api/products</h3>
                        <p class="small text-muted">@lang('List products. No API key required.')</p>
                        <p><strong>@lang('Query:')</strong> <code>per_page</code> (default 15, max 50), <code>search</code>, <code>category_id</code>, <code>brand_id</code></p>
                        <p><strong>@lang('Example:')</strong></p>
                        <pre class="bg-light p-3 rounded small"><code>GET {{ $baseUrl }}/products?per_page=10</code></pre>
                    </div>

                    <div class="api-endpoint mb-5">
                        <h3 class="h6 text-primary">GET /api/products/{id}</h3>
                        <p class="small text-muted">@lang('Get a single product by ID. No API key required.')</p>
                        <pre class="bg-light p-3 rounded small"><code>GET {{ $baseUrl }}/products/1</code></pre>
                    </div>

                    <div class="api-endpoint mb-5">
                        <h3 class="h6 text-primary">GET /api/payment-methods</h3>
                        <p class="small text-muted">@lang('List available payment methods. Requires API key.')</p>
                        <pre class="bg-light p-3 rounded small"><code>GET {{ $baseUrl }}/payment-methods
X-API-Key: your_api_key</code></pre>
                    </div>

                    <div class="api-endpoint mb-5">
                        <h3 class="h6 text-primary">POST /api/orders</h3>
                        <p class="small text-muted">@lang('Create an order. Requires API key.')</p>
                        <p><strong>@lang('Body (JSON):')</strong></p>
                        <pre class="bg-light p-3 rounded small"><code>{
  "items": [
    { "product_id": 1, "quantity": 2 },
    { "product_id": 2, "quantity": 1, "product_variant_id": 5 }
  ],
  "shipping_address": {
    "firstname": "John",
    "lastname": "Doe",
    "mobile": "1234567890",
    "email": "john@example.com",
    "country": "United States",
    "city": "New York",
    "state": "NY",
    "zip": "10001",
    "address": "123 Main St"
  },
  "shipping_method_id": 1,
  "coupon_code": "SAVE10"
}</code></pre>
                        <p class="small">@lang('Response includes') <code>order_id</code>, <code>order_number</code>, <code>total_amount</code>. @lang('Then call') <strong>POST /api/payment/initiate</strong> @lang('to get the payment URL.')</p>
                    </div>

                    <div class="api-endpoint mb-5">
                        <h3 class="h6 text-primary">GET /api/orders</h3>
                        <p class="small text-muted">@lang('List your orders. Requires API key.')</p>
                        <p><strong>@lang('Query:')</strong> <code>per_page</code>, <code>status</code> (pending, processing, dispatched, delivered, canceled)</p>
                        <pre class="bg-light p-3 rounded small"><code>GET {{ $baseUrl }}/orders?status=pending
X-API-Key: your_api_key</code></pre>
                    </div>

                    <div class="api-endpoint mb-5">
                        <h3 class="h6 text-primary">GET /api/orders/{order_id_or_number}</h3>
                        <p class="small text-muted">@lang('Get order details. Requires API key.')</p>
                        <pre class="bg-light p-3 rounded small"><code>GET {{ $baseUrl }}/orders/OID-00001
X-API-Key: your_api_key</code></pre>
                    </div>

                    <div class="api-endpoint mb-5">
                        <h3 class="h6 text-primary">POST /api/payment/initiate</h3>
                        <p class="small text-muted">@lang('Get payment URL for an unpaid order. Requires API key.')</p>
                        <p><strong>@lang('Body (JSON):')</strong></p>
                        <pre class="bg-light p-3 rounded small"><code>{
  "order_id": 123,
  "gateway": "stripe",
  "currency": "USD"
}</code></pre>
                        <p class="small">@lang('Or use gateway currency id from') <code>GET /api/payment-methods</code>: <code>"gateway": 5</code></p>
                        <p class="small">@lang('Response includes') <code>payment_url</code>. @lang('Redirect the customer to this URL to complete payment.')</p>
                    </div>

                    <hr class="my-5">
                    <p class="text-muted small">@lang('Rate limit: 60 requests per minute per IP. For more help, contact support.')</p>
                </div>
            </div>
        </div>
    </div>
@endsection
