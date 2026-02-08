<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use App\Models\ApiKey;
use Illuminate\Http\Request;

class ApiKeyController extends Controller
{
    public function index()
    {
        $pageTitle = 'API Keys';
        $keys = auth()->user()->apiKeys()->orderByDesc('created_at')->get();
        return view('Template::user.api_keys', compact('pageTitle', 'keys'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'nullable|string|max:100',
        ]);

        $user = auth()->user();
        $plainKey = ApiKey::generateKey();
        $user->apiKeys()->create([
            'name' => $request->filled('name') ? $request->name : 'API Key ' . now()->format('Y-m-d H:i'),
            'key' => ApiKey::hashKey($plainKey),
            'key_prefix' => ApiKey::prefixForKey($plainKey),
        ]);

        $notify[] = ['success', 'API key created. Copy it now — it will not be shown again.'];
        return back()->with('new_key_plain', $plainKey)->withNotify($notify);
    }

    public function destroy($id)
    {
        $key = auth()->user()->apiKeys()->findOrFail($id);
        $key->delete();
        $notify[] = ['success', 'API key revoked.'];
        return back()->withNotify($notify);
    }
}
