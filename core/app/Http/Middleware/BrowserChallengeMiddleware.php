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
        if ($this->passesCookie($request)) {
            return $next($request);
        }

        $request->session()->put([
            'browser_challenge_nonce' => bin2hex(random_bytes(32)),
            'browser_challenge_issued_at' => now()->timestamp,
        ]);

        return response()->view('browser_challenge', [
            'siteName' => config('app.name'),
            'turnstileSiteKey' => config('services.turnstile.site_key'),
            'nonce' => $request->session()->get('browser_challenge_nonce'),
        ]);
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
