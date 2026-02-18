import 'package:flutter/material.dart';

/// Product badge/ribbon matching web product_images.blade.php and .product-badge CSS:
/// - Position: top-left on image
/// - Background: linear-gradient(90deg, #007c2e, #00b82e)
/// - White text, font-weight 600, padding 4/10, border-radius 3, box-shadow
class ProductBadgeRibbon extends StatelessWidget {
  const ProductBadgeRibbon({
    super.key,
    required this.labels,
    this.compact = false,
    this.maxLines = 4,
  });

  /// Badge labels in order (e.g. ['Today Delivery', '🇺🇸 US Express Shipping', ...])
  final List<String> labels;

  /// If true, use smaller font for all (e.g. list tile)
  final bool compact;

  /// Max number of badges to show (long labels use smaller font on web)
  final int maxLines;

  /// Web: font-size 13px default, 10px for long badges (US Express Shipping, All Countries Delivery)
  static const int _longLabelThreshold = 20;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final list = labels.take(maxLines).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list.map((label) {
        final isLong = label.length > _longLabelThreshold;
        final fontSize = compact ? 8.0 : (isLong ? 10.0 : 13.0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 10,
              vertical: compact ? 2 : 4,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007c2e), Color(0xFF00b82e)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
