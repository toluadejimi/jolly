import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order_tracking.dart';
import '../services/api_service.dart';

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({super.key});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final _controller = TextEditingController();
  OrderTrackingResult? _result;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final orderNumber = _controller.text.trim();
    if (orderNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your order number')),
      );
      return;
    }
    setState(() {
      _loading = true;
      _result = null;
    });
    final api = context.read<ApiService>();
    final res = await api.getOrderTracking(orderNumber);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Order number',
                hintText: 'e.g. ORD-12345',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _track(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _track,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Track'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResult(_result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult(OrderTrackingResult r) {
    if (!r.success) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(r.error ?? 'Order not found'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ${r.orderNumber ?? ''}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (r.estimatedDeliveryAt != null) ...[
              const Text('Estimated delivery:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(r.estimatedDeliveryAt!),
              const SizedBox(height: 12),
            ],
            if (r.trackingNumber != null) ...[
              const Text('Tracking number:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(r.trackingNumber!),
              const SizedBox(height: 12),
            ],
            if (r.trackingUrl != null && r.trackingUrl!.isNotEmpty) ...[
              FilledButton.icon(
                onPressed: () => launchUrl(Uri.parse(r.trackingUrl!)),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open tracking link'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
