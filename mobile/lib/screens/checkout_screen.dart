import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../models/checkout_models.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../utils/format_utils.dart';
import 'track_order_screen.dart';

/// Checkout flow matching web: shipping info → shipping method → place order → payment method → pay.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

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
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  final _country = TextEditingController();

  List<ShippingMethodItem> _shippingMethods = [];
  List<PaymentMethodItem> _paymentMethods = [];
  ShippingMethodItem? _selectedShipping;
  PaymentMethodItem? _selectedPayment;
  CreateOrderResult? _orderResult;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _firstname.dispose();
    _lastname.dispose();
    _email.dispose();
    _mobile.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    _country.dispose();
    super.dispose();
  }

  bool get _hasApiKey =>
      ApiConfig.apiKey != null && ApiConfig.apiKey!.trim().isNotEmpty;

  void _showApiKeyRequired() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Checkout'),
        content: const Text(
          'To place an order, you need an API key from the website dashboard (API Keys). '
          'Add it in the app configuration (api_config.dart) or in Settings if available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadShippingMethods() async {
    if (!_hasApiKey) {
      _showApiKeyRequired();
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

  Future<void> _placeOrder() async {
    if (!_hasApiKey) {
      _showApiKeyRequired();
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
      country: _country.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim().isEmpty ? null : _state.text.trim(),
      zip: _zip.text.trim().isEmpty ? null : _zip.text.trim(),
      address: _address.text.trim(),
    );
    final api = context.read<ApiService>();
    final res = await api.createOrder(
      items: cart.items,
      shippingAddress: address,
      shippingMethodId: _selectedShipping!.id,
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
    if (!_hasApiKey) return;
    setState(() => _loading = true);
    final api = context.read<ApiService>();
    final res = await api.getPaymentMethods();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data != null) {
        _paymentMethods = res.data!;
        _selectedPayment =
            _paymentMethods.isNotEmpty ? _paymentMethods.first : null;
      }
    });
  }

  Future<void> _pay() async {
    if (!_hasApiKey || _orderResult == null || _selectedPayment == null) return;
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
      final uri = Uri.tryParse(data.paymentUrl!);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (!mounted) return;
      context.read<CartProvider>().clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complete payment in the browser. Order: ${data.orderNumber}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (!mounted) return;
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
      body: _hasApiKey ? _body(theme) : _apiKeyMessage(theme),
    );
  }

  Widget _apiKeyMessage(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'API key required',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'To checkout, add your API key from the website dashboard (API Keys) in the app config.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to cart'),
            ),
          ],
        ),
      ),
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
            if (_step == _stepShipping) _shippingForm(theme),
            if (_step == _stepShippingMethod) _shippingMethodStep(theme),
            if (_step == _stepPaymentMethod) _paymentStep(theme),
          ],
        ),
      ),
    );
  }

  Widget _shippingForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          controller: _email,
          decoration: const InputDecoration(
            labelText: "Email (optional)",
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _mobile,
          decoration: const InputDecoration(
            labelText: "Phone *",
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
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
          controller: _city,
          decoration: const InputDecoration(
            labelText: "Town / City",
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _state,
          decoration: const InputDecoration(
            labelText: "State / County",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _zip,
          decoration: const InputDecoration(
            labelText: "Postcode / ZIP",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _country,
          decoration: const InputDecoration(
            labelText: "Country",
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading
              ? null
              : () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _loadShippingMethods();
                  }
                },
          child: _loading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Continue to delivery'),
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
