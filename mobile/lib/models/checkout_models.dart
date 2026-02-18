/// Active shipping method for checkout.
class ShippingMethodItem {
  ShippingMethodItem({
    required this.id,
    required this.name,
    required this.charge,
  });

  factory ShippingMethodItem.fromJson(Map<String, dynamic> json) {
    return ShippingMethodItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? 'Delivery',
      charge: (json['charge'] as num?)?.toDouble() ?? 0,
    );
  }

  final int id;
  final String name;
  final double charge;
}

/// Payment method for checkout.
class PaymentMethodItem {
  PaymentMethodItem({
    required this.id,
    required this.methodCode,
    required this.name,
    required this.currency,
    this.symbol,
  });

  factory PaymentMethodItem.fromJson(Map<String, dynamic> json) {
    return PaymentMethodItem(
      id: (json['id'] as num).toInt(),
      methodCode: (json['method_code'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Payment',
      currency: json['currency'] as String? ?? 'NGN',
      symbol: json['symbol'] as String?,
    );
  }

  final int id;
  final int methodCode;
  final String name;
  final String currency;
  final String? symbol;
}

/// Shipping address for order creation (same fields as web).
class ShippingAddressInput {
  ShippingAddressInput({
    required this.firstname,
    required this.lastname,
    required this.mobile,
    required this.country,
    required this.city,
    required this.address,
    this.email,
    this.state,
    this.zip,
  });

  Map<String, dynamic> toJson() => {
        'firstname': firstname,
        'lastname': lastname,
        'mobile': mobile,
        'email': email,
        'country': country,
        'city': city,
        'state': state ?? '',
        'zip': zip ?? '',
        'address': address,
      };

  final String firstname;
  final String lastname;
  final String mobile;
  final String? email;
  final String country;
  final String city;
  final String? state;
  final String? zip;
  final String address;
}

/// Response after creating an order.
class CreateOrderResult {
  CreateOrderResult({
    required this.orderId,
    required this.orderNumber,
    required this.subtotal,
    required this.shippingCharge,
    required this.totalAmount,
  });

  factory CreateOrderResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return CreateOrderResult(
      orderId: (data['order_id'] as num).toInt(),
      orderNumber: data['order_number'] as String? ?? '',
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      shippingCharge: (data['shipping_charge'] as num?)?.toDouble() ?? 0,
      totalAmount: (data['total_amount'] as num?)?.toDouble() ?? 0,
    );
  }

  final int orderId;
  final String orderNumber;
  final double subtotal;
  final double shippingCharge;
  final double totalAmount;
}

/// Response after initiating payment.
class PaymentInitiateResult {
  PaymentInitiateResult({
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
    this.paymentUrl,
    this.trx,
  });

  factory PaymentInitiateResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return PaymentInitiateResult(
      orderId: (data['order_id'] as num?)?.toInt() ?? 0,
      orderNumber: data['order_number'] as String? ?? '',
      totalAmount: (data['total_amount'] as num?)?.toDouble() ?? 0,
      paymentUrl: data['payment_url'] as String?,
      trx: data['trx'] as String?,
    );
  }

  final int orderId;
  final String orderNumber;
  final double totalAmount;
  final String? paymentUrl;
  final String? trx;
}

/// SprintPay paynow?mode=api response (account details to show in-app).
class SprintPayAccountResponse {
  SprintPayAccountResponse({
    required this.status,
    required this.accountNo,
    required this.accountName,
    required this.bankName,
    required this.amount,
    required this.currency,
    required this.ref,
    required this.businessName,
    required this.verifyUrl,
  });

  factory SprintPayAccountResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return SprintPayAccountResponse(
      status: json['status'] == true,
      accountNo: data['account_no'] as String? ?? '',
      accountName: data['account_name'] as String? ?? '',
      bankName: data['bank_name'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? 'NGN',
      ref: data['ref'] as String? ?? '',
      businessName: data['business_name'] as String? ?? '',
      verifyUrl: data['verify_url'] as String? ?? '',
    );
  }

  final bool status;
  final String accountNo;
  final String accountName;
  final String bankName;
  final double amount;
  final String currency;
  final String ref;
  final String businessName;
  final String verifyUrl;
}
