import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/checkout_models.dart';
import '../screens/track_order_screen.dart';
import '../services/sprintpay_service.dart';
import '../utils/format_utils.dart';

/// Neon orange theme for SprintPay UI (16px rounded, modern card).
const Color _neonOrange = Color(0xFFFF6B35);
const Color _neonOrangeDark = Color(0xFFE55A2B);
const double _cardRadius = 16;

/// Fetches payment URL with mode=api. If response status is true, shows bottom sheet
/// with account details; otherwise returns false (caller can open URL in browser).
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => SprintPayPaymentSheet(
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

/// Direct SprintPay flow: call paynow with amount, ref, email; show sheet or error.
Future<void> showSprintPayDirectFlow(
  BuildContext context, {
  required double amount,
  required String ref,
  required String email,
  required String orderNumber,
  required VoidCallback onOrderSuccess,
}) async {
  final result = await SprintPayService.initiatePaynow(
    amount: amount,
    ref: ref,
    email: email,
  );
  if (!context.mounted) return;
  if (!result.success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.errorMessage ?? 'Payment initiation failed'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SprintPayPaymentSheet(
      data: result.data!,
      orderNumber: orderNumber,
      onOrderSuccess: onOrderSuccess,
    ),
  );
}

/// Payment details bottom sheet: neon orange theme, copy, I Have Paid, Close, polling.
class SprintPayPaymentSheet extends StatefulWidget {
  const SprintPayPaymentSheet({
    super.key,
    required this.data,
    required this.orderNumber,
    required this.onOrderSuccess,
  });

  final SprintPayAccountResponse data;
  final String orderNumber;
  final VoidCallback onOrderSuccess;

  @override
  State<SprintPayPaymentSheet> createState() => _SprintPayPaymentSheetState();
}

class _SprintPayPaymentSheetState extends State<SprintPayPaymentSheet> {
  bool _verifying = false;
  String? _verifyError;
  Timer? _pollTimer;
  bool _polling = false;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    super.dispose();
  }

  void _startPolling() {
    if (_polling) return;
    _polling = true;
    setState(() {
      _verifying = true;
      _verifyError = null;
    });
    const interval = Duration(seconds: 5);
    _pollTimer = Timer.periodic(interval, (_) => _checkVerify());
    _checkVerify();
  }

  Future<void> _checkVerify() async {
    if (!mounted) return;
    final status = await SprintPayService.checkVerifyUrl(widget.data.verifyUrl);
    if (!mounted) return;
    if (status == 'success' || status == 'completed') {
      _pollTimer?.cancel();
      _pollTimer = null;
      _polling = false;
      setState(() => _verifying = false);
      Navigator.of(context).pop();
      widget.onOrderSuccess();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => TrackOrderScreen(
            orderNumber: widget.orderNumber,
            paymentSuccessMessage: 'Payment received successfully.\nYour order has been processed.',
          ),
        ),
        (route) => route.isFirst,
      );
      return;
    }
    if (status != 'pending' && status != null) {
      _pollTimer?.cancel();
      _pollTimer = null;
      _polling = false;
      setState(() {
        _verifying = false;
        _verifyError = 'Verification failed. Tap "I Have Paid" again.';
      });
      return;
    }
    if (status == null) {
      setState(() => _verifyError = 'Check failed. Retrying in 5s…');
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(_cardRadius)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Payment Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _neonOrangeDark,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Transfer the amount below to the account details',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                _PaymentCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DetailRow(label: 'Business Name', value: d.businessName),
                      _DetailRow(label: 'Bank Name', value: d.bankName),
                      _DetailRow(label: 'Account Name', value: d.accountName),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Account Number',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    d.accountNo,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, color: _neonOrange),
                                  onPressed: _copyAccountNo,
                                  tooltip: 'Copy',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      _DetailRow(label: 'Amount', value: '${d.currency} ${formatAmount(d.amount)}'),
                      _DetailRow(label: 'Currency', value: d.currency),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_verifyError != null) ...[
                  Text(
                    _verifyError!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _verifying ? null : _startPolling,
                    style: FilledButton.styleFrom(
                      backgroundColor: _neonOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
                    ),
                    child: _verifying
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('I Have Paid'),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _neonOrangeDark,
                    side: const BorderSide(color: _neonOrange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _neonOrange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _neonOrange.withOpacity(0.3)),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

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
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
