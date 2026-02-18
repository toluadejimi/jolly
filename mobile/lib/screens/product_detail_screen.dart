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
import '../utils/color_utils.dart';
import '../widgets/product_badge_ribbon.dart';

/// Strip simple HTML tags and normalize whitespace for description text.
String stripHtmlToPlainText(String? html) {
  if (html == null || html.isEmpty) return '';
  String t = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>\s*<p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"');
  return t.splitMapJoin(RegExp(r'\s+'), onMatch: (_) => ' ', onNonMatch: (s) => s).trim();
}

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
                icon: SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Icon(Icons.shopping_cart_outlined, color: theme.appBarTheme.foregroundColor, size: 24),
                      ),
                      if (cart.count > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Center(
                              child: Text(
                                cart.count > 99 ? '99+' : '${cart.count}',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
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
    final hasVariants = product.variants.isNotEmpty;
    final price = selectedVariant != null
        ? (selectedVariant!.salePrice < selectedVariant!.regularPrice
            ? selectedVariant!.salePrice
            : selectedVariant!.regularPrice)
        : product.salePrice < product.regularPrice
            ? product.salePrice
            : product.regularPrice;
    final canAddToCart = !hasVariants || selectedVariant != null;
    // When a variant with images is selected, show its images in the gallery
    final galleryUrls = selectedVariant != null && selectedVariant!.displayImageUrls.isNotEmpty
        ? selectedVariant!.displayImageUrls
        : product.displayImageUrls;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProductImageGallery(
            imageUrls: galleryUrls,
            badges: product.displayBadges,
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
                // Description
                if (product.description != null && product.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stripHtmlToPlainText(product.description),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ],
                // Variant selector – professional layout
                if (hasVariants) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Choose option',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _VariantSelector(
                    variants: product.variants,
                    selectedVariant: selectedVariant,
                    onVariantSelected: onVariantSelected,
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
                                  imageUrl: selectedVariant?.imageUrl ?? product.thumbUrl ?? product.imageUrl,
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

/// Image gallery with page indicator. Shows multiple product/variant images.
class _ProductImageGallery extends StatefulWidget {
  const _ProductImageGallery({
    required this.imageUrls,
    this.badges = const [],
  });

  final List<String> imageUrls;
  final List<String> badges;

  @override
  State<_ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<_ProductImageGallery> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urls = widget.imageUrls.isEmpty
        ? <String>[]
        : widget.imageUrls;
    final hasImages = urls.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 320,
          width: double.infinity,
          child: hasImages
              ? PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: urls.length,
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: urls[index],
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.card_giftcard,
                        size: 80,
                        color: theme.colorScheme.primary,
                      ),
                    );
                  },
                )
              : Container(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  child: Icon(
                    Icons.card_giftcard,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                ),
        ),
        if (hasImages && urls.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(urls.length, (i) {
                final selected = i == _currentPage;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: selected ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                );
              }),
            ),
          ),
        if (widget.badges.isNotEmpty)
          Positioned(
            top: 10,
            left: 10,
            child: ProductBadgeRibbon(labels: widget.badges),
          ),
      ],
    );
  }
}

/// Professional variant selector: cards with optional thumbnail, color, or text.
class _VariantSelector extends StatelessWidget {
  const _VariantSelector({
    required this.variants,
    required this.selectedVariant,
    required this.onVariantSelected,
  });

  final List<ProductVariant> variants;
  final ProductVariant? selectedVariant;
  final ValueChanged<ProductVariant?> onVariantSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 400 ? 2 : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossCount,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: crossCount == 2 ? 2.8 : 3.2,
          children: variants.map((v) {
            final isSelected = selectedVariant?.id == v.id;
            final variantPrice = v.salePrice < v.regularPrice ? v.salePrice : v.regularPrice;
            final display = variantOptionDisplay(v.name, formatNiara(variantPrice));
            final hasImage = v.imageUrl != null && v.imageUrl!.isNotEmpty;

            return Material(
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onVariantSelected(isSelected ? null : v),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      if (hasImage)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: v.imageUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(
                              Icons.image_not_supported_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else if (display.color != null)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: display.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.dividerColor),
                          ),
                        )
                      else
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 22,
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              display.displayLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (v.inStock > 0 && v.inStock < 20)
                              Text(
                                '${v.inStock} left',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
