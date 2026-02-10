
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
