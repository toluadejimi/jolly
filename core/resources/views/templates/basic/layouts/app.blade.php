<!doctype html>
<html lang="{{ config('app.locale') }}" itemscope itemtype="http://schema.org/WebPage" data-theme="light">
<head>
    <script>
        (function(){
            var saved = localStorage.getItem('site-theme');
            var t = saved || (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
            document.documentElement.setAttribute('data-theme', t);
        })();
    </script>
    <!-- Required meta tags -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title> {{ gs()->siteName(__($pageTitle)) }}</title>
    @include('partials.seo')
    <link type="image/x-icon" href="{{ siteFavicon() }}" rel="shortcut icon">
    <link rel="stylesheet" href="{{ asset('assets/global/css/bootstrap.min.css') }}">
    <link rel="stylesheet" href="{{ asset('assets/global/css/all.min.css') }}">
    <link rel="stylesheet" href="{{ asset('assets/global/css/line-awesome.min.css') }}">
    @stack('style-lib')
    <link rel="stylesheet" href="{{ asset($activeTemplateTrue . 'css/main.css') }}">
    <link rel="stylesheet" href="{{ asset($activeTemplateTrue . 'css/color.php?color=' . gs('base_color')) }}">
    @stack('style')
    <link href="{{ asset($activeTemplateTrue . 'css/custom.css') }}" rel="stylesheet">

    <script src="{{ asset('assets/global/js/jquery-3.7.1.min.js') }}"></script>


    <style>
        .product-badge {
            position: absolute;
            top: 10px;
            left: 10px;
            background: linear-gradient(90deg, #007c2e, #00b82e);
            color: white;
            font-weight: 600;
            padding: 4px 10px;
            font-size: 13px;
            border-radius: 3px;
            z-index: 10;
            box-shadow: 0 2px 5px rgba(0,0,0,0.2);
        }

    </style>
</head>

@php
    $cartCount = cartManager()->setCartCount();
@endphp




@php echo loadExtension('google-analytics') @endphp

<body>
    <div class="body-overlay" id="body-overlay"></div>
    @include('Template::partials.preloader')

    @yield('app')

    @stack('modal')

    <script src="{{ asset('assets/global/js/jquery-3.7.1.min.js') }}"></script>
    <script src="{{ asset('assets/global/js/bootstrap.bundle.min.js') }}"></script>
    <script src="{{ asset($activeTemplateTrue . 'js/jquery.validate.js') }}"></script>
    @stack('script-lib')
    <script src="{{ asset($activeTemplateTrue . 'js/main.js') }}"></script>
    @php echo loadExtension('tawk-chat') @endphp
    @include('partials.notify')
    @if (gs('pn'))
        @include('partials.push_script')
    @endif

    @push('script')
        <script>
            "use strict";

            (function($){

                function getSelectedAttributeValues() {
                    let values = [];

                    $('.attributeBtn.active').each(function () {
                        const data = $(this).data('attribute');
                        if (data && data.id) {
                            values.push(data.id);
                        }
                    });

                    return values;
                }

                $('.addToCartBtn').on('click', function () {

                    const productId = $(this).data('id');
                    const productType = $(this).data('product_type');
                    const variableType = "{{ Status::PRODUCT_TYPE_VARIABLE }}";

                    let attributeValues = [];

                    if(productType == variableType){
                        attributeValues = getSelectedAttributeValues();

                        if(attributeValues.length == 0){
                            notify('error', 'Please select product options');
                            return;
                        }
                    }

                    $.ajax({
                        url: "{{ route('cart.add', ':id') }}".replace(':id', productId),
                        method: "POST",
                        data: {
                            _token: "{{ csrf_token() }}",
                            quantity: 1,
                            attribute_values: attributeValues
                        },
                        success: function(res){
                            notify('success', res.message || 'Added to cart');

                            // Update cart count, sidebar content, and open cart sidebar
                            if(res.data){
                                $('.cartItemCount').text(res.data.cartItemCount).removeClass('d-none');
                                $('.cart-count').text(res.data.cartItemCount);
                                $('.cart--products').html(res.data.partialCartData);
                                $('.cartSubtotal').text(res.data.cartSubtotal);
                                $('#cart-sidebar-area').addClass('active');
                                $('.body-overlay').addClass('active');
                                $('body').addClass('scroll-hide-sm');
                            }
                        },
                        error: function(xhr){
                            if(xhr.responseJSON && xhr.responseJSON.message){
                                notify('error', xhr.responseJSON.message);
                            } else {
                                notify('error', 'Something went wrong');
                            }
                        }
                    });

                });

            })(jQuery);

            (function themeSwitcher() {
                function getTheme() { return document.documentElement.getAttribute('data-theme') || 'light'; }
                function setTheme(theme) {
                    document.documentElement.setAttribute('data-theme', theme);
                    try { localStorage.setItem('site-theme', theme); } catch (e) {}
                    var isDark = theme === 'dark';
                    document.querySelectorAll('.theme-icon-light').forEach(function(el) { el.classList.toggle('d-none', isDark); });
                    document.querySelectorAll('.theme-icon-dark').forEach(function(el) { el.classList.toggle('d-none', !isDark); });
                }
                function initIcons() {
                    var isDark = getTheme() === 'dark';
                    document.querySelectorAll('.theme-icon-light').forEach(function(el) { el.classList.toggle('d-none', isDark); });
                    document.querySelectorAll('.theme-icon-dark').forEach(function(el) { el.classList.toggle('d-none', !isDark); });
                }
                initIcons();
                document.querySelectorAll('.theme-switcher-btn').forEach(function(btn) {
                    btn.addEventListener('click', function() {
                        var next = getTheme() === 'dark' ? 'light' : 'dark';
                        setTheme(next);
                    });
                });
            })();
        </script>
    @endpush

    @stack('script')

</body>

</html>
