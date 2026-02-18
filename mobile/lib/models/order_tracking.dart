class OrderTrackingResult {
  OrderTrackingResult({
    required this.success,
    this.error,
    this.orderNumber,
    this.paymentStatus,
    this.status,
    this.isCod,
    this.estimatedDeliveryAt,
    this.trackingUrl,
    this.trackingNumber,
  });

  factory OrderTrackingResult.fromJson(Map<String, dynamic> json) {
    return OrderTrackingResult(
      success: json['success'] as bool? ?? false,
      error: json['error'] as String?,
      orderNumber: json['order_number'] as String?,
      paymentStatus: json['payment_status'],
      status: json['status'],
      isCod: json['is_cod'] as bool?,
      estimatedDeliveryAt: json['estimated_delivery_at'] as String?,
      trackingUrl: json['tracking_url'] as String?,
      trackingNumber: json['tracking_number'] as String?,
    );
  }

  final bool success;
  final String? error;
  final String? orderNumber;
  final dynamic paymentStatus;
  final dynamic status;
  final bool? isCod;
  final String? estimatedDeliveryAt;
  final String? trackingUrl;
  final String? trackingNumber;
}
