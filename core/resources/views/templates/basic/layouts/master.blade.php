@extends('Template::layouts.app')

@section('app')
    @include('Template::partials.header')

    <main>
        @yield('content')
    </main>

    @if (!Route::is('cart.page'))
        <div class="site-sidebar cart-sidebar-area" id="cart-sidebar-area">
            <button class="sidebar-close-btn"><i class="las la-times"></i></button>
            <div class="top-content d-flex gap-2">
                <h5 class="cart-sidebar-area__title">@lang('My Cart')</h5>
                <a href="{{ route('cart.page') }}" class="text-muted text-decoration-underline">@lang('Cart Page')</a>
            </div>
            <div class="cart-products cart--products"></div>
        </div>
    @endif

    @if (gs('product_wishlist'))
        <div class="site-sidebar cart-sidebar-area wishlist-sidebar" id="wish-sidebar-area">
            <button class="sidebar-close-btn"><i class="las la-times"></i></button>
            <div class="top-content d-flex gap-2">
                <h5 class="cart-sidebar-area__title">@lang('My Wishlist')</h5>
                <a href="{{ route('wishlist.page') }}" class="text-muted text-decoration-underline">@lang('Wishlist Page')</a>
            </div>
            <div class="cart-products wish--products"></div>
        </div>
    @endif

    @auth
        <div class="site-sidebar sidebar-nav auth-sidebar" id="authSidebarMenu">
            <div class="auth-sidebar__header">
                <h5 class="auth-sidebar__title">@lang('My Account')</h5>
                <button type="button" class="sidebar-close-btn auth-sidebar__close" aria-label="@lang('Close')"><i class="las la-times"></i></button>
            </div>
            <ul class="login-user-menu auth-sidebar__menu">
                @include('Template::user.partials.sidebar')
            </ul>
        </div>
    @endauth

    <a class="scrollToTop" href="javascript:void(0)"><i class="las la-angle-up"></i></a>

    @php
        $cookie = App\Models\Frontend::where('data_keys', 'cookie.data')->first();
    @endphp

    @if ($cookie && $cookie->data_values->status == Status::ENABLE && !\Cookie::get('gdpr_cookie'))
        <div class="cookies-card text-center hide">
            <div class="cookies-card__icon bg--base">
                <i class="las la-cookie-bite"></i>
            </div>
            <p class="mt-4 cookies-card__content">
                {{ $cookie->data_values->short_desc }}
                <a href="{{ route('cookie.policy') }}" target="_blank" class="text--base">@lang('Learn more')</a>
            </p>
            <div class="cookies-card__btn mt-4">
                <a class="btn btn--base w-100 policy h-45" href="javascript:void(0)">@lang('Allow')</a>
            </div>
        </div>
    @endif

    @include('Template::partials.footer')

    {{-- Login Modal --}}
    @guest
        <div class="modal custom--modal fade" id="loginModal" tabindex="-1" role="dialog">
            <div class="modal-dialog modal-dialog-centered" role="document">
                <div class="modal-content">
                    <div class="modal-body">
                        <button type="button" class="close modal-close-btn" data-bs-dismiss="modal" aria-label="Close">
                            <i class="las la-times"></i>
                        </button>

                        @include('Template::partials.login')
                    </div>
                </div>
            </div>
        </div>
    @endguest

    {{-- Guest Checkout Modal --}}
    @if (gs('guest_checkout'))
        @guest
            @include('Template::partials.guest_user_info')
        @endguest
    @endif
@endsection


{{-- ✅ STYLE LIBS --}}
@push('style-lib')
    {{-- Select2 CSS --}}
    <link rel="stylesheet" href="{{ asset('assets/global/css/select2.min.css') }}">
@endpush


{{-- ✅ SCRIPT LIBS --}}
@push('script-lib')
    {{-- Select2 JS --}}
    <script src="{{ asset('assets/global/js/select2.min.js') }}"></script>

    {{-- Lazyload JS (✅ moved here, was wrongly in style-lib) --}}
    <script src="{{ asset($activeTemplateTrue . 'js/lazyload.js') }}"></script>
@endpush


{{-- ✅ PAGE SCRIPTS --}}
@push('script')
    <script>
        (function($) {
            "use strict";

            // Close sidebar when login is clicked
            $(document).on('click', '.login-trigger', function() {
                $(".sidebar-close-btn").trigger('click');
            });

            // Cookie policy accept
            $('.policy').on('click', function() {
                $.get("{{ route('cookie.accept') }}", function(response) {
                    $('.cookies-card').addClass('d-none');
                });
            });

            // ✅ prevent select2 errors everywhere
            // only init select2 if library exists
            $(document).ready(function () {
                if ($.fn.select2) {
                    $('.select2').select2({
                        width: '100%'
                    });
                }
            });

        })(jQuery);
    </script>

    <x-frontend.visermart-script />
@endpush
