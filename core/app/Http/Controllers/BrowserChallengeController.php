<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\Http;

class BrowserChallengeController extends Controller
{
    public function verify(Request $request)
    {
        $request->validate([
            'nonce' => 'required|string|size:64',
            'cf-turnstile-response' => 'nullable|string',
        ]);

        $sessionNonce = $request->session()->get('browser_challenge_nonce');
        if (! is_string($sessionNonce) || ! hash_equals($sessionNonce, $request->input('nonce'))) {
            abort(403);
        }

        $secret = config('services.turnstile.secret_key');
        if (is_string($secret) && $secret !== '') {
            $token = $request->input('cf-turnstile-response');
            if (! is_string($token) || $token === '') {
                return redirect()->route('home')->withErrors(['challenge' => __('Verification required.')]);
            }

            $response = Http::asForm()->timeout(10)->post(
                'https://challenges.cloudflare.com/turnstile/v0/siteverify',
                [
                    'secret' => $secret,
                    'response' => $token,
                    'remoteip' => $request->ip(),
                ]
            );

            if (! $response->successful() || ! ($response->json('success') ?? false)) {
                return redirect()->route('home')->withErrors(['challenge' => __('Verification failed. Please try again.')]);
            }
        } else {
            $issued = $request->session()->get('browser_challenge_issued_at');
            if (! is_int($issued) && ! is_numeric($issued)) {
                abort(403);
            }
            if (now()->timestamp - (int) $issued < 1) {
                abort(403);
            }
        }

        $request->session()->forget(['browser_challenge_nonce', 'browser_challenge_issued_at']);

        $payload = Crypt::encryptString(json_encode(['e' => now()->addDays(30)->timestamp], JSON_THROW_ON_ERROR));

        return redirect()
            ->route('home')
            ->withCookie(cookie(
                'jolly_bv',
                $payload,
                60 * 24 * 30,
                '/',
                null,
                (bool) config('session.secure'),
                true,
                false,
                config('session.same_site') ?: 'lax'
            ));
    }
}
