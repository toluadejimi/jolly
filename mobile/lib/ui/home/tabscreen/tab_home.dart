// ignore: file_names
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:giftfr/constants/constant.dart';
import 'package:giftfr/constants/size_config.dart';
import 'package:giftfr/constants/widget_utils.dart';
import 'package:giftfr/constants/color_data.dart';
import 'package:giftfr/constants/app_theme.dart';
import 'package:giftfr/models/category.dart';
import 'package:giftfr/models/product.dart';
import 'package:giftfr/models/slider.dart' as app;
import 'package:giftfr/screens/product_detail_screen.dart';
import 'package:giftfr/screens/product_list_screen.dart';
import 'package:giftfr/models/cart_item.dart';
import 'package:giftfr/providers/cart_provider.dart';
import 'package:giftfr/services/api_service.dart';
import 'package:giftfr/ui/home/home_screen.dart';
import 'package:giftfr/utils/format_utils.dart';
import 'package:giftfr/utils/color_utils.dart';
import 'package:giftfr/widgets/ai_assistant_sheet.dart';
import 'package:giftfr/widgets/product_badge_ribbon.dart';
import 'package:url_launcher/url_launcher.dart';

class TabHome extends StatefulWidget {
  const TabHome({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TabHomeState();
}

class _TabHomeState extends State<TabHome> with SingleTickerProviderStateMixin {
  List<app.SliderItem> _sliders = [];
  List<CategoryItem> _categories = [];
  List<ProductItem> _products = [];
  bool _loading = true;
  String? _error;
  int _sliderIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));
    _loadAll();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ProductItem> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    final q = _searchQuery.toLowerCase();
    return _products.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _loadAll() async {
    final api = context.read<ApiService>();
    setState(() {
      _loading = true;
      _error = null;
    });
    final sliderRes = await api.getSliders();
    final categoryRes = await api.getCategories();
    if (!mounted) return;
    final sliders = sliderRes.success && sliderRes.data != null
        ? sliderRes.data!
        : <app.SliderItem>[];
    final categories = categoryRes.success && categoryRes.data != null
        ? categoryRes.data!
        : <CategoryItem>[];
    List<ProductItem> allProducts = [];
    int page = 1;
    int lastPage = 1;
    do {
      final productRes = await api.getProducts(page: page, perPage: 100);
      if (!mounted) break;
      if (!productRes.success || productRes.data == null) {
        setState(() {
          _loading = false;
          _sliders = sliders;
          _categories = categories;
          _products = allProducts;
          _error = allProducts.isEmpty
              ? (productRes.error ?? 'Failed to load products')
              : null;
        });
        _entranceController.forward(from: 0);
        return;
      }
      final data = productRes.data!;
      allProducts = [...allProducts, ...data.products];
      lastPage = data.pagination.lastPage;
      page++;
    } while (page <= lastPage);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sliders = sliders;
      _categories = categories;
      _products = allProducts;
      _error = null;
    });
    _entranceController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final theme = Theme.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final screenHeight = SizeConfig.safeBlockVertical! * 100;
    final screenWidth = SizeConfig.safeBlockHorizontal! * 100;
    final pad = getAppBarPadding();
    const crossAxisCount = 2;
    final heroHeight =
        Constant.getPercentSize(screenWidth, 48).clamp(160.0, 220.0);
    final popularWidth =
        (screenWidth - ((crossAxisCount + 1) * pad)) / crossAxisCount;
    final popularHeight = Constant.getPercentSize(screenHeight, 34);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: theme.scaffoldBackgroundColor,
        child: Stack(
          children: [
            Column(
              children: [
                _HomeHeader(
                  topPad: topPad,
                  pad: pad,
                  searchController: _searchController,
                  hasQuery: _searchQuery.isNotEmpty,
                  onClearSearch: () => _searchController.clear(),
                  onCartTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(selectedTab: 2),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: primaryColor,
                    onRefresh: _loadAll,
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideIn,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: [
                            const SizedBox(height: 8),
                            _buildSliderSection(heroHeight, pad),
                            Padding(
                              padding: EdgeInsets.fromLTRB(pad, 16, pad, 0),
                              child: _AssistantPromoCard(
                                onTap: () => showAiAssistantSheet(context),
                              ),
                            ),
                            if (_categories.isNotEmpty) ...[
                          _SectionHeader(
                            title: 'Shop by category',
                            subtitle: 'Browse gifts by occasion and style',
                            actionLabel: 'See all',
                            onAction: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      HomeScreen(selectedTab: 1),
                                ),
                              );
                            },
                            padding: EdgeInsets.fromLTRB(pad, 22, pad, 14),
                          ),
                          SizedBox(
                            height: 148,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: pad),
                              itemCount: _categories.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                return _CategoryTile(
                                  category: cat,
                                  imageUrl: _categoryImageUrl(cat),
                                  accentIndex: index,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ProductListScreen(
                                          categoryId: cat.id,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                        _SectionHeader(
                          title: 'Featured gifts',
                          subtitle: _searchQuery.isEmpty
                              ? 'Handpicked picks for every occasion'
                              : 'Results for “$_searchQuery”',
                          actionLabel: 'View all',
                          onAction: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProductListScreen(),
                              ),
                            );
                          },
                          padding: EdgeInsets.fromLTRB(pad, 22, pad, 12),
                        ),
                        if (_loading)
                          Padding(
                            padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
                            child: GridView.builder(
                              itemCount: 4,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: pad,
                                mainAxisSpacing: pad,
                                childAspectRatio: popularWidth / popularHeight,
                              ),
                              itemBuilder: (_, __) => Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F2F4),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          )
                        else if (_error != null)
                          _EmptyState(
                            message: _error!,
                            actionLabel: 'Retry',
                            onAction: _loadAll,
                            pad: pad,
                          )
                        else if (_products.isEmpty)
                          _EmptyState(
                            message: 'No products yet.',
                            pad: pad,
                          )
                        else if (_filteredProducts.isEmpty)
                          _EmptyState(
                            message: 'No products match your search.',
                            pad: pad,
                          )
                        else
                          Padding(
                            padding: EdgeInsets.fromLTRB(pad, 0, pad, pad + 72),
                            child: GridView.builder(
                              itemCount: _filteredProducts.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: pad,
                                mainAxisSpacing: pad,
                                childAspectRatio: popularWidth / popularHeight,
                              ),
                              itemBuilder: (context, index) {
                                final p = _filteredProducts[index];
                                return _ProductCard(
                                  product: p,
                                  height: popularHeight,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailScreen(
                                          productId: p.id,
                                        ),
                                      ),
                                    );
                                  },
                                  onAdd: () {
                                    final price = p.salePrice < p.regularPrice
                                        ? p.salePrice
                                        : p.regularPrice;
                                    _onAddToCartPressed(context, p, price);
                                  },
                                );
                              },
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: pad,
              bottom: pad + 8,
              child: _AssistantFab(
                onPressed: () => showAiAssistantSheet(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSection(double height, double pad) {
    if (_sliders.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: pad),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.neonOrange,
                AppTheme.neonOrangeDark,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'JollyBox',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Thoughtful gifts,\ndelivered with care',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        height: 1.15,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _sliders.length,
          options: CarouselOptions(
            height: height,
            viewportFraction: 0.92,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            enlargeCenterPage: true,
            enlargeFactor: 0.12,
            onPageChanged: (index, _) =>
                setState(() => _sliderIndex = index),
          ),
          itemBuilder: (context, index, realIndex) {
            final slide = _sliders[index];
            final imageUrl = slide.imageUrl;
            final content = ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.neonOrange.withValues(alpha: 0.2),
                        child: const Center(
                          child: Icon(Icons.card_giftcard,
                              color: Colors.white, size: 40),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.neonOrange,
                            AppTheme.neonOrangeDark,
                          ],
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: slide.link != null && slide.link!.isNotEmpty
                  ? GestureDetector(
                      onTap: () => launchUrl(Uri.parse(slide.link!)),
                      child: content,
                    )
                  : content,
            );
          },
        ),
        if (_sliders.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_sliders.length, (i) {
              final active = _sliderIndex == i;
              return AnimatedContainer(
                duration: AppTheme.transition,
                curve: Curves.easeOutCubic,
                width: active ? 18 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: active
                      ? primaryColor
                      : primaryColor.withValues(alpha: 0.28),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  String? _categoryImageUrl(CategoryItem cat) {
    if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty) return cat.imageUrl;
    if (cat.iconUrl != null && cat.iconUrl!.isNotEmpty) return cat.iconUrl;
    return null;
  }

  Future<void> _onAddToCartPressed(
      BuildContext context, ProductItem p, double listPrice) async {
    final api = context.read<ApiService>();
    final cart = context.read<CartProvider>();
    final theme = Theme.of(context);
    final res = await api.getProduct(p.id);
    if (!context.mounted) return;
    if (!res.success || res.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.error ?? 'Could not load product'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final product = res.data!;
    if (product.variants.isEmpty) {
      cart.add(CartItem(
        productId: p.id,
        variantId: null,
        name: p.name,
        price: listPrice,
        imageUrl: p.thumbUrl ?? p.imageUrl,
        currency: p.currency,
        quantity: 1,
        countryFilter: p.countryFilter,
        hasCustomerPhoto: product.customerPhoto,
        hasCustomisedTest: product.customisedTest,
        hasCustomisedShortTest: product.customisedShortTest,
        hasNote: product.note,
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Added to cart'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: theme.colorScheme.primary,
        ),
      );
      return;
    }

    ProductVariant? selectedVariant;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Text(
                        'Choose option',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: product.variants.map((v) {
                          final variantPrice = v.salePrice < v.regularPrice
                              ? v.salePrice
                              : v.regularPrice;
                          final isSelected = selectedVariant?.id == v.id;
                          final display = variantOptionDisplay(
                              v.name, formatNiara(variantPrice));
                          return ChoiceChip(
                            label: display.color != null
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: display.color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: theme.dividerColor),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(display.displayLabel),
                                    ],
                                  )
                                : Text(display.displayLabel),
                            selected: isSelected,
                            onSelected: (_) => setModalState(
                                () => selectedVariant = isSelected ? null : v),
                            selectedColor: theme.colorScheme.primaryContainer,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: selectedVariant == null
                              ? null
                              : () {
                                  final v = selectedVariant!;
                                  final variantPrice =
                                      v.salePrice < v.regularPrice
                                          ? v.salePrice
                                          : v.regularPrice;
                                  context.read<CartProvider>().add(CartItem(
                                        productId: product.id,
                                        variantId: v.id,
                                        name: product.name,
                                        price: variantPrice,
                                        imageUrl: product.thumbUrl ??
                                            product.imageUrl,
                                        currency: product.currency,
                                        quantity: 1,
                                        countryFilter: product.countryFilter,
                                        hasCustomerPhoto:
                                            product.customerPhoto,
                                        hasCustomisedTest:
                                            product.customisedTest,
                                        hasCustomisedShortTest:
                                            product.customisedShortTest,
                                        hasNote: product.note,
                                      ));
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Added to cart'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text('Add to cart'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.topPad,
    required this.pad,
    required this.searchController,
    required this.hasQuery,
    required this.onClearSearch,
    required this.onCartTap,
  });

  final double topPad;
  final double pad;
  final TextEditingController searchController;
  final bool hasQuery;
  final VoidCallback onClearSearch;
  final VoidCallback onCartTap;

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
        padding: EdgeInsets.fromLTRB(pad, topPad + 10, pad, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  '${Constant.assetImagePath}jellyboxfr_logo.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JollyBox',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Gifting made easy',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Consumer<CartProvider>(
                  builder: (context, cart, _) {
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: onCartTap,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              getSvgImage(
                                'Bag.svg',
                                22,
                                color: theme.colorScheme.onSurface,
                              ),
                              if (cart.count > 0)
                                Positioned(
                                  right: -8,
                                  top: -8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      cart.count > 99
                                          ? '99+'
                                          : '${cart.count}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
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
                  hintText: 'Search gifts...',
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.padding,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final EdgeInsets padding;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatefulWidget {
  const _CategoryTile({
    required this.category,
    required this.imageUrl,
    required this.accentIndex,
    required this.onTap,
  });

  final CategoryItem category;
  final String? imageUrl;
  final int accentIndex;
  final VoidCallback onTap;

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _pressed = false;

  static const _accents = [
    Color(0xFFFF5F1F),
    Color(0xFFE55518),
    Color(0xFFFF8A4C),
    Color(0xFFD9480F),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = _accents[widget.accentIndex % _accents.length];

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: SizedBox(
          width: 132,
          height: 148,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: widget.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: accent.withValues(alpha: 0.18)),
                    errorWidget: (_, __, ___) => _CategoryFallback(accent: accent),
                  )
                else
                  _CategoryFallback(accent: accent),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Explore',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryFallback extends StatelessWidget {
  const _CategoryFallback({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.85),
            accent,
            const Color(0xFFE55518),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.card_giftcard_rounded,
          color: Colors.white.withValues(alpha: 0.9),
          size: 36,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.height,
    required this.onTap,
    required this.onAdd,
  });

  final ProductItem product;
  final double height;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = product.thumbUrl ?? product.imageUrl;
    final onSale = product.salePrice < product.regularPrice;
    final price = onSale ? product.salePrice : product.regularPrice;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: ShapeDecoration(
          color: theme.cardTheme.color ?? Colors.white,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 18,
              cornerSmoothing: 0.6,
            ),
          ),
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: const Color(0xFFF3F4F6),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFFF3F4F6),
                                child: Icon(
                                  Icons.card_giftcard,
                                  size: Constant.getPercentSize(height, 22),
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            )
                          : Container(
                              color: const Color(0xFFF3F4F6),
                              child: Icon(
                                Icons.card_giftcard,
                                size: Constant.getPercentSize(height, 22),
                                color: theme.colorScheme.primary,
                              ),
                            ),
                    ),
                  ),
                  if (product.displayBadges.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: ProductBadgeRibbon(
                        labels: product.displayBadges,
                        compact: true,
                        maxLines: 2,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
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
                    fontSize: 14,
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
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: FilledButton(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  product.hasVariants ? 'Choose option' : 'Add to cart',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.pad,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final double pad;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(pad * 1.5),
      child: Column(
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 42,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssistantPromoCard extends StatelessWidget {
  const _AssistantPromoCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor,
                primaryColor.withValues(alpha: 0.82),
                const Color(0xFFFF8A4C),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jolly Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Order gifts, track delivery, or contact support',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantFab extends StatelessWidget {
  const _AssistantFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      shadowColor: primaryColor.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(18),
      color: primaryColor,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.smart_toy_outlined, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Ask AI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
