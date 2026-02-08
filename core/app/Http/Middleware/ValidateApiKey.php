<?php

namespace App\Http\Middleware;

use App\Models\ApiKey;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ValidateApiKey
{
    public function handle(Request $request, Closure $next): Response
    {
        $key = $request->header('X-API-Key')
            ?? $request->header('Authorization');

        if ($key && str_starts_with($key, 'Bearer ')) {
            $key = substr($key, 7);
        }

        if (empty($key)) {
            return response()->json([
                'remark' => 'unauthorized',
                'status' => 'error',
                'message' => ['error' => ['API key is required. Send it in X-API-Key header or Authorization: Bearer <key>.']],
            ], 401);
        }

        $hash = ApiKey::hashKey($key);
        $apiKey = ApiKey::where('key', $hash)->with('user')->first();

        if (!$apiKey) {
            return response()->json([
                'remark' => 'unauthorized',
                'status' => 'error',
                'message' => ['error' => ['Invalid or revoked API key.']],
            ], 401);
        }

        $user = $apiKey->user;
        if (!$user || $user->status != 1) {
            return response()->json([
                'remark' => 'forbidden',
                'status' => 'error',
                'message' => ['error' => ['Account is inactive or suspended.']],
            ], 403);
        }

        $apiKey->touchLastUsed();
        $request->setUserResolver(fn () => $user);
        $request->attributes->set('api_key', $apiKey);

        return $next($request);
    }
}
