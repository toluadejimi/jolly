import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/api_response.dart';
import '../models/cart_item.dart';
import '../models/checkout_models.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../ui/home/home_screen.dart';
import '../utils/format_utils.dart';
import '../utils/color_utils.dart';
import '../widgets/product_badge_ribbon.dart';
import '../data/checkout_data.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/sprintpay_payment_sheet.dart';

/// Neon orange theme for Buy Now and payment CTAs.
const Color _neonOrange = Color(0xFFFF6B35);
const double _buttonRadius = 16;

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

class _ProductDetailBody extends StatefulWidget {
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
  State<_ProductDetailBody> createState() => _ProductDetailBodyState();
}

class _ProductDetailBodyState extends State<_ProductDetailBody> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _formSectionKey = GlobalKey();
  bool _showReceiverForm = false;
  bool _variantError = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onBuyNowTap() {
    final hasVariants = widget.product.variants.isNotEmpty;
    if (hasVariants && widget.selectedVariant == null) {
      setState(() => _variantError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an option before continuing.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _variantError = false;
      _showReceiverForm = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _formSectionKey.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    });
  }

  void _onVariantSelected(ProductVariant? v) {
    if (_variantError) setState(() => _variantError = false);
    widget.onVariantSelected(v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;
    final quantity = widget.quantity;
    final selectedVariant = widget.selectedVariant;
    final hasVariants = product.variants.isNotEmpty;
    final price = selectedVariant != null
        ? (selectedVariant.salePrice < selectedVariant.regularPrice
            ? selectedVariant.salePrice
            : selectedVariant.regularPrice)
        : product.salePrice < product.regularPrice
            ? product.salePrice
            : product.regularPrice;
    final canAddToCart = !hasVariants || selectedVariant != null;
    final galleryUrls = selectedVariant != null && selectedVariant.displayImageUrls.isNotEmpty
        ? selectedVariant.displayImageUrls
        : product.displayImageUrls;
    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;

    return SingleChildScrollView(
      controller: _scrollController,
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
                if (hasVariants) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Choose option',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: _variantError
                          ? Border.all(color: theme.colorScheme.error, width: 2)
                          : null,
                    ),
                    child: _VariantSelector(
                      variants: product.variants,
                      selectedVariant: selectedVariant,
                      onVariantSelected: _onVariantSelected,
                    ),
                  ),
                  if (_variantError) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Please select an option before continuing.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
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
                          ? () => widget.onQuantityChanged(quantity - 1)
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
                          ? () => widget.onQuantityChanged(quantity + 1)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (isLoggedIn)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _onBuyNowTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: _neonOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_buttonRadius),
                        ),
                      ),
                      child: const Text('Buy Now'),
                    ),
                  ),
                if (isLoggedIn) const SizedBox(height: 16),
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
                                  countryFilter: product.countryFilter,
                                  hasCustomerPhoto: product.customerPhoto,
                                  hasCustomisedTest: product.customisedTest,
                                  hasCustomisedShortTest: product.customisedShortTest,
                                  hasNote: product.note,
                                  hasSameDayBdayLoveLetter:
                                      product.sameDayBdayLoveLetter,
                                  noteFee: product.noteFee,
                                  sameDayBdayLoveLetterFee:
                                      product.sameDayBdayLoveLetterFee,
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
                if (isLoggedIn) ...[
                  const SizedBox(height: 24),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: _showReceiverForm
                        ? _ReceiverFormSection(
                            key: _formSectionKey,
                            product: product,
                            quantity: quantity,
                            selectedVariant: selectedVariant,
                            price: price,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
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

/// Receiver form section: same field arrangement as checkout. Used when Buy Now is clicked.
/// Continue to Pay triggers direct SprintPay (create order + payment sheet), no checkout navigation.
class _ReceiverFormSection extends StatefulWidget {
  const _ReceiverFormSection({
    super.key,
    required this.product,
    required this.quantity,
    required this.selectedVariant,
    required this.price,
  });

  final ProductDetail product;
  final int quantity;
  final ProductVariant? selectedVariant;
  final double price;

  @override
  State<_ReceiverFormSection> createState() => _ReceiverFormSectionState();
}

class _ReceiverFormSectionState extends State<_ReceiverFormSection> {
  final _formKey = GlobalKey<FormState>();
  final _firstname = TextEditingController();
  final _lastname = TextEditingController();
  final _address = TextEditingController();
  final _apt = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  final _mobile = TextEditingController();
  final _receiverPhone = TextEditingController();
  final _email = TextEditingController();
  final _customisedTest = TextEditingController();
  final _customisedShortTest = TextEditingController();
  final _noteToSeller = TextEditingController();
  final _loveLetter = TextEditingController();

  List<CountryEntry> _countries = [];
  List<StateEntry> _states = [];
  CountryEntry? _selectedCountry;
  StateEntry? _selectedState;
  String? _countryError;
  String? _stateError;
  bool _loading = false;
  bool _userContactPrefilled = false;
  XFile? _frontPhoto;
  XFile? _backPhoto;
  static final _imagePicker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_userContactPrefilled && mounted) {
      _userContactPrefilled = true;
      final email = context.read<AuthProvider>().userEmail;
      if (email != null && email.isNotEmpty) _email.text = email;
    }
  }

  @override
  void initState() {
    super.initState();
    CheckoutData.getCountriesFiltered(widget.product.countryFilter).then((list) {
      if (mounted) setState(() => _countries = list);
    });
  }

  @override
  void dispose() {
    _firstname.dispose();
    _lastname.dispose();
    _address.dispose();
    _apt.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    _mobile.dispose();
    _receiverPhone.dispose();
    _email.dispose();
    _customisedTest.dispose();
    _customisedShortTest.dispose();
    _noteToSeller.dispose();
    _loveLetter.dispose();
    super.dispose();
  }

  Future<void> _onCountryChanged(CountryEntry? c) async {
    setState(() {
      _selectedCountry = c;
      _selectedState = null;
      _countryError = null;
      _stateError = null;
      _states = [];
    });
    if (c != null && (c.code == 'US' || c.code == 'CA')) {
      final list = await CheckoutData.getStatesForCountry(c.code);
      if (mounted) setState(() => _states = list);
    }
  }

  bool get _isVariantValid =>
      widget.product.variants.isEmpty || widget.selectedVariant != null;

  Future<void> _continueToPayment() async {
    if (!_isVariantValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an option before continuing.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _countryError = null);
    if (_selectedCountry == null) {
      setState(() => _countryError = 'Required');
      return;
    }
    if ((_selectedCountry!.code == 'US' || _selectedCountry!.code == 'CA') &&
        _selectedState == null) {
      setState(() => _stateError = 'Required');
      return;
    }
    if (widget.product.customisedTest && _customisedTest.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter customized text')),
      );
      return;
    }
    if (widget.product.customisedShortTest &&
        _customisedShortTest.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter customized short text (max 40 characters)')),
      );
      return;
    }
    if (widget.product.customerPhoto && (_frontPhoto == null || _backPhoto == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both front and back product photos')),
      );
      return;
    }
    if (widget.product.sameDayBdayLoveLetter && _loveLetter.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write your love letter')),
      );
      return;
    }
    if (_loading) return;
    setState(() => _loading = true);
    final api = context.read<ApiService>();
    String? frontPath;
    String? backPath;
    if (widget.product.customerPhoto && _frontPhoto != null && _backPhoto != null) {
      final uploadRes = await api.uploadCustomerPhotos(
        frontPath: _frontPhoto!.path,
        backPath: _backPhoto!.path,
      );
      if (!uploadRes.success || uploadRes.data == null) {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(uploadRes.error ?? 'Photo upload failed'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      frontPath = uploadRes.data!.frontPath;
      backPath = uploadRes.data!.backPath;
    }
    final shipRes = await api.getShippingMethods();
    if (!mounted) {
      setState(() => _loading = false);
      return;
    }
    if (!shipRes.success || shipRes.data == null || shipRes.data!.isEmpty) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shipRes.error ?? 'Could not load delivery options'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final noteText = _noteToSeller.text.trim();
    final noteCharge = (widget.product.note && noteText.isNotEmpty)
        ? widget.product.noteFee.round()
        : 0;
    final loveLetterText = _loveLetter.text.trim();
    final extras = CheckoutExtras(
      noteToSeller: noteText.isEmpty ? null : noteText,
      noteCharge: noteCharge,
      loveLetter: loveLetterText.isEmpty ? null : loveLetterText,
      customisedTest: _customisedTest.text.trim().isEmpty
          ? null
          : _customisedTest.text.trim(),
      customisedShortTest: _customisedShortTest.text.trim().isEmpty
          ? null
          : _customisedShortTest.text.trim(),
    );
    final receiverPhone = _receiverPhone.text.trim();
    final address = ShippingAddressInput(
      firstname: _firstname.text.trim(),
      lastname: _lastname.text.trim(),
      mobile: receiverPhone.isNotEmpty ? receiverPhone : _mobile.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      country: _selectedCountry!.name,
      city: _city.text.trim(),
      state: _selectedState?.name ??
          (_state.text.trim().isEmpty ? null : _state.text.trim()),
      zip: _zip.text.trim().isEmpty ? null : _zip.text.trim(),
      address: _address.text.trim(),
      apt: _apt.text.trim().isEmpty ? null : _apt.text.trim(),
    );
    final item = CartItem(
      productId: widget.product.id,
      variantId: widget.selectedVariant?.id,
      name: widget.product.name,
      price: widget.price,
      imageUrl: widget.selectedVariant?.imageUrl ??
          widget.product.thumbUrl ??
          widget.product.imageUrl,
      currency: widget.product.currency,
      quantity: widget.quantity,
      countryFilter: widget.product.countryFilter,
      hasCustomerPhoto: widget.product.customerPhoto,
      hasCustomisedTest: widget.product.customisedTest,
      hasCustomisedShortTest: widget.product.customisedShortTest,
      hasNote: widget.product.note,
      hasSameDayBdayLoveLetter: widget.product.sameDayBdayLoveLetter,
      noteFee: widget.product.noteFee,
      sameDayBdayLoveLetterFee: widget.product.sameDayBdayLoveLetterFee,
    );
    final orderRes = await api.createOrder(
      items: [item],
      shippingAddress: address,
      shippingMethodId: shipRes.data!.first.id,
      noteToSeller: extras.noteToSeller,
      noteCharge: extras.noteCharge,
      loveLetter: extras.loveLetter,
      customisedTest: extras.customisedTest,
      customisedShortTest: extras.customisedShortTest,
      frontPhoto: frontPath,
      backPhoto: backPath,
    );
    if (!mounted) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = false);
    if (!orderRes.success || orderRes.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderRes.error ?? 'Failed to create order'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final orderData = orderRes.data!;
    await showSprintPayDirectFlow(
      context,
      amount: orderData.totalAmount,
      ref: orderData.orderNumber,
      email: _email.text.trim(),
      orderId: orderData.orderId,
      orderNumber: orderData.orderNumber,
      onOrderSuccess: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.product;
    final showStateDropdown = _selectedCountry != null &&
        (_selectedCountry!.code == 'US' || _selectedCountry!.code == 'CA');

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 32, color: theme.dividerColor),
          Text(
            'Your contact',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(
              labelText: 'Email *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _mobile,
            decoration: const InputDecoration(
              labelText: 'WhatsApp / Phone *',
              hintText: 'Your WhatsApp or phone number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 24),
          Text(
            "Receiver's Details",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SearchableDropdown<CountryEntry>(
            items: _countries,
            label: 'Country / Region *',
            displayString: (c) => c.name,
            value: _selectedCountry,
            onChanged: _onCountryChanged,
            hint: 'Search country...',
            errorText: _countryError,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _firstname,
            decoration: const InputDecoration(
              labelText: "Receiver's First name",
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastname,
            decoration: const InputDecoration(
              labelText: "Receiver's Last name",
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _address,
            decoration: const InputDecoration(
              labelText: 'Street address',
              hintText: 'House number and street name',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _apt,
            decoration: const InputDecoration(
              labelText: 'Apartment, suite, unit (optional)',
              hintText: 'House number, apartment, suite, unit, flat etc',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (showStateDropdown)
            SearchableDropdown<StateEntry>(
              items: _states,
              label: _selectedCountry!.code == 'US' ? 'State / County *' : 'Province / Territory *',
              displayString: (s) => s.name,
              value: _selectedState,
              onChanged: (v) => setState(() {
                _selectedState = v;
                _stateError = null;
              }),
              hint: 'Select',
              errorText: _stateError,
            )
          else if (_selectedCountry != null)
            TextFormField(
              controller: _state,
              decoration: const InputDecoration(
                labelText: 'State / County',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          if (showStateDropdown || _selectedCountry != null) const SizedBox(height: 12),
          TextFormField(
            controller: _city,
            decoration: const InputDecoration(
              labelText: 'Town / City',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _zip,
            decoration: const InputDecoration(
              labelText: 'Postcode / ZIP',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _receiverPhone,
            decoration: const InputDecoration(
              labelText: "Receiver's phone (optional)",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          if (p.customerPhoto) ...[
            const SizedBox(height: 24),
            Text(
              'Upload Customized Product Photo',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'JPG or PNG, max 2MB each.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Front', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final x = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                          if (x != null && mounted) setState(() => _frontPhoto = x);
                        },
                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                        label: Text(_frontPhoto == null ? 'Add front' : 'Change'),
                      ),
                      if (_frontPhoto != null) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(_frontPhoto!.path), height: 80, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Back', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final x = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                          if (x != null && mounted) setState(() => _backPhoto = x);
                        },
                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                        label: Text(_backPhoto == null ? 'Add back' : 'Change'),
                      ),
                      if (_backPhoto != null) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(_backPhoto!.path), height: 80, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (p.customisedTest) ...[
            const SizedBox(height: 24),
            Text(
              'Customized Text',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _customisedTest,
              decoration: const InputDecoration(
                hintText: 'Enter your note here...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 5000,
            ),
          ],
          if (p.customisedShortTest) ...[
            const SizedBox(height: 24),
            Text(
              'Customized Short Text (40)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _customisedShortTest,
              decoration: const InputDecoration(
                hintText: 'Enter your short note here...',
                border: OutlineInputBorder(),
              ),
              maxLength: 40,
            ),
          ],
          if (p.note) ...[
            const SizedBox(height: 24),
            Text(
              'Note to Seller',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteToSeller,
              decoration: const InputDecoration(
                hintText: 'Enter your note here...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 250,
            ),
            const SizedBox(height: 4),
            Text(
              'Note: Additional fee of ${formatNiara(widget.product.noteFee)} will be added.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (p.sameDayBdayLoveLetter) ...[
            const SizedBox(height: 24),
            Text(
              'Love Letter',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Write the birthday / love letter that will go with this gift.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _loveLetter,
              decoration: const InputDecoration(
                hintText: 'Write your love letter here...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 2000,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Love letter is required' : null,
            ),
            if (widget.product.sameDayBdayLoveLetterFee > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Same Day Bday & love letter fee of ${formatNiara(widget.product.sameDayBdayLoveLetterFee)} will be added.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: (_loading || !_isVariantValid) ? null : _continueToPayment,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _neonOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_buttonRadius),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Continue to Pay'),
            ),
          ),
        ],
      ),
    );
  }
}
