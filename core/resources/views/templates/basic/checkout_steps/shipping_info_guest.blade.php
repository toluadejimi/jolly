@extends($activeTemplate . 'layouts.checkout')

@section('blade')
    <form action="{{ route('checkout.guest.shipping.info.store') }}" method="POST" id="shipping-form">
        @csrf
        <div>
            @php
                $shippingInformation = (object) Session::get('shipping_info');
                $checkoutContent = getContent('guest_checkout.content', true)?->data_values;
            @endphp

            @if ($checkoutContent->shipping_info_recipient_info_title)
                <h5 class="mb-1 ">{{ __($checkoutContent->shipping_info_recipient_info_title) }}</h5>
            @endif

            @if ($checkoutContent->shipping_info_recipient_info_description)
                <p class="text-muted fst-italic">
                    {{ __($checkoutContent->shipping_info_recipient_info_description) }}
                </p>
            @endif

            <div class="row">

                <div class="col-md-6">
                    <div class="form-group">
                        <label>@lang('First Name')</label>
                        <input type="text" value="{{ @$shippingInformation->firstname }}"
                               class="form-control form--control" name="firstname" required>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="form-group">
                        <label>@lang('Last Name')</label>
                        <input type="text" value="{{ @$shippingInformation->lastname }}"
                               class="form-control form--control" name="lastname" required>
                    </div>
                </div>



                <div class="col-md-6">
                    <div class="form-group">
                        <label>@lang('Mobile')</label>
                        <div class="input-group">
                            <!-- Country dropdown: set fixed width -->
                            <select name="mobile_country" id="mobileCountrySelect" class="form-select w-auto" style="max-width: 150px;" required>
                                @foreach ($countries as $code => $country)
                                    <option value="{{ $country->country }}"
                                            data-mobile_code="{{ $country->dial_code }}"
                                            data-code="{{ $code }}"
                                        {{ isset($shippingInformation) && @$shippingInformation->country_code == $code ? 'selected' : '' }}>
                                        {{ $country->country }}
                                    </option>
                                @endforeach
                            </select>

                            <!-- Dial code -->
                            <span class="input-group-text" id="dialCode" style="min-width: 70px;"></span>

                            <!-- Hidden inputs -->
                            <input type="hidden" name="mobile_code" id="mobile_code">
                            <input type="hidden" name="country_code" id="country_code">

                            <!-- Mobile number input -->
                            <input type="number" name="mobile" value="{{ @$shippingInformation->mobile }}"
                                   class="form-control form--control" placeholder="@lang('Enter mobile number')" required>
                        </div>

                        <small class="text-muted">
                            <i class="la la-info-circle"></i> @lang('Enter the mobile number without the country code.')
                        </small>
                    </div>

                    <script>
                        document.addEventListener('DOMContentLoaded', function () {
                            const countrySelect = document.getElementById('mobileCountrySelect');
                            const dialCodeSpan = document.getElementById('dialCode');
                            const mobileCodeInput = document.getElementById('mobile_code');
                            const countryCodeInput = document.getElementById('country_code');

                            function updateDialCode() {
                                const selectedOption = countrySelect.options[countrySelect.selectedIndex];
                                const dialCode = selectedOption.getAttribute('data-mobile_code');
                                const code = selectedOption.getAttribute('data-code');

                                dialCodeSpan.textContent = '+' + dialCode;
                                mobileCodeInput.value = dialCode;
                                countryCodeInput.value = code;
                            }

                            updateDialCode();
                            countrySelect.addEventListener('change', updateDialCode);
                        });
                    </script>
                </div>




                <div class="col-md-6">
                    <div class="form-group">
                        <label>@lang('Email')</label>
                        <input type="text" value="{{ @$shippingInformation->email }}" class="form-control form--control"
                               name="email" required>
                    </div>
                </div>
            </div>

            <hr>

            <div class="row mt-4">

                <h5 class="mb-1 "> Note to Seller</h5>


                <p class="text-muted fst-italic">
                    Note about your order. Ex Special note for delivery
                </p>

                <div class="col-md-12">
                    <div class="form-group">
                        <label>@lang('Enter Note')</label>
                        <textarea class="form-control form--control" name="note_to_seller" id="note_to_seller" rows="4" placeholder="Enter your note here..." maxlength="250"></textarea>
                        <small id="charCount" class="text-muted d-block">0 / 250 characters</small>
                        <small class="text-info d-block mt-1">
                            Note: To include note with your order, a Additional fee of ₦5,000 will be added.
                        </small>
                    </div>
                </div>

                <script>
                    const textarea = document.getElementById('note_to_seller');
                    const charCount = document.getElementById('charCount');

                    textarea.addEventListener('input', function() {
                        const length = this.value.length;
                        charCount.textContent = `${length} / 250 characters`;

                        // Optional visual feedback
                        if (length > 250) {
                            charCount.classList.add('text-danger');
                        } else {
                            charCount.classList.remove('text-danger');
                        }
                    });
                </script>

            </div>

            <hr>

            <div class="row mt-4">

                @if ($checkoutContent->description_in_shipping_info_title)
                    <h5 class="mb-1 ">{{ __($checkoutContent->description_in_shipping_info_title) }}</h5>
                @endif

                @if ($checkoutContent->description_in_shipping_info_description)
                    <p class="text-muted fst-italic">
                        {{ __($checkoutContent->description_in_shipping_info_description) }}
                    </p>
                @endif

                <div class="col-md-6">
                    <div class="form-group">
                        <label class="form-label">@lang('Country')</label>
                        <select name="country" class="form-control form--control select2" required>
                            @foreach ($countries as $key => $country)
                                <option data-mobile_code="{{ $country->dial_code }}" value="{{ $country->country }}"
                                        data-code="{{ $key }}">
                                    {{ __($country->country) }}
                                </option>
                            @endforeach
                        </select>
                    </div>
                </div>

                <div class="col-md-6">
                    <div class="form-group">
                        <label>@lang('State')</label>
                        <input type="text" value="{{ @$shippingInformation->state }}" class="form-control form--control"
                               name="state" required>
                    </div>
                </div>

                <div class="col-md-6">
                    <div class="form-group">
                        <label>@lang('City')</label>
                        <input type="text" value="{{ @$shippingInformation->city }}" class="form-control form--control"
                               name="city" required>
                    </div>
                </div>

                <div class="col-md-6">
                    <div class="form-group">
                        <label>@lang('Zip')</label>
                        <input type="text" value="{{ @$shippingInformation->zip }}" class="form-control form--control"
                               name="zip" required>
                    </div>
                </div>

                <div class="col-md-12">
                    <div class="form-group">
                        <label>@lang('Address')</label>
                        <input type="text" value="{{ @$shippingInformation->address }}"
                               class="form-control form--control" name="address" required>
                    </div>
                </div>
            </div>
        </div>

        <div class="d-flex align-items-center justify-content-between flex-wrap mt-4">
            <a href="{{ route('cart.page') }}" class="text--base">
                <i class="las la-angle-left"></i> @lang('Back to Cart')
            </a>

            <button type="submit" class="btn btn--base h-45">@lang('Continue to Next') <i
                    class="las la-angle-right"></i></button>
        </div>
    </form>
@endsection
