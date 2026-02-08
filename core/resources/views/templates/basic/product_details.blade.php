@extends('Template::layouts.master')

@section('content')


    @php


                if ($product->categories->isNotEmpty()) {
                    $categoryId = $product->categories->first()->pivot->category_id;


                    if (in_array($categoryId, [4,5,7,9,11])) {
                        $countries = getusaCountries();
                    }elseif($categoryId == 6){
                        $countries = getusacanadaCountries();
                    } else{

                        $countries = getCountries();

                    }
                }


    @endphp


    <div class="product-details-page py-60">
        <div class="container">
            <div class="row g-4 g-xl-5">



                {{-- LEFT SIDE --}}
                <div class="col-xl-9">

                    {{-- Product Quick View --}}
                    @include($activeTemplate . 'partials.quick_view')

                    @php
                        $description = preg_replace('/<\/?(div|br)\s*\/?>/i', '', $product->description);
                        $shippingInformation = (object) Session::get('shipping_info');
                        $checkoutContent = getContent('guest_checkout.content', true)?->data_values;
                    @endphp


                    <div class="card my-2 product-description-card">
                        <h6 class="card-header-title">Product Description</h6>
                        <div class="card-body">
                            {{ $description }}
                        </div>
                    </div>



                    @auth
                    {{-- Checkout form: only for logged-in users --}}
                    <div class="card my-4" id="shippingFormCard">
                            <div class="card-body">
                                <form action="{{ route('checkout.guest.shipping.info.store') }}"
                                      method="POST"
                                      enctype="multipart/form-data"
                                      id="shipping-form">

                                    @csrf

                                    <hr>

                                    {{-- Receiver Details --}}
                                    @if (@$checkoutContent->shipping_info_recipient_info_title)
                                        <h5 class="mb-4">Receiver's Details</h5>
                                    @endif

                                    <div class="row">

                                        {{-- Country --}}
                                        <div class="col-md-12">
                                            <div class="form-group">
                                                <label class="form-label">Country / Region</label>
                                                <select name="country" class="form-control form--control select2" required>
                                                    <option value="">Search Country...</option>
                                                    @foreach ($countries as $key => $country)
                                                        <option data-mobile_code="{{ $country->dial_code }}"
                                                                value="{{ $country->country }}"
                                                                data-code="{{ $key }}">
                                                            {{ __($country->country) }}
                                                        </option>
                                                    @endforeach
                                                </select>
                                            </div>



                                            <input type="hidden" name="product_id" value="{{ $product->id }}">
                                            <input type="hidden" name="product_type" value="{{ $product->product_type }}">

                                            {{-- quantity --}}
                                            <input type="hidden" name="quantity" id="directQty" value="1">

                                            {{-- for variable product --}}
                                            <input type="hidden" name="variant_attributes" id="variantAttributes" value="">


                                        </div>

                                        {{-- Firstname --}}
                                        <div class="col-md-6">
                                            <div class="form-group">
                                                <label>Receiver's First name</label>
                                                <input type="text"
                                                       value="{{ @$shippingInformation->firstname }}"
                                                       class="form-control form--control"
                                                       name="firstname" required>
                                            </div>
                                        </div>

                                        {{-- Lastname --}}
                                        <div class="col-md-6">
                                            <div class="form-group">
                                                <label>Receiver's Last name</label>
                                                <input type="text"
                                                       value="{{ @$shippingInformation->lastname }}"
                                                       class="form-control form--control"
                                                       name="lastname" required>
                                            </div>
                                        </div>

                                        {{-- Address --}}
                                        <div class="col-md-12">
                                            <div class="form-group">
                                                <label>Street address</label>
                                                <input type="text"
                                                       value="{{ @$shippingInformation->address }}"
                                                       class="form-control form--control"
                                                       placeholder="House Number and Street Name"
                                                       name="address" required>
                                            </div>
                                        </div>

                                        {{-- Apt --}}
                                        <div class="col-md-12">
                                            <div class="form-group">
                                                <input type="text"
                                                       value="{{ @$shippingInformation->apt }}"
                                                       placeholder="House number, Apartment, suite, unit, flat etc"
                                                       class="form-control form--control"
                                                       name="apt">
                                            </div>
                                        </div>

                                        {{-- State --}}
                                        <div class="col-md-12">
                                            <div class="form-group">
                                                <label>State / County</label>
                                                <div id="stateInputWrapper">
                                                    <input type="text"
                                                           value="{{ @$shippingInformation->state }}"
                                                           class="form-control form--control"
                                                           name="state"
                                                           id="stateInput"
                                                           required>
                                                </div>
                                            </div>
                                        </div>

                                        {{-- City --}}
                                        <div class="col-md-12">
                                            <div class="form-group">
                                                <label>Town / City</label>
                                                <input type="text"
                                                       value="{{ @$shippingInformation->city }}"
                                                       class="form-control form--control"
                                                       name="city" required>
                                            </div>
                                        </div>

                                        {{-- Zip --}}
                                        <div class="col-md-12">
                                            <div class="form-group">
                                                <label>Postcode / ZIP</label>
                                                <input type="text"
                                                       value="{{ @$shippingInformation->zip }}"
                                                       class="form-control form--control"
                                                       name="zip" required>
                                            </div>
                                        </div>

                                        {{-- Mobile --}}
                                        <div class="col-md-12">
                                            <div class="form-group">
                                                <label>Receiver’s Phone Number (Optional)</label>
                                                <input type="number"
                                                       name="mobile"
                                                       value="{{ @$shippingInformation->mobile }}"
                                                       class="form-control form--control">

                                                <input type="hidden" value="0" name="mobile_code" id="mobile_code">
                                                <input type="hidden" value="0" name="country_code" id="country_code">
                                            </div>
                                        </div>
                                        <div class="col-md-12">
                                            <div class="form-group">
                                                <label>Email</label>
                                                <input type="email" name="email" class="form-control form--control" value="{{ auth()->check() ? auth()->user()->email : (optional(session('guest_user_data'))->email ?? old('email')) }}" required>
                                            </div>
                                        </div>

                                    </div>{{-- row --}}

                                    <hr>

                                    {{-- Upload photos --}}
                                    @if($product->customer_photo === 1)
                                        <div class="card my-4">
                                            <div class="card-body">
                                                <h5 class="mb-3">Upload Customized Product Photo</h5>

                                                <div class="row">
                                                    <div class="col-md-6">
                                                        <div class="form-group">
                                                            <label>@lang('Upload Front Picture')</label>
                                                            <input type="file" class="form-control form--control" name="front_picture"
                                                                   id="front_picture" accept="image/*" required>

                                                            <div class="mt-3 text-center">
                                                                <img id="frontPreview" src="#" class="img-fluid rounded shadow-sm d-none"
                                                                     style="max-width: 250px;">
                                                            </div>
                                                        </div>
                                                    </div>

                                                    <div class="col-md-6">
                                                        <div class="form-group">
                                                            <label>@lang('Upload Back Picture')</label>
                                                            <input type="file" class="form-control form--control" name="back_picture"
                                                                   id="back_picture" accept="image/*" required>

                                                            <div class="mt-3 text-center">
                                                                <img id="backPreview" src="#" class="img-fluid rounded shadow-sm d-none"
                                                                     style="max-width: 250px;">
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    @endif

                                    {{-- Customised Text --}}
                                    @if($product->customised_test === 1)
                                        <div class="card my-4">
                                            <div class="card-body">
                                                <h5 class="mb-3">Customized Text</h5>
                                                <textarea class="form-control form--control"
                                                          name="customised_test"
                                                          required maxlength="5000"
                                                          placeholder="Enter your note here..."></textarea>
                                            </div>
                                        </div>
                                    @endif

                                    {{-- Customised Short Text --}}
                                    @if($product->customised_short_test === "1")
                                        <div class="card my-4">
                                            <div class="card-body">
                                                <h5 class="mb-3">Customized Short Text (40)</h5>
                                                <textarea class="form-control form--control"
                                                          name="customised_short_test"
                                                          required maxlength="40"
                                                          placeholder="Enter your short note here..."></textarea>
                                            </div>
                                        </div>
                                    @endif

                                    {{-- Note to seller --}}
                                    @if($product->note === 1)
                                        <div class="card my-4">
                                            <div class="card-body">
                                                <h5 class="mb-2">Note to Seller</h5>

                                                <textarea class="form-control form--control"
                                                          name="note_to_seller"
                                                          id="note_to_seller"
                                                          rows="4"
                                                          maxlength="250"
                                                          required
                                                          placeholder="Enter your note here...">{{ old('note_to_seller', session('note_to_seller')) }}</textarea>

                                                <small id="charCount" class="text-muted d-block mt-2">0 / 250 characters</small>

                                                <small class="text-info d-block mt-1">
                                                    Note: Additional fee of ₦5,000 will be added.
                                                </small>
                                            </div>
                                        </div>
                                    @endif

                                    {{-- Submit --}}
                                    <div class="d-flex justify-content-end mt-4">

                                        <button type="submit" class="btn btn--base h-45">
                                            @lang('Continue to Payment') <i class="las la-angle-right"></i>
                                        </button>
                                    </div>

                                </form>

                            </div>

                        </div>
                    @else
                    <div class="card my-4">
                        <div class="card-body">
                            <p class="mb-0">@lang('Please') <a href="javascript:void(0)" class="login-trigger text--base">@lang('login')</a> @lang('or continue as guest from cart to checkout.')</p>
                        </div>
                    </div>
                    @endauth

                </div>{{-- col-xl-9 --}}


                {{-- RIGHT SIDE --}}
                @if ($otherProducts->count() > 0)
                    <div class="col-md-12 col-xl-3">
                        <div class="sticky-sidebar">
                            <h5 class="product-details-title fw-500 mb-3">{{ __($otherProductsTitle) }}</h5>

                            <div class="row gy-3">
                                @foreach ($otherProducts as $relatedProduct)
                                    <div class="col-sm-6 col-md-6 col-lg-4 col-xl-12">
                                        <div class="best-sell-item">
                                            <div class="best-sell-inner d-flex flex-wrap">
                                                <div class="thumb">
                                                    <a href="{{ $relatedProduct->link() }}">
                                                        <img src="{{ getImage(null) }}"
                                                             data-src="{{ $relatedProduct->mainImage() }}"
                                                             class="lazyload"
                                                             alt="products">
                                                    </a>
                                                </div>
                                                <div class="content">
                                                    <h6 class="title">
                                                        <a href="{{ $relatedProduct->link() }}">{{ __($relatedProduct->name) }}</a>
                                                    </h6>

                                                    <div class="price fw-500">
                                                        @php echo $relatedProduct->formattedPrice(); @endphp
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                @endforeach
                            </div>

                        </div>
                    </div>
                @endif

            </div>{{-- row --}}
        </div>{{-- container --}}
    </div>{{-- py-60 --}}


    @push('script')
        <script>
            "use strict";
            $(document).ready(function() {
                $("select[name='country']").select2({
                    placeholder: "Search Country...",
                    allowClear: true,
                    width: '100%',
                });
            });
        </script>
    @endpush

    @push('script')
        <script>
            "use strict";

            function previewImage(input, previewId) {
                const file = input.files[0];
                const preview = document.getElementById(previewId);

                if (file) {
                    const reader = new FileReader();
                    reader.onload = function (e) {
                        preview.src = e.target.result;
                        preview.classList.remove('d-none');
                    };
                    reader.readAsDataURL(file);
                } else {
                    preview.classList.add('d-none');
                }
            }

            document.getElementById('front_picture')?.addEventListener('change', function () {
                previewImage(this, 'frontPreview');
            });

            document.getElementById('back_picture')?.addEventListener('change', function () {
                previewImage(this, 'backPreview');
            });

            const textarea = document.getElementById('note_to_seller');
            const charCount = document.getElementById('charCount');
            if (textarea && charCount) {
                charCount.textContent = `${textarea.value.length} / 250 characters`;
                textarea.addEventListener('input', function () {
                    charCount.textContent = `${this.value.length} / 250 characters`;
                });
            }
        </script>
    @endpush

@endsection


@push('style-lib')
    <link rel="stylesheet" href="{{ asset($activeTemplateTrue . 'css/owl.carousel.min.css') }}">
    <link rel="stylesheet" href="{{ asset($activeTemplateTrue . 'css/product-details.css') }}">
    <link rel="stylesheet" href="{{ asset($activeTemplateTrue . 'css/xzoom/xzoom.css') }}">
    <link rel="stylesheet" href="{{ asset($activeTemplateTrue . 'css/xzoom/magnific-popup.css') }}">
@endpush

@push('script-lib')
    <script src="{{ asset($activeTemplateTrue . 'js/owl.carousel.min.js') }}"></script>
    <script src="{{ asset($activeTemplateTrue . 'js/owl-carousel.js') }}"></script>
    <script src="{{ asset($activeTemplateTrue . 'js/xzoom/xzoom.min.js') }}"></script>
    <script src="{{ asset($activeTemplateTrue . 'js/xzoom/magnific-popup.js') }}"></script>
    <script src="{{ asset($activeTemplateTrue . 'js/xzoom/setup.js') }}"></script>
@endpush


@push('script')
    <script>
        "use strict";

        @if (gs('product_review'))
            loadReviews(`{{ route('product.reviews', $product->id) }}`);
        @endif

        const firstTabLink = document.querySelector('#productTabs a');

        if (firstTabLink) {
            const firstTab = new bootstrap.Tab(firstTabLink);
            firstTab.show();
        }

        $('.review-rating-tab').on("click", function() {
            $('.review-gallery').each(function() {
                $(this).magnificPopup({
                    delegate: 'a',
                    type: 'image',
                    gallery: {
                        enabled: true
                    }
                });
            });
        });
    </script>
@endpush


@push('script')
    <script>
        $(document).ready(function () {

            let usaStates = {};
            let canadaStates = {};

            // Load USA states JSON
            $.getJSON("{{ asset('core/resources/views/partials/usastates.json') }}", function (data) {
                usaStates = data;
            });

            // Load Canada provinces JSON
            $.getJSON("{{ asset('core/resources/views/partials/castates.json') }}", function (data) {
                canadaStates = data;
            });

            function loadStateSelect(states) {
                let selectHtml = '<select name="state" id="stateSelect" class="form-control form--control select2" required>';
                selectHtml += '<option value="">Select State</option>';

                $.each(states, function (key, value) {
                    selectHtml += `<option value="${value}">${value}</option>`;
                });

                selectHtml += '</select>';

                $("#stateInputWrapper").html(selectHtml);
                $('.select2').select2();
            }

            function loadStateInput() {
                $("#stateInputWrapper").html(`
                                        <input type="text" class="form-control form--control" name="state" required>
                                    `);
            }

            $("select[name='country']").on("change", function () {
                const selectedCountry = $(this).find(":selected").data("code");

                if (selectedCountry === "US") {
                    loadStateSelect(usaStates);
                } else if (selectedCountry === "CA") {
                    loadStateSelect(canadaStates);
                } else {
                    loadStateInput();
                }
            });

            // Trigger change on load
            $("select[name='country']").trigger("change");
        });
    </script>


@endpush
