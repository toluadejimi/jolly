// ignore: file_names
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:giftfr/constants/constant.dart';
import 'package:giftfr/constants/size_config.dart';
import 'package:giftfr/constants/widget_utils.dart';
import 'package:giftfr/constants/color_data.dart';
import 'package:giftfr/models/category.dart';
import 'package:giftfr/models/api_response.dart';
import 'package:giftfr/models/product.dart';
import 'package:giftfr/models/slider.dart' as app;
import 'package:giftfr/screens/product_detail_screen.dart';
import 'package:giftfr/screens/product_list_screen.dart';
import 'package:giftfr/models/cart_item.dart';
import 'package:giftfr/providers/cart_provider.dart';
import 'package:giftfr/services/api_service.dart';
import 'package:giftfr/ui/home/home_screen.dart';
import 'package:giftfr/utils/format_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class TabHome extends StatefulWidget {
  const TabHome({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TabHomeState();
}

class _TabHomeState extends State<TabHome> {
  List<app.SliderItem> _sliders = [];
  List<CategoryItem> _categories = [];
  List<ProductItem> _products = [];
  bool _loading = true;
  String? _error;
  int _sliderIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    final sliders = sliderRes.success && sliderRes.data != null ? sliderRes.data! : <app.SliderItem>[];
    final categories = categoryRes.success && categoryRes.data != null ? categoryRes.data! : <CategoryItem>[];
    List<ProductItem> allProducts = [];
    int page = 1;
    int? lastPage;
    do {
      final productRes = await api.getProducts(page: page, perPage: 100);
      if (!mounted) break;
      if (!productRes.success || productRes.data == null) {
        setState(() {
          _loading = false;
          _sliders = sliders;
          _categories = categories;
          _products = allProducts;
          _error = allProducts.isEmpty ? (productRes.error ?? 'Failed to load products') : null;
        });
        return;
      }
      final data = productRes.data!;
      allProducts = [...allProducts, ...data.products];
      lastPage = data.pagination.lastPage;
      page++;
    } while (lastPage != null && page <= lastPage);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sliders = sliders;
      _categories = categories;
      _products = allProducts;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double screenWidth = SizeConfig.safeBlockHorizontal! * 100;
    double appbarPadding = getAppBarPadding();
    double iconSize = Constant.getPercentSize(screenHeight, 3);
    double carousalHeight = Constant.getPercentSize(screenWidth, 32);
    double categoryHeight = Constant.getPercentSize(screenHeight, 14);
    double categoryWidth = Constant.getPercentSize(categoryHeight, 58);
    double marginPopular = appbarPadding;
    int crossAxisCountPopular = 2;
    double popularWidth =
        (screenWidth - ((crossAxisCountPopular - 1) * marginPopular)) /
            crossAxisCountPopular;
    double popularHeight = Constant.getPercentSize(screenHeight, 32);

    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: appbarPadding),
            child: AppBar(
              elevation: 0,
              backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary,
              foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary,
              leadingWidth: Constant.getPercentSize(screenHeight, 18),
              leading: CachedNetworkImage(
                imageUrl: 'https://jollyboxfr.com/assets/images/logo_icon/logo_dark.png',
                height: Constant.getPercentSize(screenHeight, 4),
                fit: BoxFit.contain,
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
              actions: [
                Consumer<CartProvider>(
                  builder: (context, cart, _) {
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(selectedTab: 2),
                          ),
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          getSvgImage("Bag.svg", iconSize, color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary),
                          if (cart.count > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  cart.count > 99 ? '99+' : '${cart.count}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: Constant.getPercentSize(screenHeight, 1.2)),
          // Search bar between app bar and slider
          Padding(
            padding: EdgeInsets.symmetric(horizontal: appbarPadding),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant, size: 22),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                ),
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                onSubmitted: (_) {},
              ),
            ),
          ),
          SizedBox(height: Constant.getPercentSize(screenHeight, 1)),
          Expanded(
            flex: 1,
            child: Container(
              color: theme.scaffoldBackgroundColor,
              width: double.infinity,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(height: Constant.getPercentSize(screenHeight, 2)),
                  // Slider from backend
                  _buildSliderSection(carousalHeight, appbarPadding, screenHeight),
                  // Categories from backend
                  if (_categories.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: appbarPadding,
                        vertical: Constant.getPercentSize(screenHeight, 1),
                      ),
                      child: getCustomText(
                        "Categories",
                        theme.colorScheme.onSurface,
                        1,
                        TextAlign.start,
                        FontWeight.w800,
                        Constant.getPercentSize(screenHeight, 2.5),
                      ),
                    ),
                    SizedBox(
                      height: categoryHeight,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: appbarPadding),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          return Padding(
                            padding: EdgeInsets.only(right: index < _categories.length - 1 ? 12 : 0),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ProductListScreen(categoryId: cat.id),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: categoryWidth,
                                height: categoryHeight,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: categoryWidth,
                                        decoration: BoxDecoration(
                                          color: theme.cardTheme.color,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: theme.dividerColor),
                                          boxShadow: theme.brightness == Brightness.dark ? null : [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.06),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: _categoryImageUrl(cat) != null
                                              ? CachedNetworkImage(
                                                  imageUrl: _categoryImageUrl(cat)!,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                  placeholder: (_, __) => Container(color: theme.cardTheme.color, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                                                  errorWidget: (_, __, ___) => Container(color: theme.colorScheme.primary.withValues(alpha: 0.2), child: Icon(Icons.category, color: theme.colorScheme.primary, size: 32)),
                                                )
                                              : Container(color: theme.colorScheme.primary.withValues(alpha: 0.2), child: Icon(Icons.category, color: theme.colorScheme.primary, size: 32)),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: Constant.getPercentSize(categoryHeight, 6)),
                                    SizedBox(
                                      width: categoryWidth,
                                      height: Constant.getPercentSize(categoryHeight, 18),
                                      child: getCustomText(
                                        cat.name,
                                        theme.colorScheme.onSurface,
                                        2,
                                        TextAlign.center,
                                        FontWeight.w600,
                                        Constant.getPercentSize(categoryHeight, 10),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: Constant.getPercentSize(screenHeight, 1.5)),
                  ],
                  // Products section header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: appbarPadding,
                      vertical: Constant.getPercentSize(screenHeight, 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        getCustomText(
                          "Products",
                          theme.colorScheme.onSurface,
                          1,
                          TextAlign.start,
                          FontWeight.w800,
                          Constant.getPercentSize(screenHeight, 3),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ProductListScreen(),
                              ),
                            );
                          },
                          child: getCustomText(
                            "View all",
                            theme.colorScheme.primary,
                            1,
                            TextAlign.start,
                            FontWeight.w400,
                            Constant.getPercentSize(screenHeight, 2.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_loading)
                    Padding(
                      padding: EdgeInsets.all(appbarPadding * 2),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Padding(
                      padding: EdgeInsets.all(appbarPadding),
                      child: Column(
                        children: [
                          getCustomText(
                            _error!,
                            theme.colorScheme.onSurfaceVariant,
                            3,
                            TextAlign.center,
                            FontWeight.w400,
                            Constant.getPercentSize(screenHeight, 2.2),
                          ),
                          SizedBox(height: Constant.getPercentSize(screenHeight, 2)),
                          TextButton(
                            onPressed: _loadAll,
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    )
                  else if (_products.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(appbarPadding),
                      child: getCustomText(
                        "No products yet.",
                        theme.colorScheme.onSurfaceVariant,
                        1,
                        TextAlign.center,
                        FontWeight.w400,
                        Constant.getPercentSize(screenHeight, 2.2),
                      ),
                    )
                  else if (_filteredProducts.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(appbarPadding),
                      child: getCustomText(
                        "No products match your search.",
                        theme.colorScheme.onSurfaceVariant,
                        1,
                        TextAlign.center,
                        FontWeight.w400,
                        Constant.getPercentSize(screenHeight, 2.2),
                      ),
                    )
                  else
                    GridView.count(
                      padding: EdgeInsets.only(
                        left: marginPopular,
                        right: marginPopular,
                        bottom: marginPopular,
                        top: 0,
                      ),
                      crossAxisCount: crossAxisCountPopular,
                      crossAxisSpacing: marginPopular,
                      mainAxisSpacing: marginPopular,
                      childAspectRatio: popularWidth / popularHeight,
                      shrinkWrap: true,
                      primary: false,
                      children: _filteredProducts.map((p) => _productCard(context, p, popularWidth, popularHeight)).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection(double carousalHeight, double appbarPadding, double screenHeight) {
    if (_sliders.isEmpty) {
      return Container(
        height: carousalHeight,
        margin: EdgeInsets.all(Constant.getPercentSize(screenHeight, 1.5)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Constant.getPercentSize(carousalHeight, 8)),
          color: primaryColor.withOpacity(0.2),
        ),
        child: Center(
          child: getCustomText(
            "Gift Store",
            Colors.white,
            1,
            TextAlign.center,
            FontWeight.bold,
            Constant.getPercentSize(carousalHeight, 10),
          ),
        ),
      );
    }
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _sliders.length,
          options: CarouselOptions(
            height: carousalHeight,
            viewportFraction: 1.0,
            autoPlay: true,
            enlargeCenterPage: false,
            onPageChanged: (index, _) => setState(() => _sliderIndex = index),
          ),
          itemBuilder: (context, index, realIndex) {
            final slide = _sliders[index];
            final imageUrl = slide.imageUrl;
            Widget content;
            if (imageUrl != null && imageUrl.isNotEmpty) {
              content = CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                errorWidget: (_, __, ___) => Container(color: primaryColor.withOpacity(0.2), child: Center(child: getCustomText("Gift Store", Colors.white, 1, TextAlign.center, FontWeight.bold, 18))),
              );
            } else {
              content = Container(
                color: primaryColor.withOpacity(0.2),
                child: Center(
                  child: getCustomText("Gift Store", Colors.white, 1, TextAlign.center, FontWeight.bold, Constant.getPercentSize(carousalHeight, 10)),
                ),
              );
            }
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: appbarPadding),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Constant.getPercentSize(carousalHeight, 8)),
                child: slide.link != null && slide.link!.isNotEmpty
                    ? GestureDetector(
                        onTap: () => launchUrl(Uri.parse(slide.link!)),
                        child: content,
                      )
                    : content,
              ),
            );
          },
        ),
        if (_sliders.length > 1)
          Padding(
            padding: EdgeInsets.only(top: Constant.getPercentSize(screenHeight, 0.8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_sliders.length, (i) {
                return Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _sliderIndex == i ? primaryColor : primaryColor.withOpacity(0.3),
                  ),
                );
              }),
            ),
          ),
        SizedBox(height: Constant.getPercentSize(screenHeight, 1.5)),
      ],
    );
  }

  String? _categoryImageUrl(CategoryItem cat) {
    if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty) return cat.imageUrl;
    if (cat.iconUrl != null && cat.iconUrl!.isNotEmpty) return cat.iconUrl;
    return null;
  }

  Widget _categoryPlaceholder(double categoryWidth, double categoryHeight) {
    return Container(
      width: categoryWidth,
      color: primaryColor.withOpacity(0.2),
      child: Icon(Icons.category, color: primaryColor, size: Constant.getPercentSize(categoryHeight, 35)),
    );
  }

  Future<void> _onAddToCartPressed(BuildContext context, ProductItem p, double listPrice) async {
    final api = context.read<ApiService>();
    final cart = context.read<CartProvider>();
    final theme = Theme.of(context);
    final res = await api.getProduct(p.id);
    if (!context.mounted) return;
    if (!res.success || res.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Could not load product'), behavior: SnackBarBehavior.floating),
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
    // Show choose option bottom sheet
    ProductVariant? selectedVariant;
    final price = product.salePrice < product.regularPrice ? product.salePrice : product.regularPrice;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Choose option',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: product.variants.map((v) {
                          final variantPrice = v.salePrice < v.regularPrice ? v.salePrice : v.regularPrice;
                          final isSelected = selectedVariant?.id == v.id;
                          return ChoiceChip(
                            label: Text(formatNiara(variantPrice)),
                            selected: isSelected,
                            onSelected: (_) => setModalState(() => selectedVariant = isSelected ? null : v),
                            selectedColor: theme.colorScheme.primaryContainer,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: selectedVariant == null
                              ? null
                              : () {
                                  final v = selectedVariant!;
                                  final variantPrice = v.salePrice < v.regularPrice ? v.salePrice : v.regularPrice;
                                  context.read<CartProvider>().add(CartItem(
                                    productId: product.id,
                                    variantId: v.id,
                                    name: product.name,
                                    price: variantPrice,
                                    imageUrl: product.thumbUrl ?? product.imageUrl,
                                    currency: product.currency,
                                    quantity: 1,
                                  ));
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Added to cart'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: theme.colorScheme.primary,
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Add to cart'),
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
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

  Widget _productCard(BuildContext context, ProductItem p, double w, double h) {
    final theme = Theme.of(context);
    final imageUrl = p.thumbUrl ?? p.imageUrl;
    final price = p.salePrice < p.regularPrice ? p.salePrice : p.regularPrice;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: p.id),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(Constant.getPercentSize(h, 3.3)),
        decoration: ShapeDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 14,
              cornerSmoothing: 0.5,
            ),
          ),
          shadows: theme.brightness == Brightness.dark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Constant.getPercentSize(h, 4)),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: theme.cardTheme.color, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                            errorWidget: (_, __, ___) => Container(color: theme.cardTheme.color, child: Icon(Icons.card_giftcard, size: Constant.getPercentSize(h, 25), color: theme.colorScheme.primary)),
                          )
                        : Container(
                            color: theme.cardTheme.color,
                            child: Icon(Icons.card_giftcard, size: Constant.getPercentSize(h, 25), color: theme.colorScheme.primary),
                          ),
                  ),
                  if (p.badge != null && p.badge!.isNotEmpty)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          p.badge!,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: Constant.getPercentSize(h, 3.2),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: Constant.getPercentSize(h, 3)),
            getCustomText(
              p.name,
              theme.colorScheme.onSurface,
              2,
              TextAlign.start,
              FontWeight.bold,
              Constant.getPercentSize(h, 5),
            ),
            SizedBox(height: Constant.getPercentSize(h, 2)),
            getCustomText(
              formatNiara(price),
              theme.colorScheme.onSurfaceVariant,
              1,
              TextAlign.start,
              FontWeight.w400,
              Constant.getPercentSize(h, 5),
            ),
            SizedBox(height: Constant.getPercentSize(h, 2.5)),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => _onAddToCartPressed(context, p, price),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: Constant.getPercentSize(h, 2)),
                    child: Center(
                      child: getCustomText(
                        'Add to cart',
                        theme.colorScheme.onPrimary,
                        1,
                        TextAlign.center,
                        FontWeight.w600,
                        Constant.getPercentSize(h, 4.5),
                      ),
                    ),
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
