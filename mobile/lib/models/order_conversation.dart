/// Order conversation list item from GET /api/order-conversations.
class OrderConversationItem {
  OrderConversationItem({
    required this.conversationId,
    required this.orderId,
    required this.orderNumber,
    this.lastMessage,
    required this.updatedAt,
    required this.unreadCount,
  });

  factory OrderConversationItem.fromJson(Map<String, dynamic> json) {
    final last = json['last_message'] as Map<String, dynamic>?;
    return OrderConversationItem(
      conversationId: (json['conversation_id'] as num).toInt(),
      orderId: (json['order_id'] as num).toInt(),
      orderNumber: json['order_number'] as String? ?? '',
      lastMessage: last != null ? LastMessagePreview.fromJson(last) : null,
      updatedAt: json['updated_at'] as String? ?? '',
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  final int conversationId;
  final int orderId;
  final String orderNumber;
  final LastMessagePreview? lastMessage;
  final String updatedAt;
  final int unreadCount;
}

class LastMessagePreview {
  LastMessagePreview({
    this.message,
    this.attachmentName,
    required this.sender,
    required this.createdAt,
  });

  factory LastMessagePreview.fromJson(Map<String, dynamic> json) {
    return LastMessagePreview(
      message: json['message'] as String?,
      attachmentName: json['attachment_name'] as String?,
      sender: json['sender'] as String? ?? 'user',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  final String? message;
  final String? attachmentName;
  final String sender;
  final String createdAt;
}

/// Single message in a conversation.
class ConversationMessage {
  ConversationMessage({
    required this.id,
    required this.sender,
    this.message,
    this.attachmentName,
    this.attachmentUrl,
    required this.createdAt,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: (json['id'] as num).toInt(),
      sender: json['sender'] as String? ?? 'user',
      message: json['message'] as String?,
      attachmentName: json['attachment_name'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  final int id;
  final String sender;
  final String? message;
  final String? attachmentName;
  final String? attachmentUrl;
  final String createdAt;

  bool get isFromUser => sender == 'user';
  bool get isFromAdmin => sender == 'admin';
}

/// Full conversation with messages from GET /api/orders/{order_ref}/conversation.
class OrderConversationData {
  OrderConversationData({
    required this.conversationId,
    required this.orderId,
    required this.orderNumber,
    required this.messages,
  });

  factory OrderConversationData.fromJson(Map<String, dynamic> json) {
    final list = json['messages'] as List<dynamic>? ?? [];
    return OrderConversationData(
      conversationId: (json['conversation_id'] as num).toInt(),
      orderId: (json['order_id'] as num).toInt(),
      orderNumber: json['order_number'] as String? ?? '',
      messages: list
          .map((e) => ConversationMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int conversationId;
  final int orderId;
  final String orderNumber;
  final List<ConversationMessage> messages;
}

/// Response from POST /api/orders/{order_ref}/conversation (single sent message).
class SendMessageResult {
  SendMessageResult({required this.message});

  factory SendMessageResult.fromJson(Map<String, dynamic> json) {
    final msg = json['message'] as Map<String, dynamic>?;
    if (msg == null) return SendMessageResult(message: ConversationMessage(id: 0, sender: 'user', createdAt: ''));
    return SendMessageResult(message: ConversationMessage.fromJson(msg));
  }

  final ConversationMessage message;
}

/// Paginated list from GET /api/order-conversations.
class OrderConversationsListData {
  OrderConversationsListData({
    required this.conversations,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory OrderConversationsListData.fromJson(Map<String, dynamic> json) {
    final list = json['conversations'] as List<dynamic>? ?? [];
    final pag = json['pagination'] as Map<String, dynamic>? ?? {};
    return OrderConversationsListData(
      conversations: list
          .map((e) => OrderConversationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (pag['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (pag['last_page'] as num?)?.toInt() ?? 1,
      total: (pag['total'] as num?)?.toInt() ?? 0,
    );
  }

  final List<OrderConversationItem> conversations;
  final int currentPage;
  final int lastPage;
  final int total;
}
