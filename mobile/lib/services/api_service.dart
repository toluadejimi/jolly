import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/category.dart';
import '../models/checkout_models.dart';
import '../models/order_tracking.dart';
import '../models/product.dart';
import '../models/slider.dart';
import '../models/user_dashboard.dart';
import '../models/api_response.dart';
import '../models/auth_data.dart';
import '../models/cart_item.dart';

/// Set to true to print API request/response in the terminal (where `flutter run` is active).
const bool kLogApi = true;

void _logApi(String method, String url, {String? requestBody, int? statusCode, String? responseBody}) {
  if (!kLogApi || !kDebugMode) return;
  debugPrint('━━━━━━━━━━ API $method $url ━━━━━━━━━━');
  if (requestBody != null && requestBody.isNotEmpty) {
    final truncated = requestBody.length > 800 ? '${requestBody.substring(0, 800)}...' : requestBody;
    debugPrint('REQUEST BODY: $truncated');
  }
  if (statusCode != null) debugPrint('RESPONSE STATUS: $statusCode');
  if (responseBody != null && responseBody.isNotEmpty) {
    final truncated = responseBody.length > 1200 ? '${responseBody.substring(0, 1200)}...' : responseBody;
    debugPrint('RESPONSE BODY: $truncated');
  }
  debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}

class ApiService {
  ApiService({String? apiKey}) : _apiKey = apiKey ?? ApiConfig.apiKey;

  final String? _apiKey;
  String get baseUrl => ApiConfig.baseUrl.trim().replaceAll(RegExp(r'/$'), '');

  Map<String, String> get _publicHeaders => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Map<String, String> get _authHeaders {
    final m = Map<String, String>.from(_publicHeaders);
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      m['X-API-Key'] = _apiKey!;
      m['Authorization'] = 'Bearer $_apiKey';
    }
    return m;
  }

  /// POST /api/login (no auth). Returns api_key and user.
  Future<ApiResponse<AuthData>> login({required String username, required String password}) async {
    final body = jsonEncode({'username': username, 'password': password});
    _logApi('POST', '$baseUrl/api/login', requestBody: body);
    final res = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: _publicHeaders,
      body: body,
    );
    _logApi('POST', '$baseUrl/api/login', statusCode: res.statusCode, responseBody: res.body);
    return _parseAuthResponse(res);
  }

  /// POST /api/register (no auth). Returns api_key and user.
  Future<ApiResponse<AuthData>> register({
    required String email,
    required String password,
    required String passwordConfirmation,
    String? firstname,
    String? lastname,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (firstname != null && firstname.isNotEmpty) 'firstname': firstname,
      if (lastname != null && lastname.isNotEmpty) 'lastname': lastname,
    };
    final bodyStr = jsonEncode(body);
    _logApi('POST', '$baseUrl/api/register', requestBody: bodyStr);
    final res = await http.post(
      Uri.parse('$baseUrl/api/register'),
      headers: _publicHeaders,
      body: bodyStr,
    );
    _logApi('POST', '$baseUrl/api/register', statusCode: res.statusCode, responseBody: res.body);
    return _parseAuthResponse(res);
  }

  static ApiResponse<AuthData> _parseAuthResponse(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>?;
    if (body == null) return ApiResponse.error('Invalid response');
    if ((body['status'] as String?) != 'success') {
      final msg = body['message'];
      final err = msg is Map ? (msg['error'] as List?)?.first : msg?.toString();
      return ApiResponse.error(err ?? 'Request failed');
    }
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) return ApiResponse.error('No data');
    return ApiResponse.success(AuthData.fromJson(data));
  }

  /// GET /api/products
  Future<ApiResponse<ProductListData>> getProducts({
    int page = 1,
    int perPage = 15,
    int? categoryId,
    int? brandId,
    String? search,
  }) async {
    final q = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
    };
    if (categoryId != null) q['category_id'] = '$categoryId';
    if (brandId != null) q['brand_id'] = '$brandId';
    if (search != null && search.isNotEmpty) q['search'] = search;
    final uri = Uri.parse('$baseUrl/api/products').replace(queryParameters: q);
    _logApi('GET', uri.toString());
    final res = await http.get(uri, headers: _publicHeaders);
    _logApi('GET', uri.toString(), statusCode: res.statusCode, responseBody: res.body);
    return _parseProductList(res);
  }

  /// GET /api/products/{id}
  Future<ApiResponse<ProductDetail>> getProduct(int id) async {
    final url = '$baseUrl/api/products/$id';
    _logApi('GET', url);
    final res = await http.get(Uri.parse(url), headers: _publicHeaders);
    _logApi('GET', url, statusCode: res.statusCode, responseBody: res.body);
    return _parseProductDetail(res);
  }

  /// GET /api/categories
  Future<ApiResponse<List<CategoryItem>>> getCategories() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/categories'),
      headers: _publicHeaders,
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>?;
    if (body == null) return ApiResponse.error('Invalid response');
    if ((body['status'] as String?) != 'success') {
      final msg = body['message'];
      final err = msg is Map ? (msg['error'] as List?)?.first : msg?.toString();
      return ApiResponse.error(err ?? 'Request failed');
    }
    final data = body['data'] as Map<String, dynamic>?;
    final list = (data?['categories'] as List<dynamic>?) ?? [];
    return ApiResponse.success(
      list.map((e) => CategoryItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// GET /api/sliders
  Future<ApiResponse<List<SliderItem>>> getSliders() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/sliders'),
      headers: _publicHeaders,
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>?;
    if (body == null) return ApiResponse.error('Invalid response');
    if ((body['status'] as String?) != 'success') {
      final msg = body['message'];
      final err = msg is Map ? (msg['error'] as List?)?.first : msg?.toString();
      return ApiResponse.error(err ?? 'Request failed');
    }
    final data = body['data'] as Map<String, dynamic>?;
    final list = (data?['sliders'] as List<dynamic>?) ?? [];
    return ApiResponse.success(
      list.map((e) => SliderItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// GET /api/shipping-methods (requires API key)
  Future<ApiResponse<List<ShippingMethodItem>>> getShippingMethods() async {
    final url = '$baseUrl/api/shipping-methods';
    _logApi('GET', url);
    final res = await http.get(Uri.parse(url), headers: _authHeaders);
    _logApi('GET', url, statusCode: res.statusCode, responseBody: res.body);
    return _parseListResponse(res, 'shipping_methods', ShippingMethodItem.fromJson);
  }

  /// GET /api/payment-methods (requires API key)
  Future<ApiResponse<List<PaymentMethodItem>>> getPaymentMethods() async {
    final url = '$baseUrl/api/payment-methods';
    _logApi('GET', url);
    final res = await http.get(Uri.parse(url), headers: _authHeaders);
    _logApi('GET', url, statusCode: res.statusCode, responseBody: res.body);
    return _parseListResponse(res, 'payment_methods', PaymentMethodItem.fromJson);
  }

  /// POST /api/upload-customer-photos (requires API key). Upload front/back product photos. Returns paths to pass to createOrder.
  Future<ApiResponse<UploadCustomerPhotosResult>> uploadCustomerPhotos({
    required String? frontPath,
    required String? backPath,
  }) async {
    if ((frontPath == null || frontPath.isEmpty) && (backPath == null || backPath.isEmpty)) {
      return ApiResponse.success(UploadCustomerPhotosResult(frontPath: null, backPath: null));
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/upload-customer-photos'),
    );
    request.headers.addAll(_authHeaders);
    request.headers.remove('Content-Type');
    try {
      if (frontPath != null && frontPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('front_picture', frontPath));
      }
      if (backPath != null && backPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('back_picture', backPath));
      }
    } catch (e) {
      return ApiResponse.error('Failed to read image: $e');
    }
    final url = '$baseUrl/api/upload-customer-photos';
    _logApi('POST', url, requestBody: '[multipart: front_picture, back_picture]');
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _logApi('POST', url, statusCode: res.statusCode, responseBody: res.body);
    final body = jsonDecode(res.body) as Map<String, dynamic>?;
    if (body == null) return ApiResponse.error('Invalid response');
    if (res.statusCode == 401) return ApiResponse.error('API key required.');
    if ((body['status'] as String?) != 'success') {
      final msg = body['message'];
      final err = msg is Map ? (msg['error'] as List?)?.first : msg?.toString();
      return ApiResponse.error(err ?? 'Upload failed');
    }
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return ApiResponse.success(UploadCustomerPhotosResult(
      frontPath: data['front_path'] as String?,
      backPath: data['back_path'] as String?,
    ));
  }

  /// POST /api/orders (requires API key). Creates order from cart items.
  /// [noteCharge] is added to total when product has note and user enters note (e.g. 5000).
  /// [frontPhoto] and [backPhoto] are storage paths from uploadCustomerPhotos (when product has customer_photo).
  Future<ApiResponse<CreateOrderResult>> createOrder({
    required List<CartItem> items,
    required ShippingAddressInput shippingAddress,
    required int shippingMethodId,
    String? couponCode,
    String? noteToSeller,
    int noteCharge = 0,
    String? customisedTest,
    String? customisedShortTest,
    String? frontPhoto,
    String? backPhoto,
  }) async {
    final body = <String, dynamic>{
      'items': items.map((i) => {
            'product_id': i.productId,
            'quantity': i.quantity,
            if (i.variantId != null) 'product_variant_id': i.variantId,
          }).toList(),
      'shipping_address': shippingAddress.toJson(),
      'shipping_method_id': shippingMethodId,
      if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
      if (noteToSeller != null && noteToSeller.isNotEmpty) 'note_to_seller': noteToSeller,
      if (noteCharge > 0) 'note_charge': noteCharge,
      if (customisedTest != null && customisedTest.isNotEmpty) 'customised_test': customisedTest,
      if (customisedShortTest != null && customisedShortTest.isNotEmpty) 'customised_short_test': customisedShortTest,
      if (frontPhoto != null && frontPhoto.isNotEmpty) 'front_photo': frontPhoto,
      if (backPhoto != null && backPhoto.isNotEmpty) 'back_photo': backPhoto,
    };
    final bodyStr = jsonEncode(body);
    final url = '$baseUrl/api/orders';
    _logApi('POST', url, requestBody: bodyStr);
    final res = await http.post(Uri.parse(url), headers: _authHeaders, body: bodyStr);
    _logApi('POST', url, statusCode: res.statusCode, responseBody: res.body);
    return _parseCreateOrder(res);
  }

  /// POST /api/payment/initiate (requires API key). Returns payment_url to open in browser.
  Future<ApiResponse<PaymentInitiateResult>> initiatePayment({
    required int orderId,
    required dynamic gateway,
    String? currency,
  }) async {
    final body = <String, dynamic>{
      'order_id': orderId,
      'gateway': gateway is int ? gateway : gateway.toString(),
      if (currency != null) 'currency': currency,
    };
    final bodyStr = jsonEncode(body);
    final url = '$baseUrl/api/payment/initiate';
    _logApi('POST', url, requestBody: bodyStr);
    final res = await http.post(Uri.parse(url), headers: _authHeaders, body: bodyStr);
    _logApi('POST', url, statusCode: res.statusCode, responseBody: res.body);
    return _parsePaymentInitiate(res);
  }

  static ApiResponse<List<T>> _parseListResponse<T>(
    http.Response res,
    String dataKey,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = jsonDecode(res.body) as Map<String, dynamic>?;
    if (body == null) return ApiResponse.error('Invalid response');
    if (res.statusCode == 401) {
      final msg = body['message'];
      final err = msg is Map ? (msg['error'] as List?)?.first : msg?.toString();
      return ApiResponse.error(err ?? 'API key required for checkout.');
    }
    if ((body['status'] as String?) != 'success') {
      final msg = body['message'];
      final err = msg is Map ? (msg['error'] as List?)?.first : msg?.toString();
      return ApiResponse.error(err ?? 'Request failed');
    }
    final data = body['data'] as Map<String, dynamic>?;
    final list = (data?[dataKey] as List<dynamic>?) ?? [];
    return ApiResponse.success(
      list.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  static ApiResponse<CreateOrderResult> _parseCreateOrder(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>?;
    if (body == null) return ApiResponse.error('Invalid response');
    if (res.statusCode == 401) {
      return ApiResponse.error('API key required for checkout.');
    }
    if (res.statusCode == 422 || (body['status'] as String?) != 'success') {
      final msg = body['message'];
      final err = msg is Map ? (msg['error'] as List?)?.first : msg?.toString();
      return ApiResponse.error(err ?? 'Failed to create order');
    }
    return ApiResponse.success(CreateOrderResult.fromJson(body));
  }

  static ApiResponse<PaymentInitiateResult> _parsePaymentInitiate(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>?;
    if (body == null) return ApiResponse.error('Invalid response');
    if (res.statusCode == 401) {
      return ApiResponse.error('API key required for checkout.');
    }
    if (res.statusCode != 200 || (body['status'] as String?) != 'success') {
      final msg = body['message'];
      final err = msg is Map ? (msg['error'] as List?)?.first : msg?.toString();
      return ApiResponse.error(err ?? 'Payment initiation failed');
    }
    return ApiResponse.success(PaymentInitiateResult.fromJson(body));
  }

  /// POST /api/orders/{orderId}/confirm-payment (requires API key). Marks order as paid and processing.
  Future<ApiResponse<void>> confirmPayment(int orderId) async {
    final url = '$baseUrl/api/orders/$orderId/confirm-payment';
    _logApi('POST', url);
    final res = await http.post(
      Uri.parse(url),
      headers: _authHeaders,
      body: jsonEncode(<String, dynamic>{}),
    );
    _logApi('POST', url, statusCode: res.statusCode, responseBody: res.body);
    final body = jsonDecode(res.body) as Map<String, dynamic>?;
    if (body == null) return ApiResponse.error('Invalid response');
    if (res.statusCode == 401) return ApiResponse.error('API key required.');
    if (res.statusCode == 404) return ApiResponse.error('Order not found.');
    if ((body['status'] as String?) != 'success') {
      final msg = body['message'];
      final err = msg is Map ? (msg['error'] as List?)?.first : msg?.toString();
      return ApiResponse.error(err ?? 'Failed to confirm payment');
    }
    return ApiResponse.success(null);
  }

  /// GET /api/dashboard (requires API key). Order counts + latest orders.
  Future<ApiResponse<DashboardData>> getDashboard() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/dashboard'),
      headers: _authHeaders,
    );
    return _parseDashboard(res);
  }

  /// GET /api/orders (requires API key). Optional status: pending, processing, dispatched, delivered, canceled.
  Future<ApiResponse<OrdersListData>> getOrders({int page = 1, String? status}) async {
    final q = <String, String>{'page': '$page', 'per_page': '15'};
    if (status != null && status.isNotEmpty) q['status'] = status;
    final uri = Uri.parse('$baseUrl/api/orders').replace(queryParameters: q);
    final res = await http.get(uri, headers: _authHeaders);
    return _parseOrdersList(res);
  }

  /// GET /api/orders/{id} (requires API key). id can be order id or order_number.
  Future<ApiResponse<UserOrderDetail>> getOrderDetail(dynamic idOrNumber) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/orders/$idOrNumber'),
      headers: _authHeaders,
    );
    return _parseOrderDetail(res);
  }

  static ApiResponse<DashboardData> _parseDashboard(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>?;
    if (body == null) return ApiResponse.error('Invalid response');
    if (res.statusCode == 401) return ApiResponse.error('Please log in to view dashboard.');
    if ((body['status'] as String?) != 'success') {
      final msg = body['message'];
      final err = msg is Map ? (msg['error'] as List?)?.first : msg?.toString();
      return ApiResponse.error(err ?? 'Request failed');
    }
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) return ApiResponse.error('No data');
    return ApiResponse.success(DashboardData.fromJson(data));
  }

  static ApiResponse<OrdersListData> _parseOrdersList(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>?;
    if (body == null) return ApiResponse.error('Invalid response');
    if (res.statusCode == 401) return ApiResponse.error('Please log in to view orders.');
    if ((body['status'] as String?) != 'success') {
      final msg = body['message'];
      final err = msg is Map ? (msg['error'] as List?)?.first : msg?.toString();
      return ApiResponse.error(err ?? 'Request failed');
    }
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) return ApiResponse.error('No data');
    return ApiResponse.success(OrdersListData.fromJson(data));
  }

  static ApiResponse<UserOrderDetail> _parseOrderDetail(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>?;
    if (body == null) return ApiResponse.error('Invalid response');
    if (res.statusCode == 401) return ApiResponse.error('Please log in to view order.');
    if (res.statusCode == 404) return ApiResponse.error('Order not found.');
    if ((body['status'] as String?) != 'success') {
      final msg = body['message'];
      final err = msg is Map ? (msg['error'] as List?)?.first : msg?.toString();
      return ApiResponse.error(err ?? 'Request failed');
    }
    final data = body['data'] as Map<String, dynamic>?;
    final order = data?['order'] as Map<String, dynamic>?;
    if (order == null) return ApiResponse.error('No order');
    return ApiResponse.success(UserOrderDetail.fromJson(order));
  }

  /// POST /api/change-password (requires API key).
  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/change-password'),
      headers: _authHeaders,
      body: jsonEncode({
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      }),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>?;
    if (body == null) return ApiResponse.error('Invalid response');
    if ((body['status'] as String?) != 'success') {
      final msg = body['message'];
      final err = msg is Map ? (msg['error'] as List?)?.first : msg?.toString();
      return ApiResponse.error(err ?? 'Failed to change password');
    }
    return ApiResponse.success(null);
  }

  /// GET /api/order-tracking/{orderNumber} (no auth)
  Future<OrderTrackingResult> getOrderTracking(String orderNumber) async {
    final encoded = Uri.encodeComponent(orderNumber.trim());
    final res = await http.get(
      Uri.parse('$baseUrl/api/order-tracking/$encoded'),
      headers: _publicHeaders,
    );
    if (res.statusCode == 404) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      return OrderTrackingResult(
        success: false,
        error: body?['error'] as String? ?? 'Order not found',
      );
    }
    if (res.statusCode != 200) {
      return OrderTrackingResult(success: false, error: 'Server error');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return OrderTrackingResult.fromJson(data);
  }

  static ApiResponse<ProductListData> _parseProductList(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>?;
    if (body == null) {
      return ApiResponse.error('Invalid response');
    }
    final status = body['status'] as String?;
    if (status != 'success') {
      final msg = body['message'];
      final err = msg is Map ? (msg['error'] as List?)?.first : msg?.toString();
      return ApiResponse.error(err ?? 'Request failed');
    }
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) return ApiResponse.error('No data');
    return ApiResponse.success(ProductListData.fromJson(data));
  }

  static ApiResponse<ProductDetail> _parseProductDetail(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>?;
    if (body == null) return ApiResponse.error('Invalid response');
    final status = body['status'] as String?;
    if (status != 'success') {
      final msg = body['message'];
      final err = msg is Map ? (msg['error'] as List?)?.first : msg?.toString();
      return ApiResponse.error(err ?? 'Request failed');
    }
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) return ApiResponse.error('No data');
    final product = data['product'] as Map<String, dynamic>?;
    if (product == null) return ApiResponse.error('No product');
    return ApiResponse.success(ProductDetail.fromJson(product));
  }
}
