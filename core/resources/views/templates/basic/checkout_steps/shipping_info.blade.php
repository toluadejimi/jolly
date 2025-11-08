@extends($activeTemplate . 'layouts.checkout')

@section('blade')

    @if(session('customer_photo') === 1)

        <div class="card my-4">

            <div class="card-body">

                <h5 class="mb-1 ">Upload Customized Product Photo</h5>

                <form action="{{ url('checkout/upload-customer-picture') }}" method="POST"
                      enctype="multipart/form-data">
                    @csrf

                    <div class="row">

                        <div class="col-md-6">
                            <div class="form-group">
                                <label>@lang('Upload Front Picture')</label>
                                <input type="file" class="form-control form--control" name="front_picture"
                                       id="front_picture" accept="image/*" required>

                                @if(session('customer_photo_front'))
                                    <div class="mt-3 text-center position-relative d-inline-block">
                                        <img src="{{url('')}}/core/storage/app/public/{{ session('customer_photo_front')}}"
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
                                        <img src="{{url('')}}/core/storage/app/public/{{ session('customer_photo_back')}}"
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

                    <button type="submit" class="btn btn-success btn-lg">Add Photo</button>

                </form>


            </div>


        </div>

    @else
    @endif


    @if(session('note') === 1)

        <div class="card my-4">

            <div class="card-body">


                <div class="row mt-4">
                    <h5 class="mb-1">Note to Seller</h5>

                    <p class="text-muted fst-italic">
                        Note about your order. Ex: special note for delivery.
                    </p>

                    <form action="{{ url('checkout/upload-note') }}" method="POST" enctype="multipart/form-data">
                        @csrf

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
                                    Note: To include a note with your order, an additional fee of ₦5,000 will be added.
                                </small>
                            </div>
                        </div>

                        <button type="submit" class="btn btn-success btn-lg">Upload Note</button>
                    </form>

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

    @if(session('customised_test') === 1)

        <div class="card my-4">

            <div class="card-body">


                <div class="row mt-4">
                    <h5 class="mb-1">Customized Text</h5>

                    <p class="text-muted fst-italic">
                        Note about your order. Ex: special note for delivery.
                    </p>

                    <form action="{{ url('checkout/upload-customised-test') }}" method="POST" enctype="multipart/form-data">
                        @csrf

                        <div class="col-md-12">
                            <div class="form-group">
                                <label>@lang('Enter Customized Text')</label>

                                <textarea
                                    class="form-control form--control"
                                    name="customized_text"
                                    required
                                    placeholder="Enter your customized text here..."
                                    maxlength="5000"
                                >{{ old('customized_text', session('customized_text')) }}</textarea>


                            </div>
                        </div>

                        <button type="submit" class="btn btn-success btn-lg">Update Customized Text</button>
                    </form>

                </div>

            </div>
        </div>

    @endif



    <div class="address-wrapper">


        @foreach ($shippingAddresses as $item)
            @php
                $checkoutData = session('shipping_info');
                $guestShippingInfo = session('guest_shipping_info');
                if (@$checkoutData['shipping_address_id'] == $item->id) {
                    $isChecked = true;
                } elseif ($loop->first) {
                    $isChecked = true;
                } else {
                    $isChecked = false;
                }
            @endphp

            <label class="address-single" for="address-{{ $item->id }}">
                <div class="flex-fill">
                    <div class="address-item-left">
                        <div class="form--check d-inline-block">
                            <input class="form-check-input mt-0" type="radio" name="shipping_address_id"
                                   value="{{ $item->id }}" form="shipping-form" value=""
                                   id="address-{{ $item->id }}" @checked($isChecked)>
                        </div>
                        <h6>{{ $item->label }}</h6>
                    </div>
                    <div class="address-item-right">
                        <div class="address-item-inner">
                            <span class="address-item-label">@lang('Address')</span>
                            <span class="address-item-value"> <span
                                    class="item-devide">:</span> {{ $item->address }}</span>
                        </div>
                        <div class="address-item-inner">
                            <span class="address-item-label">@lang('Zip Code')</span>
                            <span class="address-item-value"> <span class="item-devide">:</span> {{ $item->zip }}</span>
                        </div>
                        <div class="address-item-inner">
                            <span class="address-item-label">@lang('City')</span>
                            <span class="address-item-value"> <span
                                    class="item-devide">:</span> {{ $item->city }}</span>
                        </div>
                        <div class="address-item-inner">
                            <span class="address-item-label">@lang('State')</span>
                            <span class="address-item-value"> <span
                                    class="item-devide">:</span> {{ $item->state }}</span>
                        </div>
                        <div class="address-item-inner">
                            <span class="address-item-label">@lang('Country')</span>
                            <span class="address-item-value"> <span
                                    class="item-devide">:</span> {{ $item->country }}</span>
                        </div>
                        <div class="address-item-inner">
                            <span class="address-item-label">@lang('Phone')</span>
                            <span class="address-item-value"> <span
                                    class="item-devide">:</span> {{ $item->mobile }}</span>
                        </div>
                    </div>
                </div>

                <div class="position-relative text-end">
                    <button type="button" data-resource="{{ $item }}" class="btn btn-outline--light editAddress">
                        <i class="la la-pencil"></i>
                        <span class="d-none d-sm-inline">@lang('Change')</span>
                    </button>
                </div>
            </label>
        @endforeach


        <button class="newAddress w-100 address-single-add-new">
            <i class="las la-plus-circle"></i>
            <span class="add-new-title d-block">@lang('Add New Address')</span>
        </button>


    </div>





    <div class="d-flex align-items-center justify-content-between flex-wrap mt-4">
        <a href="{{ route('cart.page') }}" class="text--base">
            <i class="las la-angle-left"></i> @lang('Back to Cart')
        </a>

        <form action="{{ route('checkout.shipping.info.add') }}" method="POST" id="shipping-form">
            @csrf
            <button type="submit" class="btn btn--base h-45">@lang('Continue to Next') <i
                    class="las la-angle-right"></i></button>
        </form>

    </div>
@endsection

@push('modal')
    <x-dynamic-component :component="frontendComponent('shipping-address-modal')" :countries="$countries"/>
@endpush

@push('style')
    <style>
        .add-new-title {
            font-size: 1rem;
            color: hsl(var(--body-color) / 0.8);
        }
    </style>
@endpush
