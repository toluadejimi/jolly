import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/api_response.dart';
import '../models/order_conversation.dart';
import '../services/api_service.dart';
import 'order_conversation_screen.dart';

class OrderConversationsListScreen extends StatefulWidget {
  const OrderConversationsListScreen({super.key});

  @override
  State<OrderConversationsListScreen> createState() => _OrderConversationsListScreenState();
}

class _OrderConversationsListScreenState extends State<OrderConversationsListScreen> {
  ApiResponse<OrderConversationsListData>? _result;

  Future<void> _load() async {
    final api = context.read<ApiService>();
    final res = await api.getOrderConversations();
    if (mounted) setState(() => _result = res);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final res = _result;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Seller'),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary,
      ),
      body: res == null
          ? const Center(child: CircularProgressIndicator())
          : !res.success
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(res.error ?? 'Failed to load conversations'),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : res.data!.conversations.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: theme.colorScheme.outline),
                            const SizedBox(height: 16),
                            Text('No conversations yet', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(
                              'Open an order and tap "Contact Seller" to start a chat.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        itemCount: res.data!.conversations.length,
                        itemBuilder: (context, index) {
                          final conv = res.data!.conversations[index];
                          return _ConversationTile(
                            item: conv,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderConversationScreen(
                                    orderRef: conv.orderNumber,
                                    orderNumber: conv.orderNumber,
                                  ),
                                ),
                              ).then((_) => _load());
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.item, required this.onTap});

  final OrderConversationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = item.lastMessage;
    String subtitle = 'No messages yet';
    if (preview != null) {
      if (preview.message != null && preview.message!.isNotEmpty) {
        subtitle = preview.message!.length > 50 ? '${preview.message!.substring(0, 50)}...' : preview.message!;
      } else if (preview.attachmentName != null && preview.attachmentName!.isNotEmpty) {
        subtitle = 'Attachment: ${preview.attachmentName}';
      }
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text('#', style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
        ),
        title: Row(
          children: [
            Text('Order ${item.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (item.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${item.unreadCount}',
                  style: TextStyle(color: theme.colorScheme.onError, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
