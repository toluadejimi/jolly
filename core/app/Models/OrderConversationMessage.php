<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderConversationMessage extends Model
{
    protected $guarded = ['id'];

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(OrderConversation::class, 'order_conversation_id');
    }

    public function isFromUser(): bool
    {
        return $this->sender_type === 'user';
    }

    public function isFromAdmin(): bool
    {
        return $this->sender_type === 'admin';
    }
}
