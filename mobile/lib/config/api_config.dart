// ═══════════════════════════════════════════════════════════════════════════════
//  EDIT BASE URL HERE  ← Change the value below to your backend URL
// ═══════════════════════════════════════════════════════════════════════════════
//
//  File: lib/config/api_config.dart
//
//  Replace the string on the next line with your Laravel API base URL (no trailing slash).
//  Examples:
//    • Local:       'http://localhost/giftfr/core/public'
//    • Tunnel:      'https://abc123.ngrok-free.app/giftfr/core/public'
//    • Same Wi‑Fi:  'http://192.168.1.10/giftfr/core/public'
//    • Production:  'https://yourdomain.com'
//
// ═══════════════════════════════════════════════════════════════════════════════

class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://jollyboxfr.com/';

  /// Optional. For orders/payment endpoints. Get from user dashboard → API Keys.
  static const String? apiKey = null;
}
