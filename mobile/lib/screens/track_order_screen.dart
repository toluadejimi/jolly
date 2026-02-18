import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order_tracking.dart';
import '../services/api_service.dart';

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({super.key, this.orderNumber, this.paymentSuccessMessage});

  final String? orderNumber;
  /// When set, show a success message (e.g. after SprintPay payment verified).
  final String? paymentSuccessMessage;

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final _controller = TextEditingController();
  OrderTrackingResult? _result;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.orderNumber != null && widget.orderNumber!.isNotEmpty) {
      _controller.text = widget.orderNumber!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _track());
    }
    if (widget.paymentSuccessMessage != null && widget.paymentSuccessMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.paymentSuccessMessage!),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Track Your Order',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Order number',
                hintText: 'Enter Your Order ID',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _track(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _track,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Track Now'),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 28),
              _buildResult(context, _result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, OrderTrackingResult r) {
    final theme = Theme.of(context);
    if (!r.success) {
      return Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(child: Text(r.error ?? 'Order not found', style: theme.textTheme.bodyMedium)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order tracking details',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (r.orderNumber != null && r.orderNumber!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Order ${r.orderNumber}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 12),
                // Estimated delivery – always show row
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                    children: [
                      TextSpan(text: 'Estimated delivery: ', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                      TextSpan(
                        text: (r.estimatedDeliveryAt != null && r.estimatedDeliveryAt!.isNotEmpty) ? r.estimatedDeliveryAt! : '—',
                        style: TextStyle(color: (r.estimatedDeliveryAt != null && r.estimatedDeliveryAt!.isNotEmpty) ? null : theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Tracking number – always show row
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                    children: [
                      TextSpan(text: 'Tracking Number: ', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                      TextSpan(
                        text: (r.trackingNumber != null && r.trackingNumber!.isNotEmpty) ? r.trackingNumber! : '—',
                        style: TextStyle(color: (r.trackingNumber != null && r.trackingNumber!.isNotEmpty) ? null : theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Tracking link – show link if URL present, else label
                if (r.trackingUrl != null && r.trackingUrl!.isNotEmpty)
                  InkWell(
                    onTap: () async {
                      final uri = Uri.tryParse(r.trackingUrl!);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.open_in_new, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                                children: [
                                  TextSpan(text: 'Tracking: ', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                                  TextSpan(text: r.trackingUrl!, style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                      children: [
                        TextSpan(text: 'Tracking: ', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                        TextSpan(text: '—', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (r.isCanceled)
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.cancel_outlined, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(child: Text('This order is canceled.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red.shade900))),
                ],
              ),
            ),
          )
        else if (r.isReturned)
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.assignment_return_outlined, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(child: Text('This order was returned.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.orange.shade900))),
                ],
              ),
            ),
          )
        else
          _buildStatusSteps(context, r.status ?? 0),
      ],
    );
  }

  /// Four steps: Pending (0), Processing (1), Dispatched (2), Delivered (3).
  Widget _buildStatusSteps(BuildContext context, int status) {
    final theme = Theme.of(context);
    const steps = [
      (label: 'Pending', icon: Icons.pending_actions_outlined),
      (label: 'Processing', icon: Icons.sync_alt),
      (label: 'Dispatched', icon: Icons.local_shipping_outlined),
      (label: 'Delivered', icon: Icons.check_circle_outline),
    ];
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.outline.withOpacity(0.6);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Row(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Divider(
                    thickness: 2,
                    color: status > i - 1 ? activeColor : inactiveColor,
                  ),
                ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: status >= i ? activeColor.withOpacity(0.15) : theme.colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          color: status >= i ? activeColor : inactiveColor,
                          width: status >= i ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        steps[i].icon,
                        size: 22,
                        color: status >= i ? activeColor : inactiveColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[i].label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: status >= i ? activeColor : inactiveColor,
                        fontWeight: status >= i ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Divider(
                    thickness: 2,
                    color: status > i ? activeColor : inactiveColor,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
