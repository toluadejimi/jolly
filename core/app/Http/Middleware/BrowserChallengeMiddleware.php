<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Crypt;
use Symfony\Component\HttpFoundation\Response;

class BrowserChallengeMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        if (! $this->isEnabled()) {
            return $next($request);
        }

        if ($this->shouldSkip($request)) {
            return $next($request);
        }

        if ($this->passesCookie($request)) {
            return $next($request);
        }

        // Bots often POST/scan without a cookie — reject without loading the shop
        if (! $request->isMethod('GET') && ! $request->isMethod('HEAD')) {
            abort(403);
        }

        $request->session()->put([
            'browser_challenge_nonce' => bin2hex(random_bytes(32)),
            'browser_challenge_issued_at' => now()->timestamp,
            'browser_challenge_intended' => $request->fullUrl(),
        ]);

        return response()->view('browser_challenge', [
            'siteName' => config('app.name', 'Jollybox'),
            'turnstileSiteKey' => config('services.turnstile.site_key'),
            'nonce' => $request->session()->get('browser_challenge_nonce'),
        ]);
    }

    private function isEnabled(): bool
    {
        if (! filter_var(config('services.turnstile.challenge_enabled', true), FILTER_VALIDATE_BOOLEAN)) {
            return false;
        }

        $siteKey = config('services.turnstile.site_key');
        $secret = config('services.turnstile.secret_key');

        return is_string($siteKey) && $siteKey !== '' && is_string($secret) && $secret !== '';
    }

    private function shouldSkip(Request $request): bool
    {
        if ($request->routeIs('browser.challenge.verify')) {
            return true;
        }

        return $request->is(
            'admin',
            'admin/*',
            'api',
            'api/*',
            'ipn',
            'ipn/*',
            'browser-challenge/*',
            'storage/*',
            'logger',
            'up',
            'clear',
            'placeholder-image/*',
        );
    }

    private function passesCookie(Request $request): bool
    {
        $raw = $request->cookie('jolly_bv');
        if (! is_string($raw) || $raw === '') {
            return false;
        }

        try {
            $payload = json_decode(Crypt::decryptString($raw), true, 512, JSON_THROW_ON_ERROR);

            return isset($payload['e']) && (int) $payload['e'] > now()->timestamp;
        } catch (\Throwable) {
            return false;
        }
    }
}
