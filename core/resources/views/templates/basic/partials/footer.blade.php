    <style>
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
