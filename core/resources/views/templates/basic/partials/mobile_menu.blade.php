<ul class="list list--row mobile-menu-icons justify-content-center justify-content-md-end option-list d-lg-none d-flex">
    <li>
        <a href="{{ route('categories') }}" class="ecommerce" id="cate-button" aria-label="@lang('Category')">
            <span class="ecommerce__icon">
                <img src="{{ svg('category') }}" alt="">
            </span>
            <span class="ecommerce__text">@lang('Category')</span>
        </a>
    </li>
    <li class="d-lg-none">
        <a href="javascript:void(0)" class="ecommerce cart-button" title="@lang('Cart')" aria-label="@lang('Cart')">
            <span class="ecommerce__icon">
                <i class="las la-shopping-cart"></i>
                <span class="ecommerce__is cartItemCount">{{ $cartCount ?? 0 }}</span>
            </span>
            <span class="ecommerce__text">@lang('Cart')</span>
        </a>
    </li>

    <li>
        <a href="{{ url('/products') }}" class="ecommerce" aria-label="@lang('Products')">
            <span class="ecommerce__icon">
                <img src="{{ svg('product') }}" alt="">
            </span>
            <span class="ecommerce__text">@lang('Products')</span>
        </a>
    </li>




    <li>
        <a href="javascript:void(0)" class="ecommerce @auth user-account-btn @endauth" id="account-button" aria-label="@lang('My Account')" @guest data-bs-toggle="modal" data-bs-target="#loginModal" @endguest>
            <span class="ecommerce__icon">
                <img src="{{ svg('my_account') }}" alt="">
            </span>
            <span class="ecommerce__text">@lang('My Account')</span>
        </a>
    </li>
</ul>


<div class="site-sidebar mobile-menu sidebar-nav d-lg-none">
    <button type="button" class="sidebar-close-btn">
        <i class="las la-times"></i>
    </button>

    <div class="mobile-menu-header">
        <div class="d-block d-lg-none">
            @include('Template::partials.menu.language_menu')
        </div>
    </div>
    <div class="mobile-menu-body">
        @include('Template::partials.menu.site_menu')
    </div>
</div>
