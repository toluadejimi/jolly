import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../utils/format_utils.dart';
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
  bool _loading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ProductSort _sort = ProductSort.def;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            final pa = a.salePrice < a.regularPrice ? a.salePrice : a.regularPrice;
            final pb = b.salePrice < b.regularPrice ? b.salePrice : b.regularPrice;
            return pa.compareTo(pb);
          });
        break;
      case ProductSort.priceHighLow:
        list = List.from(list)
          ..sort((a, b) {
            final pa = a.salePrice < a.regularPrice ? a.salePrice : a.regularPrice;
            final pb = b.salePrice < b.regularPrice ? b.salePrice : b.regularPrice;
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
    int? lastPage;
    do {
      final res = await api.getProducts(
        page: page,
        perPage: 100,
        categoryId: widget.categoryId,
      );
      if (!mounted) return;
      if (!res.success || res.data == null) {
        setState(() {
          _loading = false;
          _allProducts = all;
          _error = all.isEmpty ? (res.error ?? 'Failed to load products') : null;
        });
        return;
      }
      final data = res.data!;
      all = [...all, ...data.products];
      lastPage = data.pagination.lastPage;
      page++;
    } while (page <= lastPage!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _allProducts = all;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryId != null ? 'Products' : 'All Products'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<ProductSort>(
                  value: _sort,
                  items: const [
                    DropdownMenuItem(
                      value: ProductSort.def,
                      child: Text('Default'),
                    ),
                    DropdownMenuItem(
                      value: ProductSort.priceLowHigh,
                      child: Text('Price: Low to High'),
                    ),
                    DropdownMenuItem(
                      value: ProductSort.priceHighLow,
                      child: Text('Price: High to Low'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _sort = v ?? ProductSort.def),
                ),
              ],
            ),
          ),
          Expanded(child: _body(theme)),
        ],
      ),
    );
  }

  Widget _body(ThemeData theme) {
    if (_loading && _allProducts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _allProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
    final list = _filteredProducts;
    if (list.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? 'No products' : 'No products match your search',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final p = list[index];
          final imageUrl = p.thumbUrl ?? p.imageUrl;
          final price = p.salePrice < p.regularPrice ? p.salePrice : p.regularPrice;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(productId: p.id),
                ),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Center(
                                        child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))),
                                    errorWidget: (_, __, ___) =>
                                        const Icon(Icons.card_giftcard),
                                  )
                                : const Icon(Icons.card_giftcard, size: 36),
                          ),
                        ),
                        if (p.badge != null && p.badge!.isNotEmpty)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.badge!,
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatNiara(price),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
