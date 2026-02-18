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
  bool _loadingDashboard = false;
  ApiResponse<OrdersListData>? _result;
  ApiResponse<DashboardData>? _dashboard;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.statusFilter;
    _loadDashboard();
    _load();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loadingDashboard = true);
    final api = context.read<ApiService>();
    final res = await api.getDashboard();
    if (mounted) setState(() { _loadingDashboard = false; _dashboard = res; });
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    final api = context.read<ApiService>();
    final res = await api.getOrders(page: _page, status: _statusFilter);
    if (mounted) {
      setState(() {
        _loading = false;
        _result = res;
      });
    }
  }

  void _onFilterTap(String? status) {
    setState(() {
      _statusFilter = status;
      _page = 1;
      _result = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final res = _result;
    final dash = _dashboard;
    return Scaffold(
      appBar: AppBar(
        title: Text(_statusFilter != null ? _titleForStatus(_statusFilter!) : 'My Orders'),
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
                  : RefreshIndicator(
                      onRefresh: () async {
                        setState(() { _result = null; });
                        await _load();
                        await _loadDashboard();
                      },
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        children: [
                          if (dash?.success == true && dash?.data != null) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _CountChip(
                                  label: 'All',
                                  count: dash!.data!.orderCounts.total,
                                  selected: _statusFilter == null,
                                  onTap: () => _onFilterTap(null),
                                ),
                                _CountChip(
                                  label: 'Pending',
                                  count: dash.data!.orderCounts.pending,
                                  selected: _statusFilter == 'pending',
                                  onTap: () => _onFilterTap('pending'),
                                ),
                                _CountChip(
                                  label: 'Processing',
                                  count: dash.data!.orderCounts.processing,
                                  selected: _statusFilter == 'processing',
                                  onTap: () => _onFilterTap('processing'),
                                ),
                                _CountChip(
                                  label: 'Dispatched',
                                  count: dash.data!.orderCounts.dispatched,
                                  selected: _statusFilter == 'dispatched',
                                  onTap: () => _onFilterTap('dispatched'),
                                ),
                                _CountChip(
                                  label: 'Delivered',
                                  count: dash.data!.orderCounts.delivered,
                                  selected: _statusFilter == 'delivered',
                                  onTap: () => _onFilterTap('delivered'),
                                ),
                                _CountChip(
                                  label: 'Canceled',
                                  count: dash.data!.orderCounts.canceled,
                                  selected: _statusFilter == 'canceled',
                                  onTap: () => _onFilterTap('canceled'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (res.data!.orders.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
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
                          else
                            ...res.data!.orders.map((order) => _OrderTile(
                                  order: order,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderDetailScreen(orderId: order.id),
                                      ),
                                    );
                                  },
                                )),
                          if (res.data!.orders.isNotEmpty && res.data!.lastPage > res.data!.currentPage)
                            Padding(
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
                            ),
                        ],
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

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});

  final UserOrderItem order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
