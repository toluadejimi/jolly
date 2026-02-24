<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class OrderConversation extends Model
{
    protected $guarded = ['id'];

    protected $casts = [
        'admin_read_at' => 'datetime',
        'user_read_at' => 'datetime',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function messages(): HasMany
    {
        return $this->hasMany(OrderConversationMessage::class, 'order_conversation_id')->latest('id');
    }

    public function unreadCountForUser(): int
    {
        $lastRead = $this->user_read_at;
        if (!$lastRead) {
            return $this->messages()->where('sender_type', 'admin')->count();
        }
        return $this->messages()->where('sender_type', 'admin')->where('created_at', '>', $lastRead)->count();
    }

    public function unreadCountForAdmin(): int
    {
        $lastRead = $this->admin_read_at;
        if (!$lastRead) {
            return $this->messages()->where('sender_type', 'user')->count();
        }
        return $this->messages()->where('sender_type', 'user')->where('created_at', '>', $lastRead)->count();
    }
}
