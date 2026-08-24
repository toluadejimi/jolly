@php
    $footer = getContent('footer.content', true);
    $footer = @$footer->data_values;
    $socials = getContent('social_icon.element', orderById: true);
    $footerMenu = \App\Models\Frontend::where('data_keys', 'footer_menu.content')->first();
    $menus = $footerMenu?->data_values;
    $iosAppUrl = 'https://apps.apple.com/us/app/jollyboxfr/id6759364001';
    $androidAppUrl = route('app.download.android');
@endphp

<!-- Footer Section Starts Here -->
<footer class="footer-area footer-bg ">
    <div class="container">
        <div class="footer-products-link py-3 d-flex flex-wrap align-items-center gap-3 gap-md-4">
            <a href="{{ route('home') }}" class="footer-product-link d-inline-flex align-items-center gap-2">
                <i class="las la-home footer-product-icon" style="font-size: 1.25rem;"></i>
                <span>@lang('Home')</span>
            </a>
            <a href="{{ route('categories') }}" class="footer-product-link d-inline-flex align-items-center gap-2">
                <img src="{{ svg('product') }}" alt="" class="footer-product-icon" width="20" height="20">
                <span>@lang('Products')</span>
            </a>
            <a href="{{ route('api.documentation') }}" class="footer-product-link d-inline-flex align-items-center gap-2">
                <i class="las la-code footer-product-icon" style="font-size: 1.25rem;"></i>
                <span>@lang('API Docs')</span>
            </a>
        </div>

        @include('Template::sections.app_download')

        @if ($menus)
            <div class="footer-middle">
                @foreach ($menus as $menu)
                    <div class="footer-widget widget-link">
                        <h6 class="title">{{ __($menu->title) }}</h6>
                        <ul>
                            @foreach ($menu->links as $link)
                                <li><a href="{{ url($link->url) }}">{{ __($link->name) }}</a></li>
                            @endforeach
                        </ul>
                    </div>
                @endforeach
            </div>
        @endif

        <div class="footer-copyright">
            <div class="copyright-area d-flex flex-wrap align-items-center justify-content-between gap-4 flex-wrap-reverse">
                @if (@$footer->copyright_text)
                    <div class="left">
                        @php
                            $copyrightText = str_replace('{year}', date('Y'), $footer->copyright_text);
                            $siteName = '<a href="' . route('home') . '">' . e(gs('site_name')) . '</a>';
                            $copyrightText = str_replace('{site_name}', $siteName, $copyrightText);
                        @endphp
                        <p>{!! __(@$copyrightText) !!}</p>
                    </div>
                @endif

                <div class="footer-social-row d-flex flex-wrap align-items-center gap-3">
                    <a href="https://wa.me/2349039875741?text=Hi%20JollyBoxfr,%20I%20Got%20This%20Number%20from%20site"
                       class="footer-whatsapp"
                       target="_blank"
                       rel="noopener noreferrer"
                       aria-label="@lang('Chat on WhatsApp')">
                        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                            <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                        </svg>
                        <span>@lang('WhatsApp')</span>
                    </a>

                    @if ($socials->count() > 0)
                        <ul class="social-icons d-flex gap-2 flex-wrap mt-0 mb-0">
                            @foreach ($socials as $item)
                                <li>
                                    <a href="{{ $item->data_values->url }}" target="_blank" rel="noopener noreferrer">
                                        @php
                                            echo $item->data_values->social_icon;
                                        @endphp
                                    </a>
                                </li>
                            @endforeach
                        </ul>
                    @endif
                </div>

                @if (@$footer->payment_methods)
                    <div class="right">
                        <img src="{{ getImage(null) }}"
                            data-src="{{ getImage('assets/images/frontend/footer/' . @$footer->payment_methods, '250x30') }}"
                            class="lazyload" alt="@lang('footer')">
                    </div>
                @endif
            </div>
        </div>
    </div>

    <style>
        .footer-whatsapp {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 8px 14px;
            border-radius: 999px;
            background: #25D366;
            color: #fff !important;
            font-weight: 700;
            font-size: 14px;
            text-decoration: none !important;
            box-shadow: 0 4px 12px rgba(37, 211, 102, 0.35);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }
        .footer-whatsapp:hover {
            color: #fff !important;
            transform: translateY(-1px);
            box-shadow: 0 6px 16px rgba(37, 211, 102, 0.45);
        }
        .footer-whatsapp svg {
            width: 18px;
            height: 18px;
            fill: #fff;
            flex-shrink: 0;
        }
        @media (max-width: 767.98px) {
            .footer-social-row {
                width: 100%;
                justify-content: center;
            }
        }
    </style>
</footer>
<!-- Footer Section Ends Here -->

<div class="modal fade" id="quickView">
    <div class="modal-dialog modal-dialog-centered modal-xl" role="document">
        <div class="modal-content">
            <button type="button" class="close modal-close-btn " data-bs-dismiss="modal" aria-label="Close">
                <i class="las la-times"></i>
            </button>
            <div class="modal-body">
                <div class="ajax-loader-wrapper d-flex align-items-center justify-content-center">
                    <div class="spinner-border" role="status">
                        <span class="sr-only">@lang('Loading')...</span>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
