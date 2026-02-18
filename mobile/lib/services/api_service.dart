import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/order_tracking.dart';
import '../models/product.dart';
import '../models/api_response.dart';

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
    final res = await http.get(uri, headers: _publicHeaders);
    return _parseProductList(res);
  }

  /// GET /api/products/{id}
  Future<ApiResponse<ProductDetail>> getProduct(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/products/$id'),
      headers: _publicHeaders,
    );
    return _parseProductDetail(res);
  }

  /// GET /api/order-tracking/{orderNumber} (no auth)
  Future<OrderTrackingResult> getOrderTracking(String orderNumber) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/order-tracking/$orderNumber'),
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
