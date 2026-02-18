import 'package:shared_preferences/shared_preferences.dart';

const String _kBaseUrlKey = 'api_base_url';
const String _defaultBaseUrl = 'http://localhost/giftfr/core/public';

/// Backend API base URL. Loaded from SharedPreferences so you can set a tunnel URL (e.g. ngrok/localtunnel).
class ApiConfig {
  ApiConfig._();

  static String? _baseUrl;

  /// Current base URL (saved tunnel URL or default). No trailing slash.
  static String get baseUrl {
    final url = (_baseUrl ?? _defaultBaseUrl).trim();
    return url.replaceAll(RegExp(r'/$'), '');
  }

  /// Load saved base URL from device storage. Call once at app start.
  static Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_kBaseUrlKey);
  }

  /// Save tunnel (or any) URL as base URL. Use this from Settings.
  static Future<void> setBaseUrl(String url) async {
    final trimmed = url.trim().replaceAll(RegExp(r'/$'), '');
    _baseUrl = trimmed.isEmpty ? null : trimmed;
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(_kBaseUrlKey);
    } else {
      await prefs.setString(_kBaseUrlKey, trimmed);
    }
  }

  /// Optional. For orders/payment endpoints. Set from user dashboard API Keys.
  static const String? apiKey = null;
}
