@php
    $content = getContent('order_confirmation.content', true);
@endphp

@extends('Template::layouts.checkout')

@section('blade')
    <div class="address-wrapper">
        <div class="confirmation-card">
            <div class="confirmation-card-icon">
                <img src="{{ asset($activeTemplateTrue . 'images/order-completed.gif') }}" class="w-100 lazyload" alt="image">
            </div>
            <h3 class="confirmation-card-title mb-2">{{ __(@$content->data_values->title) }}</h3>
            <p class="confirmation-card-desc mb-4">{{ __(@$content->data_values->description) }}</p>
            <a href="{{ url('orders', $order->order_number) }}" class="btn btn-outline--light h-45">@lang('View Order Details')</a>
        </div>

        @if (!@$order->user_id)
            @php
                $shipAddr = is_object(@$order->shipping_address) ? @$order->shipping_address : (object) (@$order->shipping_address ?? []);
                $shipName = trim((@$shipAddr->firstname ?? '') . ' ' . (@$shipAddr->lastname ?? '')) ?: '—';
                $shipAddress = trim(@$shipAddr->address ?? '') ?: '—';
                if (!empty(@$shipAddr->apt ?? null)) {
                    $shipAddress = trim($shipAddress . ', ' . @$shipAddr->apt);
                }
                $shipState = trim(@$shipAddr->state ?? '');
                $shipCity = trim(@$shipAddr->city ?? '');
                $shipZip = trim(@$shipAddr->zip ?? '');
                $shipCountry = trim(@$shipAddr->country ?? '');
                $shipParts = array_filter([
                    trim((string) $shipAddress),
                    trim((string) $shipState),
                    trim((string) $shipCity),
                    trim((string) $shipZip),
                    trim((string) $shipCountry),
                ], function ($v) {
                    return !empty($v);
                });
                $shipToLine = !empty($shipParts) ? implode(', ', $shipParts) : $shipAddress;

                $shipFullParts = array_filter([
                    trim((string) $shipName),
                    trim((string) $shipToLine),
                ], function ($v) {
                    return !empty($v) && $v !== '—';
                });
                $shipFullLine = !empty($shipFullParts) ? implode(', ', $shipFullParts) : '—';

                $firstItem = @$order->orderDetail?->first();
                $mainImage = null;
                if ($firstItem) {
                    $mainImage = $firstItem->productVariant && @$firstItem->productVariant->main_image_id
                        ? @$firstItem->productVariant->mainImage(true)
                        : @$firstItem->product?->mainImage(true);
                }
            @endphp

            <div class="confirmation-order-summary">
                <h5 class="mb-3">@lang('Order Summary')</h5>

                <div class="confirmation-order-summary-product">
                    <img
                        src="{{ $mainImage ?? getImage(null) }}"
                        alt="product"
                        loading="lazy"
                        class="confirmation-order-summary-product-img"
                    >
                </div>

                <div class="confirmation-order-summary-details">
                    <div class="confirmation-shipping-to">
                        <div class="confirmation-shipping-to-icon" aria-hidden="true">
                            <i class="las la-map-marker-alt"></i>
                        </div>
                        <div class="confirmation-shipping-to-content">
                            <div class="confirmation-shipping-to-title-row">
                                <span class="fw-semibold">@lang('Shipping to'):</span>
                                <span class="confirmation-shipping-to-full">{{ $shipFullLine }}</span>
                            </div>
                        </div>
                    </div>

                    @if (!empty(@$shipAddr->mobile ?? null))
                        <p class="mb-0">
                            <i class="las la-phone"></i>
                            <span class="fw-semibold">@lang('Phone number'):</span>
                            <span>{{ @$shipAddr->mobile }}</span>
                        </p>
                    @endif
                </div>
            </div>
        @endif
    </div>
@endsection

@push('style')
    <style>
        .confirmation-card {
            max-width: 500px;
            width: 100%;
            border-radius: 6px;
            margin: 0 auto;
            text-align: center;
            padding: 40px;
        }

        .confirmation-card-icon {
            max-width: 150px;
            width: 100%;
            margin: 0 auto;
        }

        .confirmation-order-summary {
            margin: 22px auto 0;
            max-width: 520px;
            width: 100%;
            border-radius: 10px;
            padding: 18px;
            background: hsl(var(--black) / 0.03);
            border: 1px solid hsl(var(--border));
            text-align: left;
        }

        .confirmation-order-summary h5 {
            margin: 0 0 14px;
            font-weight: 600;
        }

        .confirmation-order-summary-product {
            display: flex;
            align-items: center;
            justify-content: flex-start;
            margin-bottom: 10px;
            gap: 12px;
        }

        .confirmation-order-summary-product-img {
            width: 120px;
            height: 120px;
            object-fit: cover;
            border-radius: 8px;
            background: hsl(var(--white));
        }

        .confirmation-order-summary-details p {
            display: flex;
            align-items: flex-start;
            gap: 10px;
            margin-bottom: 10px;
            color: hsl(var(--black) / 0.9);
        }

        .confirmation-order-summary-details p:last-child {
            margin-bottom: 0;
        }

        .confirmation-shipping-to {
            display: flex;
            align-items: flex-start;
            gap: 12px;
            padding: 14px 14px;
            border-radius: 10px;
            background: hsl(var(--black) / 0.03);
            border: 1px solid hsl(var(--border) / 0.5);
            margin-bottom: 10px;
        }

        .confirmation-shipping-to-icon {
            width: 40px;
            height: 40px;
            border-radius: 12px;
            display: grid;
            place-content: center;
            background: hsl(var(--black) / 0.05);
            border: 1px solid hsl(var(--border) / 0.5);
            color: hsl(var(--base));
            flex-shrink: 0;
        }

        .confirmation-shipping-to-title {
            margin-bottom: 2px;
            color: hsl(var(--black) / 0.9);
        }

        .confirmation-shipping-to-title-row {
            display: flex;
            align-items: center;
            gap: 10px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            width: 100%;
        }

        .confirmation-shipping-to-full {
            min-width: 0;
            overflow: hidden;
            text-overflow: ellipsis;
            color: hsl(var(--black) / 0.7);
            font-weight: 500;
        }

        .confirmation-shipping-to-address {
            color: hsl(var(--black) / 0.7);
            line-height: 1.35;
            font-weight: 500;
        }

        [data-theme="dark"] .confirmation-shipping-to {
            background: hsl(var(--black) / 0.18);
            border-color: rgba(255, 255, 255, 0.08);
        }

        [data-theme="dark"] .confirmation-shipping-to-icon {
            background: rgba(255, 255, 255, 0.06);
            border-color: rgba(255, 255, 255, 0.08);
            color: #fff;
        }

        [data-theme="dark"] .confirmation-shipping-to-title {
            color: #fff !important;
        }

        [data-theme="dark"] .confirmation-shipping-to-title-row .fw-semibold {
            color: #fff !important;
        }

        [data-theme="dark"] .confirmation-shipping-to-full {
            color: rgba(255, 255, 255, 0.85) !important;
        }

        [data-theme="dark"] .confirmation-shipping-to-address {
            color: rgba(255, 255, 255, 0.85) !important;
        }
    </style>
@endpush
