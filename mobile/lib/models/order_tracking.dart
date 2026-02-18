/// Order status values matching backend Status constants.
const int orderStatusPending = 0;
const int orderStatusProcessing = 1;
const int orderStatusDispatched = 2;
const int orderStatusDelivered = 3;
const int orderStatusCanceled = 4;
const int orderStatusReturned = 9;

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
    final rawStatus = json['status'];
    int? statusInt;
    if (rawStatus != null) {
      if (rawStatus is int) {
        statusInt = rawStatus;
      } else if (rawStatus is num) {
        statusInt = rawStatus.toInt();
      } else {
        statusInt = int.tryParse(rawStatus.toString());
      }
    }
    return OrderTrackingResult(
      success: _boolFromJson(json['success']) ?? false,
      error: json['error'] as String?,
      orderNumber: json['order_number'] as String?,
      paymentStatus: json['payment_status'],
      status: statusInt,
      isCod: _boolFromJson(json['is_cod']),
      estimatedDeliveryAt: _stringFromJson(json['estimated_delivery_at']),
      trackingUrl: _stringFromJson(json['tracking_url']),
      trackingNumber: _stringFromJson(json['tracking_number']),
    );
  }

  final bool success;
  final String? error;
  final String? orderNumber;
  final dynamic paymentStatus;
  /// Order status: 0=Pending, 1=Processing, 2=Dispatched, 3=Delivered, 4=Canceled, 9=Returned.
  final int? status;
  final bool? isCod;
  final String? estimatedDeliveryAt;
  final String? trackingUrl;
  final String? trackingNumber;

  bool get isCanceled => status == orderStatusCanceled;
  bool get isReturned => status == orderStatusReturned;
}

String? _stringFromJson(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  return value.toString();
}

bool? _boolFromJson(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is num) return value.toInt() != 0;
  return null;
}
