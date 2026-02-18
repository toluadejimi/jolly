import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../data/checkout_data.dart';
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

  CheckoutExtras? _extras;

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

  Future<void> _loadCountryData() async {
    final list = await CheckoutData.getCountries();
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
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = context.read<ApiService>();
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
    final extras = _extras;
    final orderRes = await api.createOrder(
      items: cart.items,
      shippingAddress: address,
      shippingMethodId: _selectedShipping!.id,
      noteToSeller: extras?.noteToSeller,
      noteCharge: extras?.noteCharge ?? 0,
      customisedTest: extras?.customisedTest,
      customisedShortTest: extras?.customisedShortTest,
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
    // 3) Load payment methods, pick default (SprintPay), initiate and redirect to gateway (match web flow)
    final payListRes = await api.getPaymentMethods();
    if (!mounted) return;
    if (!payListRes.success || payListRes.data == null || payListRes.data!.isEmpty) {
      setState(() => _loading = false);
      if (_isAuthError(payListRes.error)) {
        _showLoginRequired();
      } else {
        setState(() => _error = payListRes.error ?? 'No payment method available');
      }
      return;
    }
    _paymentMethods = payListRes.data!;
    PaymentMethodItem? chosen;
    for (final m in _paymentMethods) {
      if (m.name.toLowerCase().contains('sprintpay')) {
        chosen = m;
        break;
      }
    }
    chosen ??= _paymentMethods.first;
    final payRes = await api.initiatePayment(
      orderId: _orderResult!.orderId,
      gateway: chosen.methodCode == 0 ? 0 : chosen.id,
      currency: chosen.currency,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!payRes.success || payRes.data == null) {
      setState(() => _loading = false);
      if (_isAuthError(payRes.error)) {
        _showLoginRequired();
      } else {
        setState(() => _error = payRes.error ?? 'Payment initiation failed');
      }
      return;
    }
    final data = payRes.data!;
    if (data.paymentUrl != null && data.paymentUrl!.isNotEmpty) {
      final usedSheet = await showSprintPayPaymentFlow(
        context,
        paymentUrl: data.paymentUrl!,
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
      Navigator.of(context).popUntil((r) => r.isFirst);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrackOrderScreen(orderNumber: data.orderNumber),
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
    setState(() {
      _loading = true;
      _error = null;
    });
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
    final extras = _extras;
    final api = context.read<ApiService>();
    final res = await api.createOrder(
      items: cart.items,
      shippingAddress: address,
      shippingMethodId: _selectedShipping!.id,
      noteToSeller: extras?.noteToSeller,
      noteCharge: extras?.noteCharge ?? 0,
      customisedTest: extras?.customisedTest,
      customisedShortTest: extras?.customisedShortTest,
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

  Widget _shippingForm(ThemeData theme) {
    final showStateDropdown = _selectedCountry != null &&
        (_selectedCountry!.code == 'US' || _selectedCountry!.code == 'CA');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 24),
        Text(
          "Receiver's details",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _firstname,
          decoration: const InputDecoration(
            labelText: "First name",
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _lastname,
          decoration: const InputDecoration(
            labelText: "Last name",
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _address,
          decoration: const InputDecoration(
            labelText: "Street address",
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _apt,
          decoration: const InputDecoration(
            labelText: "Apartment, suite, unit (optional)",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _city,
          decoration: const InputDecoration(
            labelText: "Town / City",
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        SearchableDropdown<CountryEntry>(
          items: _countries,
          label: 'Country *',
          displayString: (c) => c.name,
          value: _selectedCountry,
          onChanged: _onCountryChanged,
          hint: 'Search country...',
          errorText: _countryError,
        ),
        if (showStateDropdown) ...[
          const SizedBox(height: 12),
          SearchableDropdown<StateEntry>(
            items: _states,
            label: _selectedCountry!.code == 'US' ? 'State *' : 'Province / Territory *',
            displayString: (s) => s.name,
            value: _selectedState,
            onChanged: (v) => setState(() {
              _selectedState = v;
              _stateError = null;
            }),
            hint: 'Search...',
            errorText: _stateError,
          ),
        ] else if (_selectedCountry != null) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _state,
            decoration: const InputDecoration(
              labelText: "State / County (optional)",
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: _zip,
          decoration: const InputDecoration(
            labelText: "Postcode / ZIP",
            border: OutlineInputBorder(),
          ),
        ),
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
