import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/sprintpay_config.dart';
import '../models/checkout_models.dart';

/// Result of calling SprintPay paynow?mode=api.
class SprintPayInitiateResult {
  const SprintPayInitiateResult({
    required this.success,
    this.data,
    this.errorMessage,
  });

  final bool success;
  final SprintPayAccountResponse? data;
  final String? errorMessage;

  static SprintPayInitiateResult fromResponse(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>?;
    if (body == null) {
      return SprintPayInitiateResult(
        success: false,
        errorMessage: 'Invalid response',
      );
    }
    final status = body['status'];
    final message = body['message']?.toString();
    if (status != true) {
      return SprintPayInitiateResult(
        success: false,
        errorMessage: message ?? 'Payment initiation failed',
      );
    }
    try {
      final data = SprintPayAccountResponse.fromJson(body);
      if (data.verifyUrl.isEmpty) {
        return SprintPayInitiateResult(
          success: false,
          errorMessage: 'Missing verify URL',
        );
      }
      return SprintPayInitiateResult(success: true, data: data);
    } catch (e) {
      return SprintPayInitiateResult(
        success: false,
        errorMessage: message ?? 'Invalid response data',
      );
    }
  }
}

/// SprintPay API service: paynow initiation and verify polling.
class SprintPayService {
  SprintPayService._();

  static const _timeout = Duration(seconds: 15);

  /// Builds and calls GET paynow?amount=...&key=...&ref=...&email=...&mode=api.
  /// Always appends &mode=api.
  static Future<SprintPayInitiateResult> initiatePaynow({
    required double amount,
    required String ref,
    required String email,
    String? key,
  }) async {
    final k = key ?? SprintPayConfig.paynowKey;
    final base = SprintPayConfig.baseUrl;
    final uri = Uri.parse('$base/paynow').replace(
      queryParameters: <String, String>{
        'amount': amount.toStringAsFixed(0),
        'key': k,
        'ref': ref,
        'email': email,
        'mode': 'api',
      },
    );
    try {
      final res = await http.get(uri).timeout(_timeout);
      return SprintPayInitiateResult.fromResponse(res);
    } catch (e) {
      return SprintPayInitiateResult(
        success: false,
        errorMessage: 'Network error. Please try again.',
      );
    }
  }

  /// Polls verify_url. Payment success is indicated only by {"status":"paid"}.
  /// Returns the status string (e.g. 'paid', 'pending') or null on error.
  static Future<String?> checkVerifyUrl(String verifyUrl) async {
    try {
      final res = await http.get(Uri.parse(verifyUrl)).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>?;
      final status = json?['status']?.toString().toLowerCase();
      return status;
    } catch (_) {
      return null;
    }
  }
}
