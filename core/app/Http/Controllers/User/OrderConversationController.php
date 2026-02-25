<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderConversation;
use App\Models\OrderConversationMessage;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;

class OrderConversationController extends Controller
{
    public function index()
    {
        $pageTitle = 'Contact Seller';
        $conversations = OrderConversation::where('user_id', auth()->id())
            ->with(['order', 'messages' => fn ($q) => $q->latest('id')->limit(1)])
            ->latest('updated_at')
            ->paginate(getPaginate(15));
        return view('Template::user.orders.conversations_index', compact('pageTitle', 'conversations'));
    }

    public function show($orderNumber)
    {
        $order = Order::where('order_number', $orderNumber)
            ->where('user_id', auth()->id())
            ->firstOrFail();
        $conversation = OrderConversation::firstOrCreate(
            ['order_id' => $order->id, 'user_id' => auth()->id()],
            []
        );
        $conversation->update(['user_read_at' => now()]);
        $messages = $conversation->messages()->oldest('id')->get();
        $pageTitle = 'Contact Seller - #' . $order->order_number;
        return view('Template::user.orders.conversation_show', compact('pageTitle', 'order', 'conversation', 'messages'));
    }

    public function store(Request $request, $orderNumber)
    {
        $order = Order::where('order_number', $orderNumber)
            ->where('user_id', auth()->id())
            ->firstOrFail();
        $conversation = OrderConversation::firstOrCreate(
            ['order_id' => $order->id, 'user_id' => auth()->id()],
            []
        );

        $request->validate([
            'message' => 'nullable|string|max:5000',
            'attachment' => 'nullable|file|max:10240|mimes:jpg,jpeg,png,gif,webp,pdf,doc,docx,xls,xlsx,txt,zip',
        ], [
            'attachment.max' => 'File must not exceed 10MB.',
            'attachment.mimes' => 'Allowed: images, PDF, Word, Excel, text, ZIP.',
        ]);

        $message = trim($request->message ?? '');
        $attachmentPath = null;
        $attachmentName = null;

        if ($request->hasFile('attachment')) {
            $file = $request->file('attachment');
            $path = getFilePath('orderConversation');
            $name = fileUploader($file, $path, null, null, null, 'conv_' . time() . '_' . uniqid());
            $attachmentPath = $path . '/' . $name;
            $attachmentName = $file->getClientOriginalName();
        }

        if ($message === '' && !$attachmentPath) {
            return back()->withErrors(['message' => __('Write a message or attach a file.')]);
        }

        OrderConversationMessage::create([
            'order_conversation_id' => $conversation->id,
            'sender_type' => 'user',
            'sender_id' => auth()->id(),
            'message' => $message ?: null,
            'attachment_path' => $attachmentPath,
            'attachment_name' => $attachmentName,
        ]);
        $conversation->touch();

        $preview = $message ? Str::limit($message, 150) : ($attachmentName ? __('Attachment') . ': ' . $attachmentName : __('New message'));
        sendTelegramToAdmin(
            "💬 Contact Seller – new message\n\n"
            . "Order: #" . $order->order_number . "\n"
            . "From: " . (auth()->user()->username ?? auth()->user()->email) . "\n"
            . "Message: " . $preview
        );

        $notify[] = ['success', __('Message sent.')];
        return back()->withNotify($notify);
    }

    public function downloadAttachment($messageId)
    {
        $message = OrderConversationMessage::whereHas('conversation', function ($q) {
            $q->where('user_id', auth()->id());
        })->findOrFail($messageId);
        if (!$message->attachment_path || !$message->attachment_name) {
            abort(404);
        }
        $fullPath = public_path($message->attachment_path);
        if (!file_exists($fullPath) || !is_file($fullPath)) {
            abort(404);
        }
        return response()->download($fullPath, $message->attachment_name);
    }
}
