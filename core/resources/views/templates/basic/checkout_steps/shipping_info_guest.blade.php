@extends($activeTemplate . 'layouts.checkout')

@section('blade')
    @php
        $shippingInformation = (object) Session::get('shipping_info');
        $checkoutContent = getContent('guest_checkout.content', true)?->data_values;
        $guestEmail = auth()->check() ? auth()->user()->email : data_get(session('guest_user_data'), 'email', '');
    @endphp

    <div class="card">
        <div class="card-body">
            <form action="{{ route('checkout.guest.shipping.info.store') }}" method="POST" enctype="multipart/form-data" id="shipping-form">
                @csrf

                <h5 class="mb-4">Receiver's Details</h5>

                <div class="row">
                    <div class="col-md-12">
                        <div class="form-group">
                            <label class="form-label">Country / Region</label>
                            <select name="country" class="form-control form--control select2" required>
                                <option value="">Search Country...</option>
                                @foreach ($countries as $key => $country)
                                    <option data-mobile_code="{{ $country->dial_code }}" value="{{ $country->country }}" data-code="{{ $key }}">
                                        {{ __($country->country) }}
                                    </option>
                                @endforeach
                            </select>
                        </div>
                    </div>

                    <div class="col-md-6">
                        <div class="form-group">
                            <label>Receiver's First name</label>
                            <input type="text" value="{{ @$shippingInformation->firstname }}" class="form-control form--control" name="firstname" required>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="form-group">
                            <label>Receiver's Last name</label>
                            <input type="text" value="{{ @$shippingInformation->lastname }}" class="form-control form--control" name="lastname" required>
                        </div>
                    </div>

                    <div class="col-md-12">
                        <div class="form-group">
                            <label>Street address</label>
                            <input type="text" value="{{ @$shippingInformation->address }}" class="form-control form--control" placeholder="House Number and Street Name" name="address" required>
                        </div>
                    </div>

                    <div class="col-md-12">
                        <div class="form-group">
                            <input type="text" value="{{ @$shippingInformation->apt }}" placeholder="Apartment, suite, unit, etc." class="form-control form--control" name="apt">
                        </div>
                    </div>

                    <div class="col-md-12">
                        <div class="form-group">
                            <label>State / County</label>
                            <div id="stateInputWrapper">
                                <input type="text" value="{{ @$shippingInformation->state }}" class="form-control form--control" name="state" id="stateInput" required>
                            </div>
                        </div>
                    </div>

                    <div class="col-md-12">
                        <div class="form-group">
                            <label>Town / City</label>
                            <input type="text" value="{{ @$shippingInformation->city }}" class="form-control form--control" name="city" required>
                        </div>
                    </div>

                    <div class="col-md-12">
                        <div class="form-group">
                            <label>Postcode / ZIP</label>
                            <input type="text" value="{{ @$shippingInformation->zip }}" class="form-control form--control" name="zip" required>
                        </div>
                    </div>

                    <div class="col-md-12">
                        <div class="form-group">
                            <label>Receiver's Phone <span class="text-danger">*</span></label>
                            <input type="text" name="mobile" value="{{ @$shippingInformation->mobile }}" class="form-control form--control" placeholder="Phone number for delivery" required>
                            <input type="hidden" name="mobile_code" id="mobile_code" value="0">
                            <input type="hidden" name="country_code" id="country_code" value="0">
                            <input type="hidden" name="email" value="{{ $guestEmail }}">
                        </div>
                    </div>
                </div>

                @if(session('customer_photo') == 1)
                    <hr class="my-4">
                    <h5 class="mb-3">Upload Customized Product Photo</h5>
                    <div class="row">
                        <div class="col-md-6">
                            <div class="form-group">
                                <label>@lang('Upload Front Picture')</label>
                                <input type="file" class="form-control form--control" name="front_picture" id="front_picture" accept="image/*">
                                <div class="mt-2 text-center"><img id="frontPreview" src="#" class="img-fluid rounded d-none" style="max-width: 200px;"></div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="form-group">
                                <label>@lang('Upload Back Picture')</label>
                                <input type="file" class="form-control form--control" name="back_picture" id="back_picture" accept="image/*">
                                <div class="mt-2 text-center"><img id="backPreview" src="#" class="img-fluid rounded d-none" style="max-width: 200px;"></div>
                            </div>
                        </div>
                    </div>
                @endif

                @if(session('customised_test') == 1)
                    <hr class="my-4">
                    <h5 class="mb-3">Customized Text</h5>
                    <textarea class="form-control form--control" name="customised_test" maxlength="5000" placeholder="Enter your note here..."></textarea>
                @endif

                @if(session('customised_short_test') == '1')
                    <hr class="my-4">
                    <h5 class="mb-3">Customized Short Text (40)</h5>
                    <textarea class="form-control form--control" name="customised_short_test" maxlength="40" placeholder="Enter your short note here..."></textarea>
                @endif

                @if(session('note') == 1)
                    <hr class="my-4">
                    <h5 class="mb-2">Note to Seller</h5>
                    <textarea class="form-control form--control" name="note_to_seller" id="note_to_seller" rows="4" maxlength="250" placeholder="Enter your note here...">{{ old('note_to_seller', session('note_to_seller')) }}</textarea>
                    <small id="charCount" class="text-muted d-block mt-2">0 / 250 characters</small>
                    <small class="text-info d-block mt-1">Note: Additional fee of ₦5,000 will be added.</small>
                @endif

                <div class="d-flex align-items-center justify-content-between flex-wrap mt-4">
                    <a href="{{ route('cart.page') }}" class="text--base"><i class="las la-angle-left"></i> @lang('Back to Cart')</a>
                    <button type="submit" class="btn btn--base h-45">@lang('Continue to Payment') <i class="las la-angle-right"></i></button>
                </div>
            </form>
        </div>
    </div>

    @push('script')
    <script>
        $(document).ready(function () {
            if ($.fn.select2) $("select[name='country']").select2({ placeholder: "Search Country...", allowClear: true, width: '100%' });

            let usaStates = {}, canadaStates = {};
            $.getJSON("{{ asset('core/resources/views/partials/usastates.json') }}", function (d) { usaStates = d; });
            $.getJSON("{{ asset('core/resources/views/partials/castates.json') }}", function (d) { canadaStates = d; });

            function loadStateSelect(states) {
                var html = '<select name="state" id="stateSelect" class="form-control form--control" required><option value="">Select State</option>';
                $.each(states, function (k, v) { html += '<option value="'+v+'">'+v+'</option>'; });
                html += '</select>';
                $("#stateInputWrapper").html(html);
                if ($.fn.select2) $('#stateSelect').select2({ width: '100%' });
            }
            function loadStateInput() {
                $("#stateInputWrapper").html('<input type="text" class="form-control form--control" name="state" required>');
            }

            $("select[name='country']").on("change", function () {
                var code = $(this).find(":selected").data("code");
                if (code === "US") loadStateSelect(usaStates);
                else if (code === "CA") loadStateSelect(canadaStates);
                else loadStateInput();
            });
            $("select[name='country']").trigger("change");

            function previewImage(input, previewId) {
                var file = input.files[0], el = document.getElementById(previewId);
                if (file && el) {
                    var r = new FileReader();
                    r.onload = function(e) { el.src = e.target.result; el.classList.remove('d-none'); };
                    r.readAsDataURL(file);
                } else if (el) el.classList.add('d-none');
            }
            document.getElementById('front_picture') && document.getElementById('front_picture').addEventListener('change', function () { previewImage(this, 'frontPreview'); });
            document.getElementById('back_picture') && document.getElementById('back_picture').addEventListener('change', function () { previewImage(this, 'backPreview'); });

            var noteEl = document.getElementById('note_to_seller'), countEl = document.getElementById('charCount');
            if (noteEl && countEl) {
                countEl.textContent = noteEl.value.length + ' / 250 characters';
                noteEl.addEventListener('input', function () { countEl.textContent = this.value.length + ' / 250 characters'; });
            }
        });
    </script>
    @endpush
@endsection
