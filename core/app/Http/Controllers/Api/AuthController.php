<?php

namespace App\Http\Controllers\Api;

use App\Constants\Status;
use App\Http\Controllers\Controller;
use App\Models\ApiKey;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;
use Illuminate\Support\Facades\Validator;

/**
 * Login and register matching web User\Auth flow.
 * Returns an API key so the app can authenticate subsequent requests.
 */
class AuthController extends Controller
{
    /**
     * POST /api/login
     * Body: username (email or username), password
     * Returns: api_key (plain), user (id, email, firstname, lastname)
     */
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        $login = $request->input('username');
        $fieldType = filter_var($login, FILTER_VALIDATE_EMAIL) ? 'email' : 'username';
        $credentials = [
            $fieldType => $login,
            'password' => $request->password,
        ];

        if (!Auth::attempt($credentials)) {
            return response()->json([
                'remark' => 'invalid_credentials',
                'status' => 'error',
                'message' => ['error' => ['Invalid login details.']],
            ], 422);
        }

        $user = Auth::user();
        if ($user->status != Status::USER_ACTIVE) {
            Auth::logout();
            return response()->json([
                'remark' => 'account_inactive',
                'status' => 'error',
                'message' => ['error' => ['Account is inactive or suspended.']],
            ], 403);
        }

        $apiKey = $this->getOrCreateApiKey($user);
        if (!$apiKey) {
            return response()->json([
                'remark' => 'api_key_error',
                'status' => 'error',
                'message' => ['error' => ['Could not create API key.']],
            ], 500);
        }

        return response()->json([
            'remark' => 'login_success',
            'status' => 'success',
            'message' => ['success' => ['Login successful.']],
            'data' => [
                'api_key' => $apiKey,
                'user' => [
                    'id' => $user->id,
                    'email' => $user->email,
                    'firstname' => $user->firstname ?? '',
                    'lastname' => $user->lastname ?? '',
                ],
            ],
        ]);
    }

    /**
     * POST /api/register
     * Body: firstname, lastname, email, password, password_confirmation
     * Returns: api_key (plain), user (id, email, firstname, lastname)
     */
    public function register(Request $request): JsonResponse
    {
        if (!gs('registration')) {
            return response()->json([
                'remark' => 'registration_disabled',
                'status' => 'error',
                'message' => ['error' => ['Registration is not allowed.']],
            ], 403);
        }

        $passwordRule = Password::min(6);
        if (gs('secure_password')) {
            $passwordRule = $passwordRule->mixedCase()->numbers()->symbols();
        }

        $request->validate([
            'firstname' => 'nullable|string|max:40',
            'lastname'  => 'nullable|string|max:40',
            'email'     => 'required|string|email|unique:users',
            'password'  => ['required', 'confirmed', $passwordRule],
        ], [
            'email.unique' => 'This email is already registered.',
        ]);

        $user = new User();
        $user->email     = strtolower($request->email);
        $user->firstname = $request->firstname ?? '';
        $user->lastname  = $request->lastname ?? '';
        $user->password  = Hash::make($request->password);
        $user->ev = gs('ev') ? Status::NO : Status::YES;
        $user->sv = gs('sv') ? Status::NO : Status::YES;
        $user->status = Status::USER_ACTIVE;
        $user->save();

        $apiKey = $this->getOrCreateApiKey($user);
        if (!$apiKey) {
            return response()->json([
                'remark' => 'api_key_error',
                'status' => 'error',
                'message' => ['error' => ['Account created but could not create API key. Please log in.']],
            ], 500);
        }

        return response()->json([
            'remark' => 'register_success',
            'status' => 'success',
            'message' => ['success' => ['Registration successful.']],
            'data' => [
                'api_key' => $apiKey,
                'user' => [
                    'id' => $user->id,
                    'email' => $user->email,
                    'firstname' => $user->firstname ?? '',
                    'lastname' => $user->lastname ?? '',
                ],
            ],
        ], 201);
    }

    /**
     * POST /api/change-password (requires API key).
     * Body: current_password, password, password_confirmation
     */
    public function changePassword(Request $request): JsonResponse
    {
        $passwordRule = Password::min(6);
        if (gs('secure_password')) {
            $passwordRule = $passwordRule->mixedCase()->numbers()->symbols();
        }

        $request->validate([
            'current_password' => 'required|string',
            'password' => ['required', 'confirmed', $passwordRule],
        ]);

        $user = $request->user();
        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'remark' => 'invalid_password',
                'status' => 'error',
                'message' => ['error' => ['Current password is incorrect.']],
            ], 422);
        }

        $user->password = Hash::make($request->password);
        $user->save();

        return response()->json([
            'remark' => 'password_changed',
            'status' => 'success',
            'message' => ['success' => ['Password changed successfully.']],
        ]);
    }

    /**
     * POST /api/account/delete (requires API key).
     * Permanently deletes the authenticated user's account: revokes API keys and anonymizes user data.
     * Order history is retained for legal record; the account cannot be used again.
     */
    public function deleteAccount(Request $request): JsonResponse
    {
        $user = $request->user();

        $user->apiKeys()->delete();

        $user->email = 'deleted_' . $user->id . '_' . Str::random(8) . '@deleted.local';
        $user->firstname = '';
        $user->lastname = '';
        $user->password = Hash::make(Str::random(32));
        $user->status = Status::USER_BAN;
        $user->save();

        \App\Models\ShippingAddress::where('user_id', $user->id)->delete();

        return response()->json([
            'remark' => 'account_deleted',
            'status' => 'success',
            'message' => ['success' => ['Your account has been permanently deleted.']],
        ]);
    }

    private function getOrCreateApiKey(User $user): ?string
    {
        $plain = ApiKey::generateKey();
        $user->apiKeys()->create([
            'name' => 'Mobile app ' . now()->format('Y-m-d H:i'),
            'key' => ApiKey::hashKey($plain),
            'key_prefix' => ApiKey::prefixForKey($plain),
        ]);
        return $plain;
    }
}
