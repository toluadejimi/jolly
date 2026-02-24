/// Summary of conversation for an order (in order list/detail response).
class OrderConversationSummary {
  OrderConversationSummary({
    required this.conversationId,
    required this.unreadCount,
  });

  factory OrderConversationSummary.fromJson(Map<String, dynamic> json) {
    return OrderConversationSummary(
      conversationId: (json['conversation_id'] as num).toInt(),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  final int conversationId;
  final int unreadCount;
}

/// Dashboard data from GET /api/dashboard (order counts + latest orders).
class DashboardData {
  DashboardData({
    required this.orderCounts,
    required this.latestOrders,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final counts = json['order_counts'] as Map<String, dynamic>? ?? {};
    final list = json['latest_orders'] as List<dynamic>? ?? [];
    return DashboardData(
      orderCounts: OrderCounts(
        total: (counts['total'] as num?)?.toInt() ?? 0,
        pending: (counts['pending'] as num?)?.toInt() ?? 0,
        processing: (counts['processing'] as num?)?.toInt() ?? 0,
        dispatched: (counts['dispatched'] as num?)?.toInt() ?? 0,
        delivered: (counts['delivered'] as num?)?.toInt() ?? 0,
        canceled: (counts['canceled'] as num?)?.toInt() ?? 0,
      ),
      latestOrders: list
          .map((e) => UserOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final OrderCounts orderCounts;
  final List<UserOrderItem> latestOrders;
}

class OrderCounts {
  OrderCounts({
    required this.total,
    required this.pending,
    required this.processing,
    required this.dispatched,
    required this.delivered,
    required this.canceled,
  });

  final int total;
  final int pending;
  final int processing;
  final int dispatched;
  final int delivered;
  final int canceled;
}

/// Order list item (dashboard latest + orders list).
class UserOrderItem {
  UserOrderItem({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.subtotal,
    this.shippingCharge,
    this.paymentStatus,
    this.conversation,
  });

  factory UserOrderItem.fromJson(Map<String, dynamic> json) {
    final conv = json['conversation'] as Map<String, dynamic>?;
    return UserOrderItem(
      id: (json['id'] as num).toInt(),
      orderNumber: json['order_number'] as String? ?? '',
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String? ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      shippingCharge: (json['shipping_charge'] as num?)?.toDouble(),
      paymentStatus: json['payment_status'] as String?,
      conversation: conv != null ? OrderConversationSummary.fromJson(conv) : null,
    );
  }

  final int id;
  final String orderNumber;
  final double totalAmount;
  final String status;
  final String createdAt;
  final double? subtotal;
  final double? shippingCharge;
  final String? paymentStatus;
  final OrderConversationSummary? conversation;

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'dispatched':
        return 'Dispatched';
      case 'delivered':
        return 'Delivered';
      case 'canceled':
        return 'Canceled';
      case 'returned':
        return 'Returned';
      default:
        return status;
    }
  }
}

/// Full order detail from GET /api/orders/{id}.
class UserOrderDetail {
  UserOrderDetail({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.items,
    this.shippingAddress,
    this.subtotal,
    this.shippingCharge,
    this.paymentStatus,
    this.estimatedDeliveryAt,
    this.trackingNumber,
    this.trackingUrl,
    this.conversation,
  });

  factory UserOrderDetail.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final conv = json['conversation'] as Map<String, dynamic>?;
    return UserOrderDetail(
      id: (json['id'] as num).toInt(),
      orderNumber: json['order_number'] as String? ?? '',
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String? ?? '',
      items: itemsList
          .map((e) => UserOrderDetailItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      shippingAddress: json['shipping_address'],
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      shippingCharge: (json['shipping_charge'] as num?)?.toDouble(),
      paymentStatus: json['payment_status'] as String?,
      estimatedDeliveryAt: json['estimated_delivery_at'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      trackingUrl: json['tracking_url'] as String?,
      conversation: conv != null ? OrderConversationSummary.fromJson(conv) : null,
    );
  }

  final int id;
  final String orderNumber;
  final double totalAmount;
  final String status;
  final String createdAt;
  final List<UserOrderDetailItem> items;
  final dynamic shippingAddress;
  final double? subtotal;
  final double? shippingCharge;
  final String? paymentStatus;
  final String? estimatedDeliveryAt;
  final String? trackingNumber;
  final String? trackingUrl;
  final OrderConversationSummary? conversation;

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'dispatched':
        return 'Dispatched';
      case 'delivered':
        return 'Delivered';
      case 'canceled':
        return 'Canceled';
      case 'returned':
        return 'Returned';
      default:
        return status;
    }
  }
}

class UserOrderDetailItem {
  UserOrderDetailItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.imageUrl,
  });

  factory UserOrderDetailItem.fromJson(Map<String, dynamic> json) {
    return UserOrderDetailItem(
      productId: (json['product_id'] as num).toInt(),
      productName: json['product_name'] as String? ?? '',
      quantity: (json['quantity'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
    );
  }

  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final double subtotal;
  final String? imageUrl;
}

/// Orders list response from GET /api/orders.
class OrdersListData {
  OrdersListData({
    required this.orders,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory OrdersListData.fromJson(Map<String, dynamic> json) {
    final list = json['orders'] as List<dynamic>? ?? [];
    final pag = json['pagination'] as Map<String, dynamic>? ?? {};
    return OrdersListData(
      orders: list
          .map((e) => UserOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (pag['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (pag['last_page'] as num?)?.toInt() ?? 1,
      total: (pag['total'] as num?)?.toInt() ?? 0,
    );
  }

  final List<UserOrderItem> orders;
  final int currentPage;
  final int lastPage;
  final int total;
}
