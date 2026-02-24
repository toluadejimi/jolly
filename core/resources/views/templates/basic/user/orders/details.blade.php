@extends($activeTemplate . 'layouts.' . $layout)

@php
    $sectionName = $layout == 'user' ? 'panel' : 'content';
@endphp

@section($sectionName)
    @if ($layout != 'user')
        <div class="container py-60">
    @endif
    <div class="order-details">
        <div class="order-details-top justify-content-between">
            <div>
                <span>
                    @php echo $order->paymentBadge() @endphp
                    @php echo $order->statusBadge() @endphp
                </span>
            </div>
            <div class="d-flex align-items-center flex-wrap gap-2">
                <h5 class="order-details-id mb-1 d-flex align-items-center flex-wrap gap-3">
                    <span class="order-details-id">#{{ $order->order_number }}
                </h5>
                <span> {{ showDateTime($order->created_at, 'd F, Y') }}</span>
                <a href="{{ route('user.orders.conversation.show', $order->order_number) }}" class="btn btn--primary btn-sm">
                    <i class="las la-comment-dots"></i> @lang('Contact Seller')
                </a>
            </div>
        </div>

        <div class="order-details-products mb-3">
            <div class="table-responsive">
                <table class="table table-bordered table--responsive--md">
                    <thead>
                        <tr>
                            <th>@lang('Product')</th>
                            <th>@lang('Price')</th>
                            <th>@lang('Quantity')</th>
                            <th>@lang('Total Price')</th>
                        </tr>
                    </thead>
                    <tbody>
                        @php
                            $subtotal = $order->orderDetail->sum(function ($detail) {
                                return $detail->price * $detail->quantity;
                            });
                        @endphp

                        @foreach ($order->orderDetail as $data)
                            @php
                                $mainImage = $data->productVariant && @$data->productVariant->main_image_id ? $data->productVariant->mainImage(true) : @$data->product->mainImage(true);
                            @endphp

                            <tr>
                                <td>
                                    <div class="single-product-item  align-items-center">
                                        <div class="thumb">
                                            <img class="lazyload" src="{{ getImage(null) }}" data-src="{{ $mainImage }}" alt="{{ @$data->product->name ?? 'product' }}">
                                        </div>

                                        <div class="content d-flex flex-column">
                                            {{ @$data->product->name }}

                                            @if ($data->productVariant)
                                                - {{ @$data->productVariant->name }}
                                            @endif

                                            @if ($data->product->is_downloadable && $order->status == Status::ORDER_DELIVERED && $order->payment_status == Status::PAYMENT_SUCCESS)
                                                <a href="{{ route('order.item.download', encrypt($data->id)) }}" class="fw-light text-decoration-underline">
                                                    <i class="la la-download"></i> @lang('Download')
                                                </a>
                                            @endif
                                        </div>
                                    </div>
                                </td>
                                <td> {{ showAmount($data->price) }}</td>
                                <td>{{ $data->quantity }}</td>
                                <td class="text-end">{{ showAmount($data->price * $data->quantity) }}</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>

        <div class="row g-3 flex-md-row-reverse">
            <div class="col-md-6">
                <div class="details-info-list">
                    <h6 class="mb-3">@lang('Order Summary')</h6>
                    <ul>
                        <li>
                            <span>@lang('Subtotal')</span>
                            <span class="fw-semibold">{{ showAmount($subtotal, 2) }}</span>
                        </li>
                        @if ($order->appliedCoupon)
                            <li>
                                <span>(<i class="la la-minus"></i>) @lang('Coupon')
                                    ({{ $order->appliedCoupon->coupon->coupon_code }})</span>
                                <span> {{ showAmount($order->appliedCoupon->amount, 2) }}</span>
                            </li>
                        @endif

                        <li>
                            <span>(<i class="la la-plus"></i>) @lang('Shipping')</span>
                            <span>{{ showAmount($order->shipping_charge, 2) }}</span>
                        </li>

                        <li class="total">
                            <span>@lang('Total')</span>
                            <span>{{ showAmount($order->total_amount) }}</span>
                        </li>
                    </ul>
                </div>

                @if (isset($order->deposit) && $order->deposit->status != 0)
                    <div class="details-info-list">
                        <h6 class="mb-3">@lang('Payment Details')</h6>
                        <ul>
                            <li>
                                <span>@lang('Payment Method')</span>
                                <span>
                                    @if ($order->deposit->method_code == 0)
                                        @lang('Cash On Delivery')
                                    @else
                                        {{ __($order->deposit->gateway->name) }}
                                    @endif
                                </span>
                            </li>

                            <li>
                                <span>@lang('Total Bill')</span>
                                <span>{{ showAmount($order->total_amount) }}</span>
                            </li>

                            @if (@$order->deposit->charge > 0)
                                <li>
                                    <span>@lang('Gateway Charge')</span>
                                    <span>{{ gs('cur_sym') . getAmount(@$order->deposit->charge) }}</span>
                                </li>
                            @endif

                            <li class="total">
                                <span>@lang('Total Payable Amount') </span>
                                <span>{{ gs('cur_sym') . getAmount($order->deposit->amount + @$order->deposit->charge) }}</span>
                            </li>

                        </ul>
                    </div>
                @endif

                @if ($order->estimated_delivery_at)
                    <div class="details-info-list mt-3">
                        <h6 class="mb-3">@lang('Estimated Delivery')</h6>
                        <p class="mb-0 text--primary fw-semibold">
                            <i class="las la-clock"></i>
                            @if ($order->estimated_delivery_end_at && $order->estimated_delivery_end_at->format('Y-m-d') != $order->estimated_delivery_at->format('Y-m-d'))
                                {{ $order->estimated_delivery_at->format('M j, Y') }} – {{ $order->estimated_delivery_end_at->format('M j, Y') }}
                            @else
                                {{ $order->estimated_delivery_at->format('l, F j, Y') }}
                            @endif
                        </p>
                    </div>
                @endif

                @if ($order->tracking_number || $order->tracking_url)
                    <div class="details-info-list mt-3">
                        <h6 class="mb-3">@lang('Track Order')</h6>
                        @if ($order->tracking_number)
                            <p class="mb-2">
                                <strong>@lang('Tracking Number'):</strong> {{ $order->tracking_number }}
                            </p>
                        @endif
                        @if ($order->tracking_url)
                            <p class="mb-0">
                                <a href="{{ $order->tracking_url }}" target="_blank" rel="noopener noreferrer" class="btn btn--primary btn-sm">
                                    <i class="las la-external-link-alt"></i> @lang('Track your order')
                                </a>
                            </p>
                        @endif
                    </div>
                @endif
            </div>




            <div class="col-md-6">
                @if ($order->shipping_address)
                    @php
                        $addr = is_object($order->shipping_address) ? $order->shipping_address : (object) ($order->shipping_address ?? []);
                    @endphp
                    <div class="details-info-address">
                        <h6 class="mb-3">@lang('Shipping Details')</h6>
                        <ul class="info-address-list">
                            <li>
                                <span class="title">@lang('Name') </span>
                                <span>
                                    <span class="devide-colon">:</span>
                                    {{ trim(($addr->firstname ?? '') . ' ' . ($addr->lastname ?? '')) ?: ($order_detail->firstname ?? '') . ' ' . ($order_detail->lastname ?? '') ?: '—' }}
                                </span>
                            </li>
                            <li>
                                <span class="title">@lang('Address')</span>
                                <span>
                                    <span class="devide-colon">:</span>
                                    {{ $addr->address ?? '—' }}
                                </span>
                            </li>
                            <li>
                                <span class="title">@lang('State')</span>
                                <span>
                                    <span class="devide-colon">:</span>
                                    {{ $addr->state ?? '—' }}
                                </span>
                            </li>
                            <li>
                                <span class="title">@lang('City')</span>
                                <span>
                                    <span class="devide-colon">:</span>
                                    {{ $addr->city ?? '—' }}
                                </span>
                            </li>
                            <li>
                                <span class="title">@lang('Zip')</span>
                                <span>
                                    <span class="devide-colon">:</span>
                                    {{ $addr->zip ?? '—' }}
                                </span>
                            </li>
                            <li>
                                <span class="title">@lang('Country')</span>
                                <span>
                                    <span class="devide-colon">:</span>
                                    {{ $addr->country ?? '—' }}
                                </span>
                            </li>
                        </ul>
                    </div>
                @endif
            </div>
        </div>

    </div>

    @if ($layout == 'user')
        </div>
    @endif
@endsection

@push('style')
    <link rel="stylesheet" href="{{ asset($activeTemplateTrue . 'css/order_details.css') }}">
@endpush
