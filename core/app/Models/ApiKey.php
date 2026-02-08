<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class ApiKey extends Model
{
    protected $fillable = ['user_id', 'name', 'key', 'key_prefix'];

    protected $hidden = ['key'];

    protected $casts = [
        'last_used_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public static function generateKey(): string
    {
        return 'gk_' . Str::random(48);
    }

    public static function hashKey(string $key): string
    {
        return hash('sha256', $key);
    }

    public static function prefixForKey(string $key): string
    {
        return substr($key, 0, 12);
    }

    public function touchLastUsed(): void
    {
        $this->update(['last_used_at' => now()]);
    }
}
