import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/checkout_models.dart';
import '../utils/format_utils.dart';
import '../screens/track_order_screen.dart';

/// Fetches payment URL with mode=api. If response status is true, shows bottom sheet
/// with account details and "I have paid"; polls verify_url until success/completed.
/// Otherwise returns false so caller can fall back to opening URL in browser.
Future<bool> showSprintPayPaymentFlow(
  BuildContext context, {
  required String paymentUrl,
  required String orderNumber,
  required VoidCallback onOrderSuccess,
}) async {
  final urlWithApi = paymentUrl.contains('?') ? '$paymentUrl&mode=api' : '$paymentUrl?mode=api';
  try {
    final res = await http.get(Uri.parse(urlWithApi)).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return false;
    final json = jsonDecode(res.body) as Map<String, dynamic>?;
    if (json == null) return false;
    final data = SprintPayAccountResponse.fromJson(json);
    if (!data.status || data.verifyUrl.isEmpty) return false;
    if (!context.mounted) return true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (ctx) => _SprintPayPaymentSheet(
        data: data,
        orderNumber: orderNumber,
        onOrderSuccess: onOrderSuccess,
      ),
    );
    return true;
  } catch (_) {
    return false;
  }
}

class _SprintPayPaymentSheet extends StatefulWidget {
  const _SprintPayPaymentSheet({
    required this.data,
    required this.orderNumber,
    required this.onOrderSuccess,
  });

  final SprintPayAccountResponse data;
  final String orderNumber;
  final VoidCallback onOrderSuccess;

  @override
  State<_SprintPayPaymentSheet> createState() => _SprintPayPaymentSheetState();
}

class _SprintPayPaymentSheetState extends State<_SprintPayPaymentSheet> {
  bool _verifying = false;
  String? _verifyError;

  Future<void> _onIHavePaid() async {
    if (_verifying) return;
    setState(() {
      _verifying = true;
      _verifyError = null;
    });
    const interval = Duration(seconds: 5);
    while (mounted) {
      try {
        final res = await http.get(Uri.parse(widget.data.verifyUrl)).timeout(const Duration(seconds: 10));
        if (!mounted) return;
        if (res.statusCode != 200) {
        } else {
          final json = jsonDecode(res.body) as Map<String, dynamic>?;
          final status = json?['status']?.toString().toLowerCase();
          if (status == 'success' || status == 'completed') {
            final nav = Navigator.of(context);
            nav.pop();
            widget.onOrderSuccess();
            nav.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => TrackOrderScreen(
                  orderNumber: widget.orderNumber,
                  paymentSuccessMessage: 'Payment received and order has been processed',
                ),
              ),
              (route) => route.isFirst,
            );
            return;
          }
        }
      } catch (e) {
        if (mounted) setState(() => _verifyError = 'Check failed. Retrying…');
      }
      await Future.delayed(interval);
    }
  }

  void _copyAccountNo() {
    if (widget.data.accountNo.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: widget.data.accountNo));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account number copied'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = widget.data;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Pay with Transfer', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Transfer the amount below to the account details', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 20),
              _Row(label: 'Business', value: d.businessName),
              _Row(label: 'Bank', value: d.bankName),
              _Row(label: 'Account name', value: d.accountName),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('Account number', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(d.accountNo, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: _copyAccountNo,
                          tooltip: 'Copy',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _Row(label: 'Amount', value: '${d.currency} ${formatAmount(d.amount)}'),
              _Row(label: 'Ref', value: d.ref),
              const SizedBox(height: 24),
              if (_verifyError != null) ...[
                Text(_verifyError!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                const SizedBox(height: 8),
              ],
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _verifying ? null : _onIHavePaid,
                  child: _verifying
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('I have paid'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
