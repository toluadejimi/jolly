import 'package:flutter/foundation.dart';

import '../constants/pref_data.dart';

class AuthProvider extends ChangeNotifier {
  String? _apiKey;
  String? _userEmail;
  String? _userName;
  bool _isLoggedIn = false;

  String? get apiKey => _apiKey;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  bool get isLoggedIn => _isLoggedIn;

  /// Load stored auth from prefs (call once at app start).
  Future<void> loadFromPrefs() async {
    _apiKey = await PrefData.getApiKey();
    _userEmail = await PrefData.getUserEmail();
    _userName = await PrefData.getUserName();
    _isLoggedIn = await PrefData.isLogIn();
    notifyListeners();
  }

  /// Call after successful login or register. Persists to prefs and updates state.
  Future<void> setFromLogin({
    required String apiKey,
    required String email,
    String? name,
  }) async {
    _apiKey = apiKey;
    _userEmail = email;
    _userName = name;
    _isLoggedIn = true;
    await PrefData.setApiKey(apiKey);
    await PrefData.setUserEmail(email);
    await PrefData.setUserName(name);
    await PrefData.setLogIn(true);
    notifyListeners();
  }

  /// Clear auth and persist.
  Future<void> logout() async {
    _apiKey = null;
    _userEmail = null;
    _userName = null;
    _isLoggedIn = false;
    await PrefData.setApiKey(null);
    await PrefData.setUserEmail(null);
    await PrefData.setUserName(null);
    await PrefData.setLogIn(false);
    notifyListeners();
  }
}
