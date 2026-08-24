import '../models/api_response.dart';
import '../models/order_tracking.dart';
import '../models/product.dart';
import 'api_service.dart';

enum AssistantIntent { order, track, support, greeting, help, unknown }

enum AssistantActionType {
  openProducts,
  openProduct,
  openTrack,
  openSupportChat,
  openLogin,
  openCart,
  none,
}

class AssistantAction {
  const AssistantAction({
    required this.type,
    this.label,
    this.productId,
    this.orderNumber,
    this.categoryId,
  });

  final AssistantActionType type;
  final String? label;
  final int? productId;
  final String? orderNumber;
  final int? categoryId;
}

class AssistantReply {
  const AssistantReply({
    required this.text,
    this.actions = const [],
    this.intent = AssistantIntent.unknown,
  });

  final String text;
  final List<AssistantAction> actions;
  final AssistantIntent intent;
}

class AssistantMessage {
  AssistantMessage({
    required this.text,
    required this.isUser,
    this.actions = const [],
    DateTime? at,
  }) : at = at ?? DateTime.now();

  final String text;
  final bool isUser;
  final List<AssistantAction> actions;
  final DateTime at;
}

/// Lightweight on-device assistant that helps with ordering, tracking, and support.
class AssistantService {
  AssistantService(this._api);

  final ApiService _api;

  static final RegExp _orderNumberPattern = RegExp(
    r'\b((?:OID|JOLFR)[-_]?\d{3,}|[A-Z]{2,}\d{4,})\b',
    caseSensitive: false,
  );

  AssistantIntent detectIntent(String raw) {
    final text = raw.toLowerCase().trim();
    if (text.isEmpty) return AssistantIntent.unknown;

    if (_looksLikeGreeting(text)) return AssistantIntent.greeting;
    if (_containsAny(text, [
      'track',
      'tracking',
      'where is my order',
      'delivery status',
      'order status',
      'shipped',
      'dispatch',
      'oid-',
      'jolfr',
    ])) {
      return AssistantIntent.track;
    }
    if (_containsAny(text, [
      'support',
      'help me',
      'contact',
      'seller',
      'agent',
      'human',
      'complaint',
      'issue',
      'problem',
      'refund',
      'chat',
    ])) {
      return AssistantIntent.support;
    }
    if (_containsAny(text, [
      'order',
      'buy',
      'purchase',
      'gift',
      'shop',
      'product',
      'cart',
      'checkout',
      'recommend',
      'suggest',
      'find',
      'looking for',
      'want',
    ])) {
      return AssistantIntent.order;
    }
    if (_containsAny(text, ['help', 'what can you', 'assist'])) {
      return AssistantIntent.help;
    }
    return AssistantIntent.unknown;
  }

  String? extractOrderNumber(String text) {
    final match = _orderNumberPattern.firstMatch(text);
    if (match == null) return null;
    return match.group(1)?.toUpperCase();
  }

  Future<AssistantReply> reply({
    required String userText,
    required bool isLoggedIn,
  }) async {
    final intent = detectIntent(userText);
    final orderNumber = extractOrderNumber(userText);

    switch (intent) {
      case AssistantIntent.greeting:
        return const AssistantReply(
          text:
              'Hi! I’m Jolly Assistant. I can help you order gifts, track a delivery, or contact support.',
          intent: AssistantIntent.greeting,
          actions: [
            AssistantAction(
              type: AssistantActionType.openProducts,
              label: 'Browse gifts',
            ),
            AssistantAction(
              type: AssistantActionType.openTrack,
              label: 'Track order',
            ),
            AssistantAction(
              type: AssistantActionType.openSupportChat,
              label: 'Contact support',
            ),
          ],
        );

      case AssistantIntent.help:
        return const AssistantReply(
          text:
              'Here’s what I can do:\n• Order — find gifts and start shopping\n• Track — check delivery with your order number\n• Support — open chat with our team',
          intent: AssistantIntent.help,
          actions: [
            AssistantAction(
              type: AssistantActionType.openProducts,
              label: 'Start shopping',
            ),
            AssistantAction(
              type: AssistantActionType.openTrack,
              label: 'Track an order',
            ),
            AssistantAction(
              type: AssistantActionType.openSupportChat,
              label: 'Talk to support',
            ),
          ],
        );

      case AssistantIntent.track:
        if (orderNumber != null) {
          final tracking = await _api.getOrderTracking(orderNumber);
          return _trackingReply(orderNumber, tracking);
        }
        return const AssistantReply(
          text:
              'I can check your delivery. Share your order number (for example OID-01234), or open the tracker.',
          intent: AssistantIntent.track,
          actions: [
            AssistantAction(
              type: AssistantActionType.openTrack,
              label: 'Open order tracker',
            ),
          ],
        );

      case AssistantIntent.support:
        if (isLoggedIn) {
          return const AssistantReply(
            text:
                'I can connect you with support. Open your order chats to message our team, or track an order first if you need status help.',
            intent: AssistantIntent.support,
            actions: [
              AssistantAction(
                type: AssistantActionType.openSupportChat,
                label: 'Open support chat',
              ),
              AssistantAction(
                type: AssistantActionType.openTrack,
                label: 'Track order',
              ),
            ],
          );
        }
        return const AssistantReply(
          text:
              'To message support about an order, please sign in. You can also track a delivery with your order number without logging in.',
          intent: AssistantIntent.support,
          actions: [
            AssistantAction(
              type: AssistantActionType.openLogin,
              label: 'Sign in',
            ),
            AssistantAction(
              type: AssistantActionType.openTrack,
              label: 'Track order',
            ),
          ],
        );

      case AssistantIntent.order:
        final query = _shoppingQuery(userText);
        if (query != null && query.length >= 2) {
          final products = await _searchProducts(query);
          if (products.isNotEmpty) {
            return AssistantReply(
              text:
                  'I found gifts related to “$query”. Tap one to view it, or browse the full catalog.',
              intent: AssistantIntent.order,
              actions: [
                ...products.take(4).map(
                      (p) => AssistantAction(
                        type: AssistantActionType.openProduct,
                        label: p.name,
                        productId: p.id,
                      ),
                    ),
                const AssistantAction(
                  type: AssistantActionType.openProducts,
                  label: 'See all gifts',
                ),
                const AssistantAction(
                  type: AssistantActionType.openCart,
                  label: 'Go to cart',
                ),
              ],
            );
          }
        }
        return const AssistantReply(
          text:
              'Let’s find the perfect gift. Browse products, or tell me what you’re looking for (for example “chocolate” or “watch”).',
          intent: AssistantIntent.order,
          actions: [
            AssistantAction(
              type: AssistantActionType.openProducts,
              label: 'Browse gifts',
            ),
            AssistantAction(
              type: AssistantActionType.openCart,
              label: 'View cart',
            ),
          ],
        );

      case AssistantIntent.unknown:
        if (orderNumber != null) {
          final tracking = await _api.getOrderTracking(orderNumber);
          return _trackingReply(orderNumber, tracking);
        }
        return const AssistantReply(
          text:
              'I can help with ordering, tracking, or contacting support. What would you like to do?',
          intent: AssistantIntent.unknown,
          actions: [
            AssistantAction(
              type: AssistantActionType.openProducts,
              label: 'Order a gift',
            ),
            AssistantAction(
              type: AssistantActionType.openTrack,
              label: 'Track order',
            ),
            AssistantAction(
              type: AssistantActionType.openSupportChat,
              label: 'Contact support',
            ),
          ],
        );
    }
  }

  AssistantReply _trackingReply(String orderNumber, OrderTrackingResult result) {
    if (!result.success) {
      return AssistantReply(
        text:
            'I couldn’t find order $orderNumber${result.error != null ? ': ${result.error}' : '.'} Double-check the number, or open the tracker to try again.',
        intent: AssistantIntent.track,
        actions: [
          AssistantAction(
            type: AssistantActionType.openTrack,
            label: 'Open tracker',
            orderNumber: orderNumber,
          ),
          const AssistantAction(
            type: AssistantActionType.openSupportChat,
            label: 'Contact support',
          ),
        ],
      );
    }

    final status = _statusLabel(result.status);
    final buffer = StringBuffer('Here’s the latest for $orderNumber:\n• Status: $status');
    if (result.estimatedDeliveryAt != null &&
        result.estimatedDeliveryAt!.trim().isNotEmpty) {
      buffer.writeln('\n• Estimated delivery: ${result.estimatedDeliveryAt}');
    }
    if (result.trackingNumber != null &&
        result.trackingNumber!.trim().isNotEmpty) {
      buffer.writeln('\n• Tracking number: ${result.trackingNumber}');
    }
    buffer.write('\n\nI can open the full tracker if you need more detail.');

    return AssistantReply(
      text: buffer.toString(),
      intent: AssistantIntent.track,
      actions: [
        AssistantAction(
          type: AssistantActionType.openTrack,
          label: 'Open full tracker',
          orderNumber: orderNumber,
        ),
        const AssistantAction(
          type: AssistantActionType.openSupportChat,
          label: 'Contact support',
        ),
      ],
    );
  }

  String _statusLabel(int? status) {
    switch (status) {
      case orderStatusPending:
        return 'Pending';
      case orderStatusProcessing:
        return 'Processing';
      case orderStatusDispatched:
        return 'Dispatched';
      case orderStatusDelivered:
        return 'Delivered';
      case orderStatusCanceled:
        return 'Canceled';
      case orderStatusReturned:
        return 'Returned';
      default:
        return 'In progress';
    }
  }

  Future<List<ProductItem>> _searchProducts(String query) async {
    final ApiResponse<ProductListData> res =
        await _api.getProducts(page: 1, perPage: 40);
    if (!res.success || res.data == null) return [];
    final q = query.toLowerCase();
    return res.data!.products
        .where((p) => p.name.toLowerCase().contains(q))
        .take(6)
        .toList();
  }

  String? _shoppingQuery(String raw) {
    var text = raw.toLowerCase();
    for (final stop in [
      'i want to',
      'i want',
      'i need',
      'looking for',
      'search for',
      'find me',
      'find',
      'buy me',
      'buy',
      'order',
      'purchase',
      'gift',
      'please',
      'a ',
      'an ',
      'the ',
      'some ',
    ]) {
      text = text.replaceAll(stop, ' ');
    }
    text = text.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty || text.length < 2) return null;
    return text;
  }

  bool _looksLikeGreeting(String text) {
    final t = text.trim().toLowerCase();
    return RegExp(
      r'^(hi|hello|hey|good morning|good afternoon|good evening)\b',
    ).hasMatch(t);
  }

  bool _containsAny(String text, List<String> needles) {
    for (final n in needles) {
      if (text.contains(n)) return true;
    }
    return false;
  }
}
