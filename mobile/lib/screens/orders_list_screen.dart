import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/api_response.dart';
import '../models/user_dashboard.dart';
import '../services/api_service.dart';
import '../utils/format_utils.dart';
import 'order_detail_screen.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key, this.statusFilter});

  /// Optional: pending, processing, dispatched, delivered, canceled
  final String? statusFilter;

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  int _page = 1;
  bool _loading = false;
  ApiResponse<OrdersListData>? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    final api = context.read<ApiService>();
    final res = await api.getOrders(page: _page, status: widget.statusFilter);
    if (mounted) {
      setState(() {
        _loading = false;
        _result = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final res = _result;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.statusFilter != null ? _titleForStatus(widget.statusFilter!) : 'My Orders'),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary,
      ),
      body: _loading && res == null
          ? const Center(child: CircularProgressIndicator())
          : res == null
              ? const SizedBox.shrink()
              : !res.success
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(res.error ?? 'Failed to load orders'),
                            const SizedBox(height: 16),
                            FilledButton(
                                onPressed: () => _load(),
                                child: const Text('Retry')),
                          ],
                        ),
                      ),
                    )
                  : res.data!.orders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: theme.colorScheme.outline),
                              const SizedBox(height: 16),
                              Text('No orders yet', style: theme.textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text('Your orders will appear here', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            setState(() => _result = null);
                            await _load();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            itemCount: res.data!.orders.length + (res.data!.lastPage > res.data!.currentPage ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= res.data!.orders.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() => _page++);
                                        _load();
                                      },
                                      child: const Text('Load more'),
                                    ),
                                  ),
                                );
                              }
                              final order = res.data!.orders[index];
                              return _OrderTile(
                                order: order,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderDetailScreen(orderId: order.id),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
    );
  }

  String _titleForStatus(String s) {
    switch (s) {
      case 'pending':
        return 'Pending Orders';
      case 'processing':
        return 'Processing Orders';
      case 'dispatched':
        return 'Dispatched Orders';
      case 'delivered':
        return 'Delivered Orders';
      case 'canceled':
        return 'Canceled Orders';
      default:
        return 'My Orders';
    }
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});

  final UserOrderItem order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${order.statusDisplay} · ${formatNiara(order.totalAmount)}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
