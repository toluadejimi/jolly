import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../models/api_response.dart';
import '../models/user_dashboard.dart';
import '../services/api_service.dart';
import '../utils/format_utils.dart';
import 'order_conversation_screen.dart';

/// Returns a color for the order status chip.
Color statusColor(String status) {
  switch (status) {
    case 'pending':
      return Colors.amber;
    case 'processing':
      return Colors.blue;
    case 'dispatched':
      return Colors.indigo;
    case 'delivered':
      return Colors.green;
    case 'canceled':
      return Colors.red;
    case 'returned':
      return Colors.grey;
    default:
      return Colors.blueGrey;
  }
}

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  /// Order id or order_number
  final dynamic orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  ApiResponse<UserOrderDetail>? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<ApiService>();
    final res = await api.getOrderDetail(widget.orderId);
    if (mounted) setState(() => _result = res);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final res = _result;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order details'),
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
                        Text(res.error ?? 'Failed to load order'),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _OrderDetailBody(order: res.data!),
                ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.order});

  final UserOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        order.orderNumber,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor(order.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor(order.status), width: 1),
                      ),
                      child: Text(
                        order.statusDisplay,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: statusColor(order.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Placed ${order.createdAt}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: theme.textTheme.titleMedium),
                    Text(formatNiara(order.totalAmount), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderConversationScreen(
                            orderRef: order.id,
                            orderNumber: order.orderNumber,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: const Text('Contact Seller'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (order.estimatedDeliveryAt != null && order.estimatedDeliveryAt!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estimated delivery', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text(order.estimatedDeliveryAt!, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if ((order.trackingNumber != null && order.trackingNumber!.isNotEmpty) ||
            (order.trackingUrl != null && order.trackingUrl!.isNotEmpty)) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_shipping_outlined, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Text('Tracking', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Tracking number: ${order.trackingNumber}', style: theme.textTheme.bodyMedium),
                  ],
                  if (order.trackingUrl != null && order.trackingUrl!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final uri = Uri.tryParse(order.trackingUrl!);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text('Track shipment', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, decoration: TextDecoration.underline)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text('Items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...order.items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: _itemImage(item.imageUrl),
                title: Text(item.productName),
                subtitle: Text('Qty: ${item.quantity} × ${formatNiara(item.price)}'),
                trailing: Text(formatNiara(item.subtotal), style: theme.textTheme.titleSmall),
                isThreeLine: false,
              ),
            )),
      ],
    );
  }

  Widget _itemImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 56,
          height: 56,
          color: Colors.grey.shade200,
          child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
        ),
      ),
    );
  }
}
