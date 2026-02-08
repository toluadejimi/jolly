@php
    $footer = getContent('footer.content', true);
    $footer = @$footer->data_values;
    $socials = getContent('social_icon.element', orderById: true);
    $menus = \App\Models\Frontend::where('data_keys', 'footer_menu.content')->first()->data_values;

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
        /* WhatsApp Floating Button */
        .whatsapp-float {
            position: fixed;
            width: 65px;
            height: 65px;
            bottom: 80px;
            left: 20px;
            background-color: #25D366;
            border-radius: 50%;
            text-align: center;
            box-shadow: 0px 4px 12px rgba(0,0,0,0.3);
            z-index: 999999;
            display: flex;
            justify-content: center;
            align-items: center;
            animation: bounce 2s infinite, pulse 2s infinite;
        }

        /* Icon size */
        .whatsapp-float img {
            width: 35px;
            height: 35px;
        }

        /* Bounce Animation */
        @keyframes bounce {
            0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
            40% { transform: translateY(-10px); }
            60% { transform: translateY(-5px); }
        }

        /* Pulse Animation */
        @keyframes pulse {
            0% { box-shadow: 0 0 0 0 rgba(37,211,102, 0.7); }
            70% { box-shadow: 0 0 0 20px rgba(37,211,102, 0); }
            100% { box-shadow: 0 0 0 0 rgba(37,211,102, 0); }
        }

        /* Show only on mobile */
        @media (min-width: 769px) {
            .whatsapp-float {
                display: none !important;
            }
        }

    </style>


    <a href="https://wa.me/2349039875741?text=Hi%20JollyBoxfr,%20I%20Got%20This%20Number%20from%20site"
       class="whatsapp-float"
       target="_blank">
        <img src="https://upload.wikimedia.org/wikipedia/commons/6/6b/WhatsApp.svg" alt="WhatsApp" />
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
