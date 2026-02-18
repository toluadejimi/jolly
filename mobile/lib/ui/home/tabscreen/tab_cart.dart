// ignore: file_names
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:giftfr/constants/size_config.dart';
import 'package:giftfr/constants/color_data.dart';
import 'package:giftfr/models/cart_item.dart';
import 'package:giftfr/providers/cart_provider.dart';
import 'package:giftfr/screens/checkout_screen.dart';
import 'package:giftfr/screens/product_list_screen.dart';
import 'package:giftfr/utils/format_utils.dart';
import '../../../constants/constant.dart';
import '../../../constants/widget_utils.dart';

class TabCart extends StatefulWidget {
  const TabCart({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TabCartState();
}

class _TabCartState extends State<TabCart> {
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double appBarPadding = getAppBarPadding();
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          getDefaultHeader(context, "My Cart", () {}, (value) {},
              withFilter: false, isShowBack: false, isShowSearch: false),
          Expanded(
            child: Consumer<CartProvider>(
              builder: (context, cart, _) {
                if (cart.items.isEmpty) {
                  return getEmptyWidget(
                    "empty_cart.svg",
                    "Your cart is empty",
                    "Add items from the store to checkout.",
                    "Browse products",
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProductListScreen(),
                        ),
                      );
                    },
                    context: context,
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(appBarPadding),
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return _CartItemTile(
                            item: item,
                            onUpdateQuantity: (qty) => cart.updateQuantity(
                                item.productId, item.variantId, qty),
                            onRemove: () => cart.remove(item.productId,
                                variantId: item.variantId),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(appBarPadding),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(
                          top: BorderSide(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                        ),
                        boxShadow: theme.brightness == Brightness.dark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal',
                                  style: theme.textTheme.titleMedium,
                                ),
                                Text(
                                  formatNiara(cart.items
                                      .fold<double>(
                                          0.0,
                                          (s, i) =>
                                              s + (i.price * i.quantity))),
                                  style: theme
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                            SizedBox(height: appBarPadding * 0.5),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CheckoutScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Proceed to Checkout'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onUpdateQuantity,
    required this.onRemove,
  });

  final CartItem item;
  final ValueChanged<int> onUpdateQuantity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox(
                        width: 80,
                        height: 80,
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.card_giftcard,
                            color: theme.colorScheme.primary),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.card_giftcard,
                          color: theme.colorScheme.primary),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatNiara(item.price),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        iconSize: 20,
                        onPressed: item.quantity > 1
                            ? () => onUpdateQuantity(item.quantity - 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('${item.quantity}',
                            style: theme.textTheme.titleSmall),
                      ),
                      IconButton(
                        iconSize: 20,
                        onPressed: () => onUpdateQuantity(item.quantity + 1),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onRemove,
                        icon: Icon(Icons.delete_outline,
                            color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
