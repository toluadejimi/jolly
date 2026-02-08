<ul class="menu {{ @$classes }} {{ !empty($withIcons) ? 'menu--with-icons' : '' }}">
    @foreach ($siteMenu as $menu)
        @php
            $url = $menu->url ?? '';
            $name = strtolower(__($menu->name));
            $iconClass = 'las la-chevron-right';
            if (str_contains($url, '/') && trim($url, '/') === '') {
                $iconClass = 'las la-home';
            } elseif (str_contains($name, 'home')) {
                $iconClass = 'las la-home';
            } elseif (str_contains($name, 'product') || str_contains($url, 'product')) {
                $iconClass = 'las la-shopping-bag';
            } elseif (str_contains($name, 'categor') || str_contains($url, 'categor')) {
                $iconClass = 'las la-th-list';
            } elseif (str_contains($name, 'contact') || str_contains($url, 'contact')) {
                $iconClass = 'las la-envelope';
            } elseif (str_contains($name, 'about') || str_contains($url, 'about')) {
                $iconClass = 'las la-info-circle';
            } elseif (str_contains($name, 'blog') || str_contains($url, 'blog')) {
                $iconClass = 'las la-newspaper';
            } elseif (str_contains($name, 'account') || str_contains($url, 'user') || str_contains($url, 'account')) {
                $iconClass = 'las la-user-circle';
            }
        @endphp
        <li>
            <a href="{{ url($menu->url) }}" @class([
                'active' => url($menu->url) == request()->url() && $menu->url != '/',
            ])>
                @if(!empty($withIcons))
                    <span class="menu-item__icon"><i class="{{ $iconClass }}"></i></span>
                @endif
                <span class="menu-item__label">{{ __($menu->name) }}</span>
            </a>
        </li>
    @endforeach
    <li>
        <a href="{{ route('api.documentation') }}" @class(['active' => Route::is('api.documentation')])>
            @if(!empty($withIcons))
                <span class="menu-item__icon"><i class="las la-code"></i></span>
            @endif
            <span class="menu-item__label">@lang('API Docs')</span>
        </a>
    </li>
</ul>
