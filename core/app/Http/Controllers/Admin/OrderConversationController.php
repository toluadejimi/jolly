<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\OrderConversation;
use App\Models\OrderConversationMessage;
use Illuminate\Http\Request;

class OrderConversationController extends Controller
{
    public function index()
    {
        $pageTitle = 'Order Conversations (Contact Seller)';
        $conversations = OrderConversation::with(['order', 'user', 'messages' => fn ($q) => $q->latest('id')->limit(1)])
            ->latest('updated_at')
            ->paginate(getPaginate(20));
        return view('admin.order.conversations_index', compact('pageTitle', 'conversations'));
    }

    public function show($id)
    {
        $conversation = OrderConversation::with(['order', 'user'])->findOrFail($id);
        $conversation->update(['admin_read_at' => now()]);
        $messages = $conversation->messages()->oldest('id')->get();
        $pageTitle = 'Conversation - Order #' . $conversation->order->order_number;
        return view('admin.order.conversation_show', compact('pageTitle', 'conversation', 'messages'));
    }

    public function store(Request $request, $id)
    {
        $conversation = OrderConversation::findOrFail($id);

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
            'sender_type' => 'admin',
            'sender_id' => auth()->guard('admin')->id(),
            'message' => $message ?: null,
            'attachment_path' => $attachmentPath,
            'attachment_name' => $attachmentName,
        ]);
        $conversation->update(['user_read_at' => null]);
        $conversation->touch();

        $notify[] = ['success', __('Reply sent.')];
        return back()->withNotify($notify);
    }

    public function downloadAttachment($messageId)
    {
        $message = OrderConversationMessage::findOrFail($messageId);
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
