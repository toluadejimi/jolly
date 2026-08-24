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

        <div class="app-download-section">
            <div class="app-download-card">
                <div class="app-download-copy">
                    <span class="app-download-eyebrow">@lang('Mobile app')</span>
                    <h5 class="app-download-title">@lang('Shop on the go with Jollyboxfr')</h5>
                    <p class="app-download-text">@lang('Order gifts, track deliveries, and chat with support from your phone.')</p>
                </div>
                <div class="app-download-badges">
                    <a href="{{ $androidAppUrl }}"
                       class="app-store-badge app-store-badge--android"
                       download="jollyboxfr.apk"
                       aria-label="@lang('Download Android APK')">
                        <span class="app-store-badge__icon" aria-hidden="true">
                            <svg viewBox="0 0 24 24" width="26" height="26" fill="currentColor">
                                <path d="M17.6 9.48l1.84-3.18a.5.5 0 10-.86-.5l-1.9 3.28A7.97 7.97 0 0012 8c-1.74 0-3.34.56-4.68 1.5L5.42 5.8a.5.5 0 10-.86.5L6.4 9.48C4.36 11.06 3 13.37 3 16h18c0-2.63-1.36-4.94-3.4-6.52zM8.5 13.5a1 1 0 110 2 1 1 0 010-2zm7 0a1 1 0 110 2 1 1 0 010-2zM7 18v2.5a1 1 0 001 1h1v-3.5H7zm8 0V21.5h1a1 1 0 001-1V18h-2z"/>
                            </svg>
                        </span>
                        <span class="app-store-badge__text">
                            <small>@lang('Download for')</small>
                            <strong>Android</strong>
                        </span>
                    </a>
                    <a href="{{ $iosAppUrl }}"
                       class="app-store-badge app-store-badge--ios"
                       target="_blank"
                       rel="noopener noreferrer"
                       aria-label="@lang('Download on the App Store')">
                        <span class="app-store-badge__icon" aria-hidden="true">
                            <svg viewBox="0 0 24 24" width="26" height="26" fill="currentColor">
                                <path d="M16.7 12.7c0-2.1 1.7-3.1 1.8-3.2-1-1.5-2.5-1.7-3.1-1.7-1.3-.1-2.6.8-3.2.8-.7 0-1.8-.8-3-.7-1.5.1-2.9.9-3.7 2.3-1.6 2.7-.4 6.7 1.1 8.9.8 1.1 1.7 2.3 2.9 2.2 1.2-.1 1.6-.7 3-.7s1.8.7 3 .7c1.3 0 2.1-1.1 2.8-2.2.9-1.3 1.3-2.5 1.3-2.6-.1 0-2.4-.9-2.4-3.8zM14.5 6.4c.6-.8 1.1-1.9.9-3-.9.1-2 .6-2.6 1.4-.6.7-1.1 1.8-.9 2.9 1 .1 2-.5 2.6-1.3z"/>
                            </svg>
                        </span>
                        <span class="app-store-badge__text">
                            <small>@lang('Download on the')</small>
                            <strong>App Store</strong>
                        </span>
                    </a>
                </div>
            </div>
        </div>

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
        @if (@$footer->copyright_text || $socials->count() > 0 || @$footer->payment_methods)
            <div class="footer-copyright">
                <div
                    class="copyright-area d-flex flex-wrap align-items-center @if ($socials->count() == 0 && !@$footer->payment_methods) justify-content-center @else justify-content-between @endif gap-4 flex-wrap-reverse">

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

                    @if ($socials->count() > 0)
                        <ul class="social-icons d-flex gap-2 flex-wrap mt-0">
                            @foreach ($socials as $item)
                                <li>
                                    <a href="{{ $item->data_values->url }}" target="_blank">
                                        @php
                                            echo $item->data_values->social_icon;
                                        @endphp
                                    </a>
                                </li>
                            @endforeach
                        </ul>
                    @endif
                    @if (@$footer->payment_methods)
                        <div class="right">
                            <img src="{{ getImage(null) }}"
                                data-src="{{ getImage('assets/images/frontend/footer/' . @$footer->payment_methods, '250x30') }}"
                                class="lazyload" alt="@lang('footer')">
                        </div>
                    @endif
                </div>
            </div>
        @endif
    </div>

    <style>
        .app-download-section {
            padding: 8px 0 28px;
        }
        .app-download-card {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            gap: 20px;
            padding: 22px 24px;
            border-radius: 18px;
            background: linear-gradient(135deg, #FF5F1F 0%, #ff8a4c 55%, #ffb089 100%);
            box-shadow: 0 12px 28px rgba(255, 95, 31, 0.28);
            color: #fff;
        }
        .app-download-eyebrow {
            display: inline-block;
            font-size: 12px;
            font-weight: 700;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            opacity: 0.9;
            margin-bottom: 6px;
        }
        .app-download-title {
            margin: 0 0 6px;
            color: #fff;
            font-weight: 800;
            font-size: 1.25rem;
        }
        .app-download-text {
            margin: 0;
            color: rgba(255, 255, 255, 0.92);
            max-width: 420px;
            font-size: 0.95rem;
            line-height: 1.45;
        }
        .app-download-badges {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
        }
        .app-store-badge {
            display: inline-flex;
            align-items: center;
            gap: 12px;
            min-width: 168px;
            padding: 10px 16px;
            border-radius: 14px;
            background: #111;
            color: #fff !important;
            text-decoration: none !important;
            transition: transform 0.2s ease, box-shadow 0.2s ease;
            box-shadow: 0 8px 18px rgba(0, 0, 0, 0.22);
        }
        .app-store-badge:hover {
            transform: translateY(-2px);
            color: #fff !important;
            box-shadow: 0 12px 22px rgba(0, 0, 0, 0.28);
        }
        .app-store-badge__icon {
            display: inline-flex;
            line-height: 0;
        }
        .app-store-badge__text {
            display: flex;
            flex-direction: column;
            line-height: 1.15;
        }
        .app-store-badge__text small {
            font-size: 11px;
            opacity: 0.85;
        }
        .app-store-badge__text strong {
            font-size: 16px;
            font-weight: 700;
        }
        .app-store-badge--android {
            background: #1f1f1f;
        }
        .app-store-badge--ios {
            background: #000;
        }

        .whatsapp-float {
            position: fixed;
            width: 56px;
            height: 56px;
            bottom: calc(24px + env(safe-area-inset-bottom, 0px));
            left: calc(20px + env(safe-area-inset-left, 0px));
            background-color: #25D366;
            border-radius: 50%;
            z-index: 9998;
            display: flex;
            justify-content: center;
            align-items: center;
            text-decoration: none;
            transition: transform 0.2s ease;
            animation: whatsapp-bounce 2s ease-in-out infinite, whatsapp-glow 2s ease-in-out infinite;
        }
        .whatsapp-float:hover {
            animation: whatsapp-bounce 2s ease-in-out infinite, whatsapp-glow 0.8s ease-in-out infinite;
        }
        .whatsapp-float svg {
            width: 30px;
            height: 30px;
            fill: #fff;
        }
        @keyframes whatsapp-bounce {
            0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
            40% { transform: translateY(-10px); }
            60% { transform: translateY(-5px); }
        }
        @keyframes whatsapp-glow {
            0%, 100% {
                box-shadow: 0 4px 12px rgba(0,0,0,0.2), 0 0 0 0 rgba(37, 211, 102, 0.6), 0 0 20px rgba(37, 211, 102, 0.3);
            }
            50% {
                box-shadow: 0 4px 16px rgba(0,0,0,0.25), 0 0 0 15px rgba(37, 211, 102, 0), 0 0 35px rgba(37, 211, 102, 0.5);
            }
        }

        @media (max-width: 767.98px) {
            .app-download-card {
                padding: 18px;
            }
            .app-store-badge {
                width: 100%;
                justify-content: center;
            }
        }
    </style>

    <a href="https://wa.me/2349039875741?text=Hi%20JollyBoxfr,%20I%20Got%20This%20Number%20from%20site"
       class="whatsapp-float"
       target="_blank"
       rel="noopener noreferrer"
       aria-label="@lang('Chat on WhatsApp')">
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
        </svg>
    </a>
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
