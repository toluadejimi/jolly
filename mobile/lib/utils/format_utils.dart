/// Formats numeric amount with thousands separator (e.g. 58000.5 → "58,000.50").
String formatAmount(double amount) {
  if (amount.isNaN || amount.isInfinite) return '0.00';
  final neg = amount < 0;
  final a = neg ? -amount : amount;
  final parts = a.toStringAsFixed(2).split('.');
  final intPart = parts[0];
  final decPart = parts.length > 1 ? parts[1] : '00';
  final buffer = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
    buffer.write(intPart[i]);
  }
  final s = '$buffer.$decPart';
  return neg ? '-$s' : s;
}

/// Formats amount as Naira currency (e.g. 58000.5 → "₦58,000.50").
String formatNiara(double amount) {
  return '₦${formatAmount(amount)}';
}
