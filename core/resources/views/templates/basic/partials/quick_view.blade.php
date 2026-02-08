<div class="row g-4 g-xl-5 product-details-container">
    <div class="col-md-5" id="variantImages">
        @include($activeTemplate . 'partials.product_images')
    </div>

    <div class="col-md-7">
        <div class="product-details">
            <div class="product-header">
                <h1 class="product-title product-id" data-pdi="{{ $product->id }}">{{ __($product->name) }}</h1>

                <div class="d-flex flex-wrap align-items-center gap-2 product-detail-price">
                    <span class="product-price" id="productPrice">
                        @php echo $product->formattedPrice(); @endphp
                    </span>
                    <span id="stockBadge"></span>
                </div>

{{--                <div class="product-header-actions d-flex gap-2 flex-wrap">--}}
{{--                    <button class="btn btn--base btn--sm flex-shrink-0 showShippingFormBtn"--}}
{{--                            data-id="{{ $product->id }}"--}}
{{--                            data-product_type="{{ $product->product_type }}"--}}
{{--                            type="button">--}}
{{--                        Buy Now--}}
{{--                    </button>--}}
{{--                </div>--}}
            </div>

            @if ($product->summary)
                <div class="product-summary">
                    {{ __($product->summary) }}
                </div>
            @endif

            <div class="product-types d-flex flex-column">
                <span>
                    <b class="product-details-label">@lang('Categories'): </b>
                    @forelse ($product->categories as $category)
                        <a href="{{ $category->shopLink() }}">{{ __($category->name) }}</a>
                        @if (!$loop->last)
                            /
                        @endif
                    @empty
                        @lang('Uncategorized')
                    @endforelse
                </span>





            </div>

            @if ($product->product_type == Status::PRODUCT_TYPE_VARIABLE && $product->attributes->count())
                <div class="product-attribute position-relative">
                    <div class="ajax-preloader d-none"></div>
                    @foreach ($product->attributes as $attribute)
                        @php
                            $attributeValues = $product->attributeValues->where('attribute_id', $attribute->id);
                            $attributeTypeClass = $attribute->type == Status::ATTRIBUTE_TYPE_TEXT ? 'product-size-area' : 'product-color-area';
                        @endphp

                        <div class="attribute-value-wrapper attributeValueArea">
                            <span class="attribute-name fw-600">{{ __(@$attribute->name) }}:</span>

                            @foreach ($attributeValues as $attributeValue)
                                @php
                                    $data = ['id' => $attributeValue->id, 'type' => $attribute->type];
                                @endphp
                                <button class="attribute-value attributeBtn" data-attribute='@json($data)' data-media_id="{{ $attributeValue->pivot->media_id }}">
                                    @if ($attribute->type == Status::ATTRIBUTE_TYPE_TEXT)
                                        <span class="text-attribute">{{ $attributeValue->value }}</span>
                                    @elseif($attribute->type == Status::ATTRIBUTE_TYPE_COLOR)
                                        <span class="color-attribute colorAttribute" data-color="{{ $attributeValue->value }}" style="background:#{{ $attributeValue->value }}"></span>
                                    @else
                                        <span class="color-attribute bg--img" data-media_id="{{ $attributeValue->pivot->media_id }}" data-background="{{ getImage(getFilePath('attribute') . '/' . $attributeValue->value) }}" />
                                    @endif
                                </button>
                            @endforeach
                        </div>
                    @endforeach
                </div>
            @endif

            <div class="d-flex gap-2 flex-column">
                <div class="product-add-to-cart">
{{--                    <x-frontend.quantity-input :isDigital="$product->is_downloadable" data-update="no" />--}}


                    @auth

                        <button class="btn btn--base btn--sm flex-shrink-0 showShippingFormBtn"
                                data-id="{{ $product->id }}"
                                data-product_type="{{ $product->product_type }}"
                                type="button">
                            @lang('Buy Now')
                        </button>


                    @else

                        <div class="justify-content-center my-5">
                            <a href="javascript:void(0)" data-bs-toggle="modal" data-bs-target="#loginModal" class="btn btn--base btn--lg">
                                Login to Continue
                            </a>
                        </div>


                        <!-- Login Modal -->
                        <div class="modal fade" id="loginModal" tabindex="-1" aria-labelledby="loginModalLabel" aria-hidden="true">
                            <div class="modal-dialog modal-dialog-centered">
                                <div class="modal-content">

                                    <div class="modal-header">
                                        <h5 class="modal-title" id="loginModalLabel">Login</h5>
                                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                                    </div>

                                    <div class="modal-body">

                                        <form action="{{ route('user.login.product') }}" method="POST" id="loginModalForm">
                                            @csrf

                                            <div class="form-group mb-3">
                                                <label class="form-label">Email</label>
                                                <input type="email" name="username" class="form-control form--control"
                                                       placeholder="Enter your email" required>
                                            </div>

                                            <div class="form-group mb-2">
                                                <label class="form-label">Password</label>
                                                <input type="password" name="password" class="form-control form--control"
                                                       placeholder="Enter your password" required>
                                            </div>

                                            <div class="d-flex justify-content-between align-items-center mb-3">
                                                <div class="form-check">
                                                    <input class="form-check-input" type="checkbox" value="1" id="remember" name="remember">
                                                    <label class="form-check-label" for="remember">
                                                        Remember Me
                                                    </label>
                                                </div>

                                                <a href="{{ route('user.password.request') }}" class="text--base">
                                                    Forgot Password?
                                                </a>
                                            </div>

                                            <button type="submit" class="btn btn--base w-100 h-45">
                                                Login
                                            </button>
                                        </form>

                                        <div class="text-center mt-3">
                                            <span>Don't have an account?</span>
                                            <a href="{{ route('user.register') }}" class="text--base fw-bold">Register</a>
                                        </div>

                                    </div>

                                </div>
                            </div>
                        </div>



                    @endauth


{{--                    <button class="btn btn--base btn--sm addToCart flex-shrink-0" data-id="{{ $product->id }}" data-product_type="{{ $product->product_type }}" @disabled(!$product->salePrice()) type="button">@lang('Buy Now')</button>--}}
                </div>
{{--                <div class="product-wishlist d-flex gap-2 mt-3">--}}

{{--                    @if (gs('product_wishlist'))--}}
{{--                        <button class="add-to-wishlist-btn @if (checkWishList($product->id)) active @endif addToWishlist" data-id="{{ $product->id }}">--}}
{{--                            <span class="wish-icon"></span> @lang('Wishlist')--}}
{{--                        </button>--}}
{{--                    @endif--}}

{{--                    @if ($product->product_type_id && gs('product_compare'))--}}
{{--                        <button class="add-to-wishlist-btn  @if (checkCompareList($product->id)) active @endif addToCompare" data-id="{{ $product->id }}">--}}
{{--                            <i class="las la-exchange-alt compare-icon"></i> @lang('Compare')--}}
{{--                        </button>--}}
{{--                    @endif--}}
{{--                </div>--}}

            </div>

{{--            @if ($quickView)--}}
{{--                <div>--}}
{{--                    <a class="btn btn-sm btn--base outline" href="{{ $product->link() }}">@lang('View Details')</a>--}}
{{--                </div>--}}
{{--            @else--}}
{{--                <x-frontend.product-sharer :product="$product" />--}}
{{--            @endif--}}
        </div>
    </div>
</div>

@if (!$quickView)
    @push('script')
    @endif
    <script src="{{ asset($activeTemplateTrue . 'js/product_details.js') }}?{{ time() }}"></script>

    <script>
        "use strict";

        $('.product-details-container').productDetails({
            productId: @json($product->id),
            totalAttributes: @json($product->attributes->count()),
            stockQuantity: @json($product->totalInStock()),
            trackInventory: @json($product->track_inventory == Status::YES),
            showStockQuantity: @json($product->show_stock && $product->track_inventory && $product->product_type == Status::PRODUCT_TYPE_SIMPLE),
            variantImageLoadUrl: "{{ route('product.variant.image', [':productId', ':attributeId']) }}",
            checkStockUrl: "{{ route('product.variant.stock', $product->slug) }}"
        });
    </script>

    @if (!$quickView)
    @endpush
@endif

@pushIf(!$quickView, 'script')

<script>
    (function($) {
        "use strict";

        const recentlyViewedLimit = {{ gs('recently_viewed_items') }} * 1;

        @if (gs('recently_viewed_items') > 0)
            const product = {
                pdi: $('.product-id').data('pdi'),
                pna: $('.product-title').text().trim(),
                plink: window.location.href,
                pima: $('.product-gallery img').attr('src'),
                date: Date.now()
            };

            addToRecentlyViewed(product);

            function addToRecentlyViewed(product) {
                let viewedProducts = JSON.parse(localStorage.getItem("recentlyViewed")) || [];

                viewedProducts = viewedProducts.filter(item => item.pdi !== product.pdi);

                viewedProducts.unshift(product);

                if (viewedProducts.length > recentlyViewedLimit) {
                    viewedProducts.pop();
                }

                localStorage.setItem("recentlyViewed", JSON.stringify(viewedProducts));
            }
        @endif
    })
    (jQuery);
</script>
@endPushIf


    @push('script')
        <script>
            "use strict";
            (function($){

                function totalRequiredAttributes() {
                    return parseInt(@json($product->attributes->count())) || 0;
                }

                function totalSelectedAttributes() {
                    return $('.attributeBtn.active').length || 0;
                }

                function validateVariantBeforeProceed() {
                    const required = totalRequiredAttributes();
                    if (required <= 0) return true;

                    const selected = totalSelectedAttributes();
                    return selected >= required;
                }

                $(document).on('click', '.showShippingFormBtn', function () {

                    // ✅ Check variants if variable product
                    const productType = "{{ $product->product_type }}";
                    const variableType = "{{ Status::PRODUCT_TYPE_VARIABLE }}";

                    if (productType == variableType) {
                        if (!validateVariantBeforeProceed()) {
                            notify('error', 'Please select product options (variant) before continuing');
                            return;
                        }
                    }

                    // ✅ show the form
                    $('#shippingFormCard').removeClass('d-none');

                    // ✅ scroll to form
                    document.getElementById('shippingFormCard')?.scrollIntoView({
                        behavior: "smooth",
                        block: "start"
                    });

                    // ✅ optional highlight effect
                    $('#shippingFormCard').addClass('border border--base');
                    setTimeout(function(){
                        $('#shippingFormCard').removeClass('border border--base');
                    }, 2000);
                });

            })(jQuery);
        </script>
    @endpush


    @push('script')
        <script>
            "use strict";
            (function($){

                // collect selected variants and store in hidden input
                function updateVariantAttributes() {
                    let selected = [];

                    $('.attributeBtn.active').each(function () {
                        const data = $(this).data('attribute'); // {id: ?, type: ?}
                        if (data) selected.push(data);
                    });

                    $('#variantAttributes').val(JSON.stringify(selected));
                    return selected;
                }

                // whenever user clicks variant button, update hidden field
                $(document).on('click', '.attributeBtn', function () {
                    setTimeout(updateVariantAttributes, 100);
                });

                // when Buy Now clicked and form revealed
                $(document).on('click', '.showShippingFormBtn', function () {
                    updateVariantAttributes();
                });

                // ✅ IMPORTANT: before submitting shipping form
                $('#shipping-form').on('submit', function (e) {
                    updateVariantAttributes();
                });

            })(jQuery);
        </script>
    @endpush

