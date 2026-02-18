import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/checkout_models.dart';
import '../screens/track_order_screen.dart';
import '../services/sprintpay_service.dart';
import '../utils/format_utils.dart';

/// Accent for SprintPay (works on both light/dark; use with theme for contrast).
const Color _accentOrange = Color(0xFFFF6B35);
const double _cardRadius = 16;
const double _sheetRadius = 20;

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
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final d = widget.data;
    final surfaceColor = colorScheme.surface;
    final cardColor = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerHighest.withOpacity(0.6);
    final accentColor = _accentOrange;
    final onAccent = Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(_sheetRadius)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 28,
                      color: accentColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Payment Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: colorScheme.onSurfaceVariant),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Transfer the exact amount below to the account details',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(_cardRadius),
                    border: Border.all(
                      color: isDark
                          ? colorScheme.outlineVariant.withOpacity(0.5)
                          : colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DetailRow(
                        label: 'Business',
                        value: d.businessName,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Bank',
                        value: d.bankName,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Account name',
                        value: d.accountName,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Account number',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    d.accountNo,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Material(
                                  color: accentColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  child: IconButton(
                                    icon: Icon(Icons.copy_rounded, color: accentColor, size: 22),
                                    onPressed: _copyAccountNo,
                                    tooltip: 'Copy account number',
                                    style: IconButton.styleFrom(
                                      padding: const EdgeInsets.all(10),
                                      minimumSize: const Size(44, 44),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'Amount',
                        value: '${d.currency} ${formatAmount(d.amount)}',
                        theme: theme,
                        colorScheme: colorScheme,
                        valueBold: true,
                      ),
                      const SizedBox(height: 6),
                      _DetailRow(
                        label: 'Reference',
                        value: d.ref,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_verifyError != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 20, color: colorScheme.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _verifyError!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _verifying ? null : _startPolling,
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: onAccent,
                      disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                      disabledForegroundColor: colorScheme.onSurfaceVariant,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_cardRadius),
                      ),
                    ),
                    child: _verifying
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: onAccent,
                            ),
                          )
                        : const Text('I have paid'),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                    side: BorderSide(color: colorScheme.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_cardRadius),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.theme,
    required this.colorScheme,
    this.valueBold = false,
  });

  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: valueBold ? FontWeight.w700 : FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
