@php
    $iosAppUrl = 'https://apps.apple.com/us/app/jollyboxfr/id6759364001';
    $androidAppUrl = route('app.download.android');
@endphp

<div class="site-section app-download-home py-4">
    <div class="container">
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
</div>

<style>
    .app-download-home .app-download-card {
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
    .app-download-home .app-download-eyebrow {
        display: inline-block;
        font-size: 12px;
        font-weight: 700;
        letter-spacing: 0.06em;
        text-transform: uppercase;
        opacity: 0.9;
        margin-bottom: 6px;
    }
    .app-download-home .app-download-title {
        margin: 0 0 6px;
        color: #fff;
        font-weight: 800;
        font-size: 1.25rem;
    }
    .app-download-home .app-download-text {
        margin: 0;
        color: rgba(255, 255, 255, 0.92);
        max-width: 420px;
        font-size: 0.95rem;
        line-height: 1.45;
    }
    .app-download-home .app-download-badges {
        display: flex;
        flex-wrap: wrap;
        gap: 12px;
    }
    .app-download-home .app-store-badge {
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
    .app-download-home .app-store-badge:hover {
        transform: translateY(-2px);
        color: #fff !important;
        box-shadow: 0 12px 22px rgba(0, 0, 0, 0.28);
    }
    .app-download-home .app-store-badge__icon {
        display: inline-flex;
        line-height: 0;
    }
    .app-download-home .app-store-badge__text {
        display: flex;
        flex-direction: column;
        line-height: 1.15;
    }
    .app-download-home .app-store-badge__text small {
        font-size: 11px;
        opacity: 0.85;
    }
    .app-download-home .app-store-badge__text strong {
        font-size: 16px;
        font-weight: 700;
    }
    .app-download-home .app-store-badge--android { background: #1f1f1f; }
    .app-download-home .app-store-badge--ios { background: #000; }
    @media (max-width: 767.98px) {
        .app-download-home .app-download-card { padding: 18px; }
        .app-download-home .app-store-badge { width: 100%; justify-content: center; }
    }
</style>
