import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../data/checkout_data.dart';
import '../models/cart_item.dart';
import '../models/checkout_models.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../utils/format_utils.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/sprintpay_payment_sheet.dart';
import '../ui/login/login_screen.dart';
import 'track_order_screen.dart';

/// Checkout flow matching web: shipping info → shipping method → place order → payment method → pay.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  /// Call this when user taps checkout. If logged in, go straight to checkout;
  /// otherwise ask guest or login.
  static void showCheckoutChoice(BuildContext context) {
    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
    if (isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CheckoutScreen()),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Checkout'),
        content: const Text(
          'Would you like to continue as a guest or log in to your account?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CheckoutScreen()),
              );
            },
            child: const Text('Continue as guest'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              ).then((_) {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                  );
                }
              });
            },
            child: const Text('Log in'),
          ),
        ],
      ),
    );
  }

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const int _stepShipping = 0;
  static const int _stepShippingMethod = 1;
  static const int _stepPaymentMethod = 2;

  int _step = _stepShipping;
  final _formKey = GlobalKey<FormState>();
  final _firstname = TextEditingController();
  final _lastname = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _address = TextEditingController();
  final _apt = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  final _country = TextEditingController();
  final _customisedTest = TextEditingController();
  final _customisedShortTest = TextEditingController();
  final _noteToSeller = TextEditingController();

  CheckoutExtras? _extras;
  XFile? _frontPhoto;
  XFile? _backPhoto;
  static final _imagePicker = ImagePicker();

  List<CountryEntry> _countries = [];
  List<StateEntry> _states = [];
  CountryEntry? _selectedCountry;
  StateEntry? _selectedState;
  String? _countryError;
  String? _stateError;

  List<ShippingMethodItem> _shippingMethods = [];
  List<PaymentMethodItem> _paymentMethods = [];
  ShippingMethodItem? _selectedShipping;
  PaymentMethodItem? _selectedPayment;
  CreateOrderResult? _orderResult;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCountryData();
  }

  /// Effective country filter from cart: usa_only > usa_canada > all.
  static String? _effectiveCountryFilter(List<CartItem> items) {
    if (items.isEmpty) return null;
    if (items.any((i) => i.countryFilter == 'usa_only')) return 'usa_only';
    if (items.any((i) => i.countryFilter == 'usa_canada')) return 'usa_canada';
    return null;
  }

  Future<void> _loadCountryData() async {
    final filter = _effectiveCountryFilter(context.read<CartProvider>().items);
    final list = await CheckoutData.getCountriesFiltered(filter);
    if (!mounted) return;
    setState(() => _countries = list);
    _applyRouteArguments();
    if (_selectedCountry != null && (_selectedCountry!.code == 'US' || _selectedCountry!.code == 'CA')) {
      final stateList = await CheckoutData.getStatesForCountry(_selectedCountry!.code);
      if (mounted) setState(() => _states = stateList);
    }
  }

  void _applyRouteArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map<String, dynamic>) return;
    final prefilled = args['prefilled'] as Map<String, dynamic>?;
    if (prefilled != null) {
      if (prefilled['firstname'] is String) _firstname.text = prefilled['firstname'] as String;
      if (prefilled['lastname'] is String) _lastname.text = prefilled['lastname'] as String;
      if (prefilled['email'] is String) _email.text = prefilled['email'] as String;
      if (prefilled['mobile'] is String) _mobile.text = prefilled['mobile'] as String;
      if (prefilled['address'] is String) _address.text = prefilled['address'] as String;
      if (prefilled['apt'] is String) _apt.text = prefilled['apt'] as String;
      if (prefilled['city'] is String) _city.text = prefilled['city'] as String;
      if (prefilled['state'] is String) _state.text = prefilled['state'] as String;
      if (prefilled['zip'] is String) _zip.text = prefilled['zip'] as String;
      final countryName = prefilled['country'] as String?;
      if (countryName != null && countryName.isNotEmpty && _countries.isNotEmpty) {
        CountryEntry? c;
        for (final e in _countries) {
          if (e.name == countryName) { c = e; break; }
        }
        if (c != null) {
          _selectedCountry = c;
          _country.text = c.name;
        }
      }
      if (prefilled['customised_test'] is String) _customisedTest.text = prefilled['customised_test'] as String;
      if (prefilled['customised_short_test'] is String) _customisedShortTest.text = prefilled['customised_short_test'] as String;
      if (prefilled['note_to_seller'] is String) _noteToSeller.text = prefilled['note_to_seller'] as String;
    }
    final extras = args['extras'] as CheckoutExtras?;
    if (extras != null) _extras = extras;
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

  @override
  void dispose() {
    _firstname.dispose();
    _lastname.dispose();
    _email.dispose();
    _mobile.dispose();
    _address.dispose();
    _apt.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    _country.dispose();
    _customisedTest.dispose();
    _customisedShortTest.dispose();
    _noteToSeller.dispose();
    super.dispose();
  }

  bool get _hasApiKey =>
      ApiConfig.apiKey != null && ApiConfig.apiKey!.trim().isNotEmpty;

  bool _isAuthError(String? message) {
    if (message == null || message.isEmpty) return false;
    final lower = message.toLowerCase();
    return lower.contains('api key') ||
        lower.contains('log in') ||
        lower.contains('login') ||
        lower.contains('unauthorized') ||
        lower.contains('authenticate');
  }

  void _showLoginRequired() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Checkout'),
        content: const Text(
          'Please log in to continue checkout.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('Log in'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadShippingMethods() async {
    if (!_hasApiKey) {
      _showLoginRequired();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = context.read<ApiService>();
    final res = await api.getShippingMethods();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data != null) {
        _shippingMethods = res.data!;
        _selectedShipping =
            _shippingMethods.isNotEmpty ? _shippingMethods.first : null;
        _step = _stepShippingMethod;
      } else {
        _error = res.error ?? 'Failed to load delivery options';
      }
    });
  }

  /// Validate form, load shipping, place order, then go to payment step (SprintPay) so user can pay.
  Future<void> _proceedToPayment() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _countryError = null;
      _stateError = null;
    });
    if (_selectedCountry == null) {
      setState(() => _countryError = 'Required');
      return;
    }
    if ((_selectedCountry!.code == 'US' || _selectedCountry!.code == 'CA') &&
        _selectedState == null) {
      setState(() => _stateError = 'Required');
      return;
    }
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      setState(() => _error = 'Your cart is empty');
      return;
    }
    if (cart.items.any((i) => i.hasCustomisedTest) && _customisedTest.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter customized text')),
      );
      return;
    }
    if (cart.items.any((i) => i.hasCustomisedShortTest) && _customisedShortTest.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter customized short text (max 40 characters)')),
      );
      return;
    }
    if (cart.items.any((i) => i.hasCustomerPhoto) && (_frontPhoto == null || _backPhoto == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both front and back product photos')),
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = context.read<ApiService>();
    String? frontPath;
    String? backPath;
    if (cart.items.any((i) => i.hasCustomerPhoto) && _frontPhoto != null && _backPhoto != null) {
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
    // 1) Load shipping methods and use first
    final shipRes = await api.getShippingMethods();
    if (!mounted) return;
    if (!shipRes.success || shipRes.data == null || shipRes.data!.isEmpty) {
      setState(() => _loading = false);
      if (_isAuthError(shipRes.error)) {
        _showLoginRequired();
      } else {
        setState(() => _error = shipRes.error ?? 'Failed to load delivery options');
      }
      return;
    }
    _shippingMethods = shipRes.data!;
    _selectedShipping = _shippingMethods.first;
    // 2) Place order
    final address = ShippingAddressInput(
      firstname: _firstname.text.trim(),
      lastname: _lastname.text.trim(),
      mobile: _mobile.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      country: _selectedCountry?.name ?? _country.text.trim(),
      city: _city.text.trim(),
      state: _selectedState?.name ?? (_state.text.trim().isEmpty ? null : _state.text.trim()),
      zip: _zip.text.trim().isEmpty ? null : _zip.text.trim(),
      address: _address.text.trim(),
      apt: _apt.text.trim().isEmpty ? null : _apt.text.trim(),
    );
    final effectiveExtras = _extras ?? CheckoutExtras(
      noteToSeller: _noteToSeller.text.trim().isEmpty ? null : _noteToSeller.text.trim(),
      noteCharge: cart.items.any((i) => i.hasNote) && _noteToSeller.text.trim().isNotEmpty ? 5000 : 0,
      customisedTest: _customisedTest.text.trim().isEmpty ? null : _customisedTest.text.trim(),
      customisedShortTest: _customisedShortTest.text.trim().isEmpty ? null : _customisedShortTest.text.trim(),
    );
    final orderRes = await api.createOrder(
      items: cart.items,
      shippingAddress: address,
      shippingMethodId: _selectedShipping!.id,
      noteToSeller: effectiveExtras.noteToSeller,
      noteCharge: effectiveExtras.noteCharge,
      customisedTest: effectiveExtras.customisedTest,
      customisedShortTest: effectiveExtras.customisedShortTest,
      frontPhoto: frontPath,
      backPhoto: backPath,
    );
    if (!mounted) return;
    if (!orderRes.success || orderRes.data == null) {
      setState(() => _loading = false);
      if (_isAuthError(orderRes.error)) {
        _showLoginRequired();
      } else {
        setState(() => _error = orderRes.error ?? 'Failed to create order');
      }
      return;
    }
    _orderResult = orderRes.data;
    _error = null;
    if (!mounted) return;
    // Must call /api/payment/initiate so a Deposit exists; SprintPay ref must match deposit.trx for IPN.
    final orderData = orderRes.data!;
    final userEmail = _email.text.trim();
    if (userEmail.isEmpty) {
      setState(() => _loading = false);
      setState(() => _error = 'Email is required for payment');
      return;
    }
    final methodsRes = await api.getPaymentMethods();
    if (!mounted) return;
    if (!methodsRes.success || methodsRes.data == null || methodsRes.data!.isEmpty) {
      setState(() {
        _loading = false;
        _error = methodsRes.error ?? 'Could not load payment methods';
      });
      return;
    }
    PaymentMethodItem? sprintOrEnkpay;
    for (final m in methodsRes.data!) {
      final n = m.name.toLowerCase();
      if (n.contains('sprintpay') || n.contains('enkpay')) {
        sprintOrEnkpay = m;
        break;
      }
    }
    sprintOrEnkpay ??= methodsRes.data!.first;
    final initRes = await api.initiatePayment(
      orderId: orderData.orderId,
      gateway: sprintOrEnkpay.methodCode == 0 ? 0 : sprintOrEnkpay.id,
      currency: sprintOrEnkpay.currency,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!initRes.success || initRes.data == null) {
      setState(() => _error = initRes.error ?? 'Could not start payment');
      return;
    }
    final payData = initRes.data!;
    if (payData.paymentUrl == null || payData.paymentUrl!.isEmpty) {
      setState(() => _error = 'No payment URL returned');
      return;
    }
    final usedSheet = await showSprintPayPaymentFlow(
      context,
      paymentUrl: payData.paymentUrl!,
      orderId: payData.orderId,
      orderNumber: payData.orderNumber,
      onOrderSuccess: () => context.read<CartProvider>().clear(),
    );
    if (!mounted) return;
    if (usedSheet) return;
    final uri = Uri.tryParse(payData.paymentUrl!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!mounted) return;
    context.read<CartProvider>().clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Complete payment in the browser. Order: ${payData.orderNumber}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).popUntil((r) => r.isFirst);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackOrderScreen(orderNumber: payData.orderNumber),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!_hasApiKey) {
      _showLoginRequired();
      return;
    }
    if (_selectedShipping == null) return;
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      setState(() => _error = 'Your cart is empty');
      return;
    }
    if (cart.items.any((i) => i.hasCustomerPhoto) && (_frontPhoto == null || _backPhoto == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both front and back product photos')),
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = context.read<ApiService>();
    String? frontPath;
    String? backPath;
    if (cart.items.any((i) => i.hasCustomerPhoto) && _frontPhoto != null && _backPhoto != null) {
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
    final address = ShippingAddressInput(
      firstname: _firstname.text.trim(),
      lastname: _lastname.text.trim(),
      mobile: _mobile.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      country: _selectedCountry?.name ?? _country.text.trim(),
      city: _city.text.trim(),
      state: _selectedState?.name ?? (_state.text.trim().isEmpty ? null : _state.text.trim()),
      zip: _zip.text.trim().isEmpty ? null : _zip.text.trim(),
      address: _address.text.trim(),
      apt: _apt.text.trim().isEmpty ? null : _apt.text.trim(),
    );
    final effectiveExtras = _extras ?? CheckoutExtras(
      noteToSeller: _noteToSeller.text.trim().isEmpty ? null : _noteToSeller.text.trim(),
      noteCharge: cart.items.any((i) => i.hasNote) && _noteToSeller.text.trim().isNotEmpty ? 5000 : 0,
      customisedTest: _customisedTest.text.trim().isEmpty ? null : _customisedTest.text.trim(),
      customisedShortTest: _customisedShortTest.text.trim().isEmpty ? null : _customisedShortTest.text.trim(),
    );
    final res = await api.createOrder(
      items: cart.items,
      shippingAddress: address,
      shippingMethodId: _selectedShipping!.id,
      noteToSeller: effectiveExtras.noteToSeller,
      noteCharge: effectiveExtras.noteCharge,
      customisedTest: effectiveExtras.customisedTest,
      customisedShortTest: effectiveExtras.customisedShortTest,
      frontPhoto: frontPath,
      backPhoto: backPath,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data != null) {
        _orderResult = res.data;
        _step = _stepPaymentMethod;
        _error = null;
        _loadPaymentMethods();
      } else {
        _error = res.error ?? 'Failed to create order';
      }
    });
  }

  Future<void> _loadPaymentMethods() async {
    if (!_hasApiKey) {
      _showLoginRequired();
      return;
    }
    setState(() => _loading = true);
    final api = context.read<ApiService>();
    final res = await api.getPaymentMethods();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data != null) {
        _paymentMethods = res.data!;
        PaymentMethodItem? sprintPay;
        for (final m in _paymentMethods) {
          if (m.name.toLowerCase().contains('sprintpay')) {
            sprintPay = m;
            break;
          }
        }
        _selectedPayment = sprintPay ?? (_paymentMethods.isNotEmpty ? _paymentMethods.first : null);
      }
    });
  }

  Future<void> _pay() async {
    if (!_hasApiKey) {
      _showLoginRequired();
      return;
    }
    if (_orderResult == null || _selectedPayment == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = context.read<ApiService>();
    final res = await api.initiatePayment(
      orderId: _orderResult!.orderId,
      gateway: _selectedPayment!.methodCode == 0 ? 0 : _selectedPayment!.id,
      currency: _selectedPayment!.currency,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!res.success) {
      setState(() => _error = res.error ?? 'Payment failed');
      return;
    }
    final data = res.data!;
    if (data.paymentUrl != null && data.paymentUrl!.isNotEmpty) {
      final usedSheet = await showSprintPayPaymentFlow(
        context,
        paymentUrl: data.paymentUrl!,
        orderId: data.orderId,
        orderNumber: data.orderNumber,
        onOrderSuccess: () => context.read<CartProvider>().clear(),
      );
      if (!mounted) return;
      if (usedSheet) return;
      final uri = Uri.tryParse(data.paymentUrl!);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      context.read<CartProvider>().clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complete payment in the browser. Order: ${data.orderNumber}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      final orderNum = data.orderNumber;
      Navigator.of(context).popUntil((r) => r.isFirst);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrackOrderScreen(orderNumber: orderNum),
        ),
      );
    } else {
      context.read<CartProvider>().clear();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Order placed'),
          content: Text(
            'Your order ${data.orderNumber} has been placed successfully.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).popUntil((r) => r.isFirst);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TrackOrderScreen(orderNumber: data.orderNumber),
                  ),
                );
              },
              child: const Text('Track order'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _body(theme),
    );
  }

  Widget _body(ThemeData theme) {
    if (_loading && _shippingMethods.isEmpty && _paymentMethods.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step indicator (web: Shipping info → Payment redirect)
            Row(
              children: [
                _stepChip(theme, 1, 'Shipping', true),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 16, color: theme.colorScheme.outline),
                ),
                _stepChip(theme, 2, 'Payment', _step != _stepShipping),
              ],
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
              ),
              const SizedBox(height: 16),
            ],
            if (_step == _stepShipping) ...[
              Text(
                'Shipping information',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _shippingForm(theme),
            ],
            if (_step == _stepShippingMethod) _shippingMethodStep(theme),
            if (_step == _stepPaymentMethod) _paymentStep(theme),
          ],
        ),
      ),
    );
  }

  Widget _stepChip(ThemeData theme, int step, String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$step. $label',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  List<Widget> _buildExtraOptionSections(ThemeData theme) {
    final cart = context.read<CartProvider>();
    final showCustomisedTest = cart.items.any((i) => i.hasCustomisedTest);
    final showCustomisedShortTest = cart.items.any((i) => i.hasCustomisedShortTest);
    final showNote = cart.items.any((i) => i.hasNote);
    final showCustomerPhoto = cart.items.any((i) => i.hasCustomerPhoto);
    final list = <Widget>[];
    if (showCustomerPhoto) {
      list.addAll([
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
      ]);
    }
    if (showCustomisedTest) {
      list.addAll([
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
      ]);
    }
    if (showCustomisedShortTest) {
      list.addAll([
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
      ]);
    }
    if (showNote) {
      list.addAll([
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
          'Note: Additional fee of ₦5,000 will be added.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ]);
    }
    return list;
  }

  Widget _shippingForm(ThemeData theme) {
    final showStateDropdown = _selectedCountry != null &&
        (_selectedCountry!.code == 'US' || _selectedCountry!.code == 'CA');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          controller: _mobile,
          decoration: const InputDecoration(
            labelText: "Receiver's phone (optional)",
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _email,
          decoration: const InputDecoration(
            labelText: 'Email (optional)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        ..._buildExtraOptionSections(theme),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _proceedToPayment,
          child: _loading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Proceed to payment'),
        ),
      ],
    );
  }

  Widget _shippingMethodStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Delivery method',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._shippingMethods.map((m) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RadioListTile<int>(
              title: Text(m.name),
              subtitle: Text(formatNiara(m.charge)),
              value: m.id,
              groupValue: _selectedShipping?.id,
              onChanged: (v) => setState(() {
                _selectedShipping = _shippingMethods.firstWhere((x) => x.id == v);
              }),
            ),
          );
        }),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _placeOrder,
          child: _loading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Place order'),
        ),
      ],
    );
  }

  Widget _paymentStep(ThemeData theme) {
    final order = _orderResult;
    if (order == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Order ${order.orderNumber}',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Total: ${formatNiara(order.totalAmount)}'),
        const SizedBox(height: 20),
        Text(
          'Payment method',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ..._paymentMethods.map((m) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RadioListTile<int>(
              title: Text(m.name),
              value: m.id,
              groupValue: _selectedPayment?.id,
              onChanged: (v) => setState(() {
                _selectedPayment = _paymentMethods.firstWhere((x) => x.id == v);
              }),
            ),
          );
        }),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _pay,
          child: _loading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Pay now'),
        ),
      ],
    );
  }
}
