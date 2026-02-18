import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/api_response.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../ui/home/home_screen.dart';
import '../utils/format_utils.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  ProductVariant? _selectedVariant;
  late Future<ApiResponse<ProductDetail>> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = context.read<ApiService>().getProduct(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product'),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.shopping_cart_outlined, color: theme.appBarTheme.foregroundColor),
                    if (cart.count > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            cart.count > 99 ? '99+' : '${cart.count}',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => HomeScreen(selectedTab: 2)),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<ApiResponse<ProductDetail>>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final res = snapshot.data;
          if (res == null || !res.success || res.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(res?.error ?? 'Failed to load product'),
              ),
            );
          }
          final p = res.data!;
          return _ProductDetailBody(
            product: p,
            quantity: _quantity,
            selectedVariant: _selectedVariant,
            onQuantityChanged: (v) => setState(() => _quantity = v),
            onVariantSelected: (v) => setState(() => _selectedVariant = v),
          );
        },
      ),
    );
  }
}

class _ProductDetailBody extends StatelessWidget {
  const _ProductDetailBody({
    required this.product,
    required this.quantity,
    required this.selectedVariant,
    required this.onQuantityChanged,
    required this.onVariantSelected,
  });

  final ProductDetail product;
  final int quantity;
  final ProductVariant? selectedVariant;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<ProductVariant?> onVariantSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = product.imageUrl ?? product.thumbUrl;
    final hasVariants = product.variants.isNotEmpty;
    final price = selectedVariant != null
        ? (selectedVariant!.salePrice < selectedVariant!.regularPrice
            ? selectedVariant!.salePrice
            : selectedVariant!.regularPrice)
        : product.salePrice < product.regularPrice
            ? product.salePrice
            : product.regularPrice;
    final canAddToCart = !hasVariants || selectedVariant != null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero image
          Container(
            height: 280,
            width: double.infinity,
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (_, __, ___) => Icon(
                      Icons.card_giftcard,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : Icon(
                    Icons.card_giftcard,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatNiara(price),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (product.brand != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Brand: ${product.brand!.name}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (product.sku != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${product.sku}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                // Variant selector
                if (hasVariants) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Choose option',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: product.variants.map((v) {
                      final isSelected = selectedVariant?.id == v.id;
                      final variantPrice = v.salePrice < v.regularPrice
                          ? v.salePrice
                          : v.regularPrice;
                      return ChoiceChip(
                        label: Text(formatNiara(variantPrice)),
                        selected: isSelected,
                        onSelected: (_) => onVariantSelected(isSelected ? null : v),
                        selectedColor: theme.colorScheme.primaryContainer,
                      );
                    }).toList(),
                  ),
                ],
                // Quantity
                const SizedBox(height: 24),
                Text(
                  'Quantity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton.filled(
                      onPressed: quantity > 1
                          ? () => onQuantityChanged(quantity - 1)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '$quantity',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton.filled(
                      onPressed: quantity < 99
                          ? () => onQuantityChanged(quantity + 1)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Add to cart
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canAddToCart
                        ? () {
                            context.read<CartProvider>().add(CartItem(
                                  productId: product.id,
                                  variantId: selectedVariant?.id,
                                  name: product.name,
                                  price: price,
                                  imageUrl: product.thumbUrl ?? product.imageUrl,
                                  currency: product.currency,
                                  quantity: quantity,
                                ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Added to cart')),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.shopping_cart),
                    label: Text(
                      hasVariants && selectedVariant == null
                          ? 'Choose option'
                          : 'Add to cart',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
