import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/app_theme.dart';
import '../constants/color_data.dart';
import '../models/cart_item.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../utils/format_utils.dart';
import '../widgets/product_badge_ribbon.dart';
import 'checkout_screen.dart';
import 'product_detail_screen.dart';

enum ProductSort { def, priceLowHigh, priceHighLow }

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.categoryId});

  final int? categoryId;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<ProductItem> _allProducts = [];
  List<CategoryItem> _categories = [];
  bool _loading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ProductSort _sort = ProductSort.def;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _loadCategories();
    _loadAll();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  Future<void> _loadCategories() async {
    final api = context.read<ApiService>();
    final res = await api.getCategories();
    if (mounted && res.success && res.data != null) {
      setState(() => _categories = res.data!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _title {
    if (_selectedCategoryId == null) return 'All Products';
    final match = _categories.where((c) => c.id == _selectedCategoryId);
    if (match.isNotEmpty) return match.first.name;
    return 'Products';
  }

  List<ProductItem> get _filteredProducts {
    var list = _allProducts;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    switch (_sort) {
      case ProductSort.priceLowHigh:
        list = List.from(list)
          ..sort((a, b) {
            final pa =
                a.salePrice < a.regularPrice ? a.salePrice : a.regularPrice;
            final pb =
                b.salePrice < b.regularPrice ? b.salePrice : b.regularPrice;
            return pa.compareTo(pb);
          });
        break;
      case ProductSort.priceHighLow:
        list = List.from(list)
          ..sort((a, b) {
            final pa =
                a.salePrice < a.regularPrice ? a.salePrice : a.regularPrice;
            final pb =
                b.salePrice < b.regularPrice ? b.salePrice : b.regularPrice;
            return pb.compareTo(pa);
          });
        break;
      case ProductSort.def:
        break;
    }
    return list;
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = context.read<ApiService>();
    List<ProductItem> all = [];
    int page = 1;
    int lastPage = 1;
    final categoryId = _selectedCategoryId ?? widget.categoryId;
    do {
      final res = await api.getProducts(
        page: page,
        perPage: 100,
        categoryId: categoryId,
      );
      if (!mounted) return;
      if (!res.success || res.data == null) {
        setState(() {
          _loading = false;
          _allProducts = all;
          _error =
              all.isEmpty ? (res.error ?? 'Failed to load products') : null;
        });
        return;
      }
      final data = res.data!;
      all = [...all, ...data.products];
      lastPage = data.pagination.lastPage;
      page++;
    } while (page <= lastPage);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _allProducts = all;
      _error = null;
    });
  }

  void _selectCategory(int? id) {
    if (_selectedCategoryId == id) return;
    setState(() => _selectedCategoryId = id);
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final filtered = _filteredProducts;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            _ProductsHeader(
              topPad: topPad,
              title: _title,
              subtitle: _loading && _allProducts.isEmpty
                  ? 'Loading gifts…'
                  : '${filtered.length} gift${filtered.length == 1 ? '' : 's'} available',
              searchController: _searchController,
              hasQuery: _searchQuery.isNotEmpty,
              onClearSearch: () => _searchController.clear(),
              onBack: () => Navigator.of(context).maybePop(),
            ),
            if (_categories.isNotEmpty)
              _CategoryFilterRow(
                categories: _categories,
                selectedId: _selectedCategoryId,
                onSelected: _selectCategory,
              ),
            _SortRow(
              sort: _sort,
              onChanged: (v) => setState(() => _sort = v),
            ),
            Expanded(child: _body(theme, filtered)),
          ],
        ),
      ),
    );
  }

  Widget _body(ThemeData theme, List<ProductItem> list) {
    if (_loading && _allProducts.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 118,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F2F4),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
    }

    if (_error != null && _allProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.card_giftcard_outlined,
                size: 44,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadAll,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 44,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isEmpty
                    ? 'No products in this category'
                    : 'No products match “$_searchQuery”',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final p = list[index];
          return _ProductListCard(
            product: p,
            onOpen: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(productId: p.id),
              ),
            ),
            onBuyNow: () {
              final price =
                  p.salePrice < p.regularPrice ? p.salePrice : p.regularPrice;
              context.read<CartProvider>().add(CartItem(
                    productId: p.id,
                    variantId: null,
                    name: p.name,
                    price: price,
                    imageUrl: p.thumbUrl ?? p.imageUrl,
                    currency: p.currency,
                    quantity: 1,
                    countryFilter: p.countryFilter,
                    hasCustomerPhoto: p.customerPhoto,
                    hasCustomisedTest: p.customisedTest,
                    hasCustomisedShortTest: p.customisedShortTest,
                    hasNote: p.note,
                    hasSameDayBdayLoveLetter: p.sameDayBdayLoveLetter,
                    noteFee: p.noteFee,
                    sameDayBdayLoveLetterFee: p.sameDayBdayLoveLetterFee,
                  ));
              CheckoutScreen.showCheckoutChoice(context);
            },
          );
        },
      ),
    );
  }
}

class _ProductsHeader extends StatelessWidget {
  const _ProductsHeader({
    required this.topPad,
    required this.title,
    required this.subtitle,
    required this.searchController,
    required this.hasQuery,
    required this.onClearSearch,
    required this.onBack,
  });

  final double topPad;
  final String title;
  final String subtitle;
  final TextEditingController searchController;
  final bool hasQuery;
  final VoidCallback onClearSearch;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.neonOrange.withValues(alpha: 0.18),
            theme.scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, topPad + 6, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E8EC)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search gifts…',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  suffixIcon: hasQuery
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: onClearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CategoryItem> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        children: [
          _FilterChip(
            label: 'All',
            selected: selectedId == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: c.name,
                selected: selectedId == c.id,
                onTap: () => onSelected(c.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.sort,
    required this.onChanged,
  });

  final ProductSort sort;
  final ValueChanged<ProductSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Text(
            'Sort',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: greyFont,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Default',
                    selected: sort == ProductSort.def,
                    onTap: () => onChanged(ProductSort.def),
                    compact: true,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Price ↑',
                    selected: sort == ProductSort.priceLowHigh,
                    onTap: () => onChanged(ProductSort.priceLowHigh),
                    compact: true,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Price ↓',
                    selected: sort == ProductSort.priceHighLow,
                    onTap: () => onChanged(ProductSort.priceHighLow),
                    compact: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? primaryColor : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 7 : 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? primaryColor
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : fontBlack,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductListCard extends StatelessWidget {
  const _ProductListCard({
    required this.product,
    required this.onOpen,
    required this.onBuyNow,
  });

  final ProductItem product;
  final VoidCallback onOpen;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = product.thumbUrl ?? product.imageUrl;
    final onSale = product.salePrice < product.regularPrice;
    final price = onSale ? product.salePrice : product.regularPrice;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? theme.colorScheme.outlineVariant
                  : const Color(0xFFECECEF),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.card_giftcard,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            )
                          : Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.card_giftcard,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                    ),
                  ),
                  if (product.displayBadges.isNotEmpty)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: ProductBadgeRibbon(
                        labels: product.displayBadges,
                        compact: true,
                        maxLines: 2,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 96,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            formatNiara(price),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                            ),
                          ),
                          if (onSale) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                formatNiara(product.regularPrice),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onOpen,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                                side: BorderSide(
                                  color: theme.brightness == Brightness.dark
                                      ? theme.colorScheme.outline
                                      : const Color(0xFFE5E7EB),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'View',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: onBuyNow,
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Buy now',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
