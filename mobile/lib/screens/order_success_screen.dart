import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/api_response.dart';
import '../models/user_dashboard.dart';
import '../services/api_service.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({
    super.key,
    required this.orderRef,
  });

  final String orderRef;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  ApiResponse<UserOrderDetail>? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<ApiService>();
    final res = await api.getOrderDetail(widget.orderRef);
    if (!mounted) return;
    setState(() => _result = res);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final res = _result;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order placed'),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary,
      ),
      body: res == null
          ? const Center(child: CircularProgressIndicator())
          : !res.success || res.data == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(res.error ?? 'Unable to load order summary'),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _SuccessBody(order: res.data!),
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({required this.order});

  final UserOrderDetail order;

  String _shippingLine(dynamic shippingAddress) {
    if (shippingAddress is! Map) return '—';
    final first = (shippingAddress['firstname'] ?? '').toString().trim();
    final last = (shippingAddress['lastname'] ?? '').toString().trim();
    final name = '$first $last'.trim();
    final parts = <String>[
      (shippingAddress['address'] ?? '').toString().trim(),
      (shippingAddress['state'] ?? '').toString().trim(),
      (shippingAddress['city'] ?? '').toString().trim(),
      (shippingAddress['zip'] ?? '').toString().trim(),
      (shippingAddress['country'] ?? '').toString().trim(),
    ]..removeWhere((e) => e.isEmpty);
    final addr = parts.join(', ');
    final full = <String>[name, addr]..removeWhere((e) => e.trim().isEmpty);
    return full.isEmpty ? '—' : full.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final shipping = _shippingLine(order.shippingAddress);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
              border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Text(
                  'Order Placed!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFB12222),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your order has been confirmed successfully.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (firstItem != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 130,
                      height: 130,
                      child: (firstItem.imageUrl != null && firstItem.imageUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: firstItem.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.image_not_supported_outlined),
                              ),
                            )
                          : Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.image_outlined),
                            ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _RowText(label: 'Delivery To', value: shipping),
                  const SizedBox(height: 8),
                  _RowText(
                    label: 'Estimated Delivery',
                    value: (order.estimatedDeliveryAt != null && order.estimatedDeliveryAt!.isNotEmpty)
                        ? order.estimatedDeliveryAt!
                        : '—',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Thank You'),
          ),
        ],
      ),
    );
  }
}

class _RowText extends StatelessWidget {
  const _RowText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

