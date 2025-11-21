@extends($activeTemplate . 'layouts.checkout')

@section('blade')
    <form action="{{ route('checkout.guest.shipping.info.store') }}" method="POST" enctype="multipart/form-data"
          id="shipping-form">
        @csrf
        <div>
            @php
                $shippingInformation = (object) Session::get('shipping_info');
                $checkoutContent = getContent('guest_checkout.content', true)?->data_values;
            @endphp

            @if ($checkoutContent->shipping_info_recipient_info_title)
                <h5 class="mb-4 ">Receiver's Details</h5>
            @endif

{{--            @if ($checkoutContent->shipping_info_recipient_info_description)--}}
{{--                <p class="text-muted fst-italic">--}}
{{--                    {{ __($checkoutContent->shipping_info_recipient_info_description) }}--}}
{{--                </p>--}}
{{--            @endif--}}

            <div class="row">

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

                        <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>

                        <script>
                            $(document).ready(function () {
                                $("select[name='country']").select2({
                                    placeholder: "Search Country...",
                                    allowClear: true,
                                    width: '100%',
                                    theme: "default"
                                });
                            });
                        </script>


                    </div>
                </div>


                <div class="col-md-6">
                    <div class="form-group">
                        <label>Receiver's First name</label>
                        <input type="text" value="{{ @$shippingInformation->firstname }}"
                               class="form-control form--control" name="firstname" required>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="form-group">
                        <label>Receiver's Last name</label>
                        <input type="text" value="{{ @$shippingInformation->lastname }}"
                               class="form-control form--control" name="lastname" required>
                    </div>
                </div>


                <div class="col-md-12">
                    <div class="form-group">
                        <label>Street address</label>
                        <input type="text" value="{{ @$shippingInformation->address }}"
                               class="form-control form--control" placeholder="House Number and Street Name" name="address" required>
                    </div>
                </div>

                <div class="col-md-12">
                    <div class="form-group">
                        <input type="text" value="{{ @$shippingInformation->apt }}" placeholder="House number, Apartment, suite, unit, flat etc" class="form-control form--control"
                               name="apt">
                    </div>
                </div>


                <div class="col-md-12">
                    <div class="form-group">
                        <label>State / County</label>

                        <div id="stateInputWrapper">
                            <input type="text"
                                   value="{{ @$shippingInformation->state }}"
                                   class="form-control form--control"
                                   name="state"
                                   id="stateInput"
                                   placeholder=""
                                   required>
                        </div>
                    </div>

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

                </div>


                <div class="col-md-12">
                    <div class="form-group">
                        <label>Town / City</label>
                        <input type="text" value="{{ @$shippingInformation->city }}" class="form-control form--control"
                               name="city" required>
                    </div>
                </div>


                <div class="col-md-12">
                    <div class="form-group">
                        <label>Postcode / ZIP </label>
                        <input type="text" value="{{ @$shippingInformation->zip }}" class="form-control form--control"
                               name="zip" required>
                    </div>
                </div>



                <div class="col-md-12">
                    <div class="form-group">
                        <label>Receiver’s Phone Number ( Optional )</label>
                        <div class="input-group">

                            <input type="number" name="mobile" value="{{ @$shippingInformation->mobile }}" class="form-control form--control">

                            <!-- Country dropdown: set fixed width -->
{{--                            <select name="mobile_country" id="mobileCountrySelect" class="form-select w-auto"--}}
{{--                                    style="max-width: 150px;" required>--}}
{{--                                @foreach ($countries as $code => $country)--}}
{{--                                    <option value="{{ $country->country }}"--}}
{{--                                            data-mobile_code="{{ $country->dial_code }}"--}}
{{--                                            data-code="{{ $code }}"--}}
{{--                                        {{ isset($shippingInformation) && @$shippingInformation->country_code == $code ? 'selected' : '' }}>--}}
{{--                                        {{ $country->country }}--}}
{{--                                    </option>--}}
{{--                                @endforeach--}}
{{--                            </select>--}}

                            <!-- Dial code -->
{{--                            <span class="input-group-text" id="dialCode" style="min-width: 70px;"></span>--}}

                            <!-- Hidden inputs -->
                            <input type="hidden" value="0" name="mobile_code" id="mobile_code">
                            <input type="hidden" value="0" name="country_code" id="country_code">
                            <input type="hidden" value="receiver@mail.com" name="email">

{{--                            <!-- Mobile number input -->--}}
{{--                            <input type="number" name="mobile" value="{{ @$shippingInformation->mobile }}"--}}
{{--                                   class="form-control form--control" placeholder="@lang('Enter whatsapp number')"--}}
{{--                                   required>--}}
{{--                        </div>--}}

{{--                        <small class="text-muted">--}}
{{--                            <i class="la la-info-circle"></i> @lang('Enter the mobile number without the country code.')--}}
{{--                        </small>--}}
                    </div>

                </div>


{{--                <div class="col-md-6">--}}
{{--                    <div class="form-group">--}}
{{--                        <label>Receiver's Email</label>--}}
{{--                        <input type="text" value="{{ @$shippingInformation->email }}" class="form-control form--control"--}}
{{--                               name="email" required>--}}
{{--                    </div>--}}
{{--                </div>--}}
            </div>

                <hr>

            @if(session('customer_photo') === 1)

                <div class="card my-4">

                    <div class="card-body">

                        <h5 class="mb-1 ">Upload Customized Product Photo</h5>

                        <div class="row">

                            <div class="col-md-6">
                                <div class="form-group">
                                    <label>@lang('Upload Front Picture')</label>
                                    <input type="file" class="form-control form--control" name="front_picture"
                                           id="front_picture" accept="image/*" required>

                                    @if(session('customer_photo_front'))
                                        <div class="mt-3 text-center position-relative d-inline-block">
                                            <img
                                                src="{{url('')}}/core/storage/app/public/{{ session('customer_photo_front')}}"
                                                alt="Front Picture"
                                                class="img-fluid rounded shadow-sm mb-2"
                                                style="max-width: 250px;">

                                            <a href="{{ route('remove_photo', ['type' => 'front']) }}"
                                               class="text-danger position-absolute"
                                               style="top: 5px; right: 10px; font-size: 20px; text-decoration: none;"
                                               title="Remove photo">
                                                &times;
                                            </a>
                                        </div>
                                    @endif

                                    <div class="mt-3 text-center">
                                        <img id="frontPreview" src="#" alt="Front Picture Preview"
                                             class="img-fluid rounded shadow-sm d-none"
                                             style="max-width: 250px; height: auto;">
                                    </div>


                                    <small class="text-info d-block mt-2">
                                        Please upload a clear front image (JPG, PNG format only, max size 2MB).
                                    </small>
                                </div>
                            </div>

                            <div class="col-md-6 ">
                                <div class="form-group">
                                    <label>@lang('Upload Back Picture')</label>
                                    <input type="file" class="form-control form--control" name="back_picture"
                                           id="back_picture" accept="image/*" required>

                                    @if(session('customer_photo_front'))
                                        <div class="mt-3 text-center position-relative d-inline-block">
                                            <img
                                                src="{{url('')}}/core/storage/app/public/{{ session('customer_photo_back')}}"
                                                alt="Back Picture" class="img-fluid rounded shadow-sm"
                                                style="max-width: 250px;">


                                            <a href="{{ route('remove_photo', ['type' => 'back']) }}"
                                               class="text-danger position-absolute"
                                               style="top: 5px; right: 10px; font-size: 20px; text-decoration: none;"
                                               title="Remove photo">
                                                &times;
                                            </a>
                                        </div>

                                    @endif


                                    <div class="mt-3 text-center">
                                        <img id="backPreview" src="#" alt="Back Picture Preview"
                                             class="img-fluid rounded shadow-sm d-none"
                                             style="max-width: 250px; height: auto;">
                                    </div>

                                    <small class="text-info d-block mt-2">
                                        Please upload a clear back image (JPG, PNG format only, max size 2MB).
                                    </small>
                                </div>
                            </div>

                            <script>
                                // Preview Function
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
                                        preview.src = '#';
                                        preview.classList.add('d-none');
                                    }
                                }

                                // Event Listeners
                                document.getElementById('front_picture').addEventListener('change', function () {
                                    previewImage(this, 'frontPreview');
                                });

                                document.getElementById('back_picture').addEventListener('change', function () {
                                    previewImage(this, 'backPreview');
                                });
                            </script>

                        </div>


                    </div>


                </div>

            @else
            @endif


            @if(session('customised_test') === 1)

                <div class="card my-4">

                    <div class="card-body">


                        <div class="row mt-4">
                            <h5 class="mb-1">Customized Text</h5>

{{--                            <p class="text-muted fst-italic">--}}
{{--                                Note about your Customized Product. Ex: special note for delivery.--}}
{{--                            </p>--}}

                            <div class="col-md-12">
                                <div class="form-group">
                                    <label>@lang('Enter Customized Text')</label>

                                    <textarea class="form-control form--control" name="customised_test" required
                                              placeholder="Enter your note here..." maxlength="5000"></textarea>

                                </div>
                            </div>


                        </div>

                    </div>
                </div>

            @endif




            @if(session('customised_short_test') === "1")

                <div class="card my-4">

                    <div class="card-body">


                        <div class="row mt-4">
                            <h5 class="mb-1">Customized Short Text (40)</h5>

                            <p class="text-muted fst-italic">
                                Short Note about your Customized Product. Ex: special note for delivery.
                            </p>

                            <div class="col-md-12">
                                <div class="form-group">
                                    <label>@lang('Enter Short Customized Text (40)')</label>

                                    <textarea class="form-control form--control" name="customised_short_test" required
                                              placeholder="Enter your short note here..." maxlength="40"></textarea>

                                </div>
                            </div>


                        </div>

                    </div>
                </div>

            @endif




            @if(session('note') === 1)

                <div class="card my-4">

                    <div class="card-body">


                        <div class="row mt-4">
                            <h5 class="mb-1">Note to Seller</h5>

                            <p class="text-muted fst-italic">
                                Note about your order. Ex: special note for delivery.
                            </p>


                            <div class="col-md-12">
                                <div class="form-group">
                                    <label>@lang('Enter Note')</label>

                                    <textarea
                                        class="form-control form--control"
                                        name="note_to_seller"
                                        id="note_to_seller"
                                        rows="4"
                                        required
                                        placeholder="Enter your note here..."
                                        maxlength="250"
                                    >{{ old('note_to_seller', session('note_to_seller')) }}</textarea>

                                    <small id="charCount" class="text-muted d-block">
                                        {{ strlen(session('note_to_seller', '')) }} / 250 characters
                                    </small>

                                    <small class="text-info d-block mt-1">
                                        Note: To include a note with your order, an additional fee of ₦5,000 will be
                                        added.
                                    </small>
                                </div>
                            </div>


                            <script>
                                const textarea = document.getElementById('note_to_seller');
                                const charCount = document.getElementById('charCount');

                                textarea.addEventListener('input', function () {
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

                    </div>
                </div>

            @endif





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
