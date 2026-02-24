<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_conversations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('orders')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->timestamp('admin_read_at')->nullable();
            $table->timestamp('user_read_at')->nullable();
            $table->timestamps();
            $table->unique(['order_id', 'user_id']);
        });

        Schema::create('order_conversation_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_conversation_id')->constrained('order_conversations')->cascadeOnDelete();
            $table->string('sender_type', 20); // 'user' | 'admin'
            $table->unsignedBigInteger('sender_id')->nullable(); // user_id or admin_id
            $table->text('message')->nullable();
            $table->string('attachment_path', 500)->nullable();
            $table->string('attachment_name', 255)->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_conversation_messages');
        Schema::dropIfExists('order_conversations');
    }
};
