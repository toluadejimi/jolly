@extends('Template::layouts.master')

@section('content')
    <div class="order-track-section py-60">
        <div class="container">
            <h5 class="title mb-3 text-center">@lang('Track Your Order')</h5>
            <div class="row justify-content-center mb-5">
                <div class="col-lg-7 col-md-9 col-xl-6">
                    <form class="order-track-form" id="order-track">
                        <div class="order-track-form-group">
                            <input type="text" name="order_number" placeholder="@lang('Enter Your Order ID')">
                            <button type="submit" class="track-btn">@lang('Track Now')</button>
                        </div>
                    </form>
                </div>
            </div>

            <div id="order-tracking-info" class="row justify-content-center mb-4 d-none">
                <div class="col-lg-10 col-xl-8">
                    <div class="card border-0 shadow-sm">
                        <div class="card-body">
                            <h6 class="card-title mb-3">@lang('Order tracking details')</h6>
                            <div id="tracking-estimated-delivery" class="mb-2 d-none">
                                <strong>@lang('Estimated delivery'):</strong>
                                <span id="tracking-estimated-delivery-value"></span>
                            </div>
                            <div id="tracking-number-wrap" class="mb-2 d-none">
                                <strong>@lang('Tracking Number'):</strong>
                                <span id="tracking-number-value"></span>
                            </div>
                            <div id="tracking-url-wrap" class="d-none">
                                <a id="tracking-url-link" href="#" target="_blank" rel="noopener noreferrer" class="btn btn--primary btn-sm">
                                    <i class="las la-external-link-alt"></i> @lang('Track your order')
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row justify-content-center">
                <div class="col-lg-10 col-xl-8">
                    <div class="order-track-wrapper d-flex flex-wrap justify-content-center">
                        <div class="confirm-state order-track-item">
                            <div class="thumb">
                                <i class="las la-check-square"></i>
                            </div>
                            <div class="content">
                                <h6 class="title">@lang('Pending')</h6>
                            </div>
                        </div>

                        <div class="order-track-item processing-state">
                            <div class="thumb">
                                <i class="las la-sync-alt"></i>
                            </div>
                            <div class="content">
                                <h6 class="title">@lang('Processing')</h6>
                            </div>
                        </div>

                        <div class="order-track-item dispatched-state">
                            <div class="thumb">
                                <i class="las la-truck-pickup"></i>
                            </div>
                            <div class="content">
                                <h6 class="title">@lang('Dispatched')</h6>
                            </div>
                        </div>

                        <div class="order-track-item delivered-state">
                            <div class="thumb">
                                <i class="las la-map-signs"></i>
                            </div>
                            <div class="content">
                                <h6 class="title">@lang('Delivered')</h6>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
@endsection

@push('script')
    <script>
        'use strict';
        (function($) {
            $(document).on('submit', '#order-track', function(e) {
                e.preventDefault();

                let orderNumber = $('input[name=order_number]').val();

                $.get(`{{ route('track.order', '') }}/${orderNumber}`, function(response) {
                    var $info = $('#order-tracking-info');
                    $('#tracking-estimated-delivery').addClass('d-none');
                    $('#tracking-number-wrap').addClass('d-none');
                    $('#tracking-url-wrap').addClass('d-none');

                    if (response.success) {
                        $('#order-tracking-info').removeClass('d-none');
                        if (response.estimated_delivery_at) {
                            $('#tracking-estimated-delivery-value').text(response.estimated_delivery_at);
                            $('#tracking-estimated-delivery').removeClass('d-none');
                        }
                        if (response.tracking_number) {
                            $('#tracking-number-value').text(response.tracking_number);
                            $('#tracking-number-wrap').removeClass('d-none');
                        }
                        if (response.tracking_url) {
                            $('#tracking-url-link').attr('href', response.tracking_url);
                            $('#tracking-url-wrap').removeClass('d-none');
                        }

                        if (response.status == {{ Status::ORDER_CANCELED }}) {
                            $('.confirm-state, .processing-state, .dispatched-state, .delivered-state').removeClass('active');
                            notify('error', 'This order is canceled by admin');
                        } else if (response.status == {{ Status::ORDER_RETURNED }}) {
                            $('.confirm-state, .processing-state, .dispatched-state, .delivered-state').removeClass('active');
                            notify('error', 'This order is cancelled by the customer');
                        } else {
                            response.status >= '{{ Status::ORDER_PENDING }}' ? $('.confirm-state').addClass('active') : $('.confirm-state').removeClass('active');

                            response.status >= '{{ Status::ORDER_PROCESSING }}' ? $('.processing-state').addClass('active') : $('.processing-state').removeClass('active');

                            response.status >= '{{ Status::ORDER_DISPATCHED }}' ? $('.dispatched-state').addClass('active') : $('.dispatched-state').removeClass('active');

                            response.status >= '{{ Status::ORDER_DELIVERED }}' ? $('.delivered-state').addClass('active') : $('.delivered-state').removeClass('active');
                        }
                    } else {
                        $('#order-tracking-info').addClass('d-none');
                        $('.confirm-state, .processing-state, .dispatched-state, .delivered-state').removeClass('active');
                        notify('error', response.error);
                    }

                    $('.track-btn').attr('disabled', false);
                });
            });
        })(jQuery)
    </script>
@endpush

@push('style-lib')
    <link href="{{ asset($activeTemplateTrue . 'css/order-track.css') }}" rel="stylesheet">
@endpush
