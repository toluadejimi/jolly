<!doctype html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex,nofollow">
    <title>{{ __('Security check') }} — {{ $siteName }}</title>
    <style>
        :root {
            --bg: #e8eef5;
            --card: #fff;
            --text: #1a1a1a;
            --muted: #5c6c7d;
            --accent: #f48120;
            --line: #d9e0e8;
        }
        @media (prefers-color-scheme: dark) {
            :root {
                --bg: #1a1d23;
                --card: #252a32;
                --text: #f0f2f5;
                --muted: #9aa5b5;
                --line: #3a424d;
            }
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: system-ui, -apple-system, "Segoe UI", Roboto, Ubuntu, sans-serif;
            background: var(--bg);
            color: var(--text);
            padding: 1.5rem;
        }
        .shell {
            width: 100%;
            max-width: 28rem;
            background: var(--card);
            border-radius: 8px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.08);
            border: 1px solid var(--line);
            padding: 2rem 1.75rem;
            text-align: center;
        }
        h1 {
            font-size: 1.125rem;
            font-weight: 600;
            margin: 0 0 0.5rem;
            line-height: 1.35;
        }
        p.sub {
            margin: 0 0 1.5rem;
            font-size: 0.875rem;
            color: var(--muted);
            line-height: 1.5;
        }
        .spinner {
            width: 2.25rem;
            height: 2.25rem;
            margin: 0 auto 1.25rem;
            border: 3px solid var(--line);
            border-top-color: var(--accent);
            border-radius: 50%;
            animation: jolly-spin 0.75s linear infinite;
        }
        @keyframes jolly-spin {
            to { transform: rotate(360deg); }
        }
        .ray {
            font-size: 0.75rem;
            color: var(--muted);
            font-family: ui-monospace, monospace;
            margin-top: 1.5rem;
            padding-top: 1rem;
            border-top: 1px solid var(--line);
            word-break: break-all;
        }
        .err {
            color: #c62828;
            font-size: 0.8125rem;
            margin-bottom: 1rem;
        }
        .cf-wrap { min-height: 65px; display: flex; justify-content: center; align-items: center; }
    </style>
    @if(!empty($turnstileSiteKey))
        <script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
    @endif
</head>
<body>
    <div class="shell">
        <div class="spinner" id="jolly-spinner" aria-hidden="true"></div>
        <h1>{{ __('Checking your browser before accessing') }} {{ $siteName }}</h1>
        <p class="sub">{{ __('This is an automatic process. You will be redirected shortly.') }}</p>

        @if ($errors->has('challenge'))
            <p class="err">{{ $errors->first('challenge') }}</p>
        @endif

        <form id="jolly-verify-form" method="post" action="{{ route('browser.challenge.verify') }}">
            @csrf
            <input type="hidden" name="nonce" value="{{ $nonce }}">
            @if(!empty($turnstileSiteKey))
                <div class="cf-wrap">
                    <div class="cf-turnstile"
                         data-sitekey="{{ $turnstileSiteKey }}"
                         data-callback="jollyTurnstileOk"></div>
                </div>
            @endif
        </form>

        <p class="ray" title="Request reference">{{ __('Reference') }}: {{ bin2hex(random_bytes(8)) }}</p>
    </div>

    <script>
        (function () {
            var form = document.getElementById('jolly-verify-form');
            var spinner = document.getElementById('jolly-spinner');
            var useTurnstile = {{ !empty($turnstileSiteKey) ? 'true' : 'false' }};

            window.jollyTurnstileOk = function () {
                if (spinner) spinner.style.visibility = 'hidden';
                form.submit();
            };

            if (!useTurnstile) {
                setTimeout(function () {
                    if (spinner) spinner.style.visibility = 'hidden';
                    form.submit();
                }, 1300);
            }
        })();
    </script>
</body>
</html>
