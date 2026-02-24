<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderConversation;
use App\Models\OrderConversationMessage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OrderConversationController extends Controller
{
    /**
     * List order conversations for the authenticated user.
     * GET /api/order-conversations
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $conversations = OrderConversation::where('user_id', $user->id)
            ->with(['order', 'messages' => fn ($q) => $q->latest('id')->limit(1)])
            ->latest('updated_at')
            ->paginate(min((int) $request->get('per_page', 15), 50));

        $items = $conversations->getCollection()->map(function ($conv) {
            $order = $conv->order;
            $lastMsg = $conv->messages->first();
            return [
                'conversation_id' => $conv->id,
                'order_id' => $order->id,
                'order_number' => $order->order_number,
                'last_message' => $lastMsg ? [
                    'message' => $lastMsg->message,
                    'attachment_name' => $lastMsg->attachment_name,
                    'sender' => $lastMsg->sender_type,
                    'created_at' => $lastMsg->created_at->toIso8601String(),
                ] : null,
                'updated_at' => $conv->updated_at->toIso8601String(),
                'unread_count' => $conv->unreadCountForUser(),
            ];
        });

        return response()->json([
            'remark' => 'order_conversations_list',
            'status' => 'success',
            'message' => ['success' => ['Conversations retrieved.']],
            'data' => [
                'conversations' => $items,
                'pagination' => [
                    'current_page' => $conversations->currentPage(),
                    'last_page' => $conversations->lastPage(),
                    'per_page' => $conversations->perPage(),
                    'total' => $conversations->total(),
                ],
            ],
        ]);
    }

    /**
     * Get messages for one order's conversation.
     * GET /api/orders/{order_ref}/conversation
     * order_ref can be order id or order_number.
     */
    public function show(Request $request, $orderRef): JsonResponse
    {
        $user = $request->user();
        $order = Order::where('user_id', $user->id)
            ->where(fn ($q) => $q->where('id', $orderRef)->orWhere('order_number', $orderRef))
            ->firstOrFail();

        $conversation = OrderConversation::firstOrCreate(
            ['order_id' => $order->id, 'user_id' => $user->id],
            []
        );
        $conversation->update(['user_read_at' => now()]);
        $messages = $conversation->messages()->oldest('id')->get();

        $messageList = $messages->map(function ($msg) {
            $attachmentUrl = null;
            if ($msg->attachment_path && $msg->attachment_name) {
                $attachmentUrl = asset($msg->attachment_path);
            }
            return [
                'id' => $msg->id,
                'sender' => $msg->sender_type,
                'message' => $msg->message,
                'attachment_name' => $msg->attachment_name,
                'attachment_url' => $attachmentUrl,
                'created_at' => $msg->created_at->toIso8601String(),
            ];
        });

        return response()->json([
            'remark' => 'order_conversation',
            'status' => 'success',
            'message' => ['success' => ['Messages retrieved.']],
            'data' => [
                'conversation_id' => $conversation->id,
                'order_id' => $order->id,
                'order_number' => $order->order_number,
                'messages' => $messageList,
            ],
        ]);
    }

    /**
     * Send a message (and optional attachment) in an order conversation.
     * POST /api/orders/{order_ref}/conversation
     * Body: message (optional), attachment (optional file)
     */
    public function store(Request $request, $orderRef): JsonResponse
    {
        $user = $request->user();
        $order = Order::where('user_id', $user->id)
            ->where(fn ($q) => $q->where('id', $orderRef)->orWhere('order_number', $orderRef))
            ->firstOrFail();

        $conversation = OrderConversation::firstOrCreate(
            ['order_id' => $order->id, 'user_id' => $user->id],
            []
        );

        $request->validate([
            'message' => 'nullable|string|max:5000',
            'attachment' => 'nullable|file|max:10240|mimes:jpg,jpeg,png,gif,webp,pdf,doc,docx,xls,xlsx,txt,zip',
        ], [
            'attachment.max' => 'File must not exceed 10MB.',
            'attachment.mimes' => 'Allowed: images, PDF, Word, Excel, text, ZIP.',
        ]);

        $messageText = trim($request->message ?? '');
        $attachmentPath = null;
        $attachmentName = null;

        if ($request->hasFile('attachment')) {
            $file = $request->file('attachment');
            $path = getFilePath('orderConversation');
            $name = fileUploader($file, $path, null, null, null, 'conv_' . time() . '_' . uniqid());
            $attachmentPath = $path . '/' . $name;
            $attachmentName = $file->getClientOriginalName();
        }

        if ($messageText === '' && !$attachmentPath) {
            return response()->json([
                'remark' => 'validation_error',
                'status' => 'error',
                'message' => ['error' => ['Provide a message or an attachment.']],
            ], 422);
        }

        $msg = OrderConversationMessage::create([
            'order_conversation_id' => $conversation->id,
            'sender_type' => 'user',
            'sender_id' => $user->id,
            'message' => $messageText ?: null,
            'attachment_path' => $attachmentPath,
            'attachment_name' => $attachmentName,
        ]);
        $conversation->touch();

        $attachmentUrl = ($msg->attachment_path && $msg->attachment_name) ? asset($msg->attachment_path) : null;

        return response()->json([
            'remark' => 'message_sent',
            'status' => 'success',
            'message' => ['success' => ['Message sent.']],
            'data' => [
                'message' => [
                    'id' => $msg->id,
                    'sender' => 'user',
                    'message' => $msg->message,
                    'attachment_name' => $msg->attachment_name,
                    'attachment_url' => $attachmentUrl,
                    'created_at' => $msg->created_at->toIso8601String(),
                ],
            ],
        ], 201);
    }

    /**
     * Get attachment URL for a message (for display or download).
     * GET /api/order-conversations/attachment/{message_id}
     * Returns URL in response so the app can open or display it.
     */
    public function attachment(Request $request, int $messageId): JsonResponse
    {
        $user = $request->user();
        $message = OrderConversationMessage::whereHas('conversation', fn ($q) => $q->where('user_id', $user->id))
            ->findOrFail($messageId);

        if (!$message->attachment_path || !$message->attachment_name) {
            return response()->json([
                'remark' => 'not_found',
                'status' => 'error',
                'message' => ['error' => ['No attachment.']],
            ], 404);
        }

        $fullPath = public_path($message->attachment_path);
        if (!file_exists($fullPath) || !is_file($fullPath)) {
            return response()->json([
                'remark' => 'not_found',
                'status' => 'error',
                'message' => ['error' => ['File not found.']],
            ], 404);
        }

        return response()->json([
            'remark' => 'attachment_url',
            'status' => 'success',
            'message' => ['success' => ['Attachment URL.']],
            'data' => [
                'attachment_name' => $message->attachment_name,
                'attachment_url' => asset($message->attachment_path),
            ],
        ]);
    }
}
