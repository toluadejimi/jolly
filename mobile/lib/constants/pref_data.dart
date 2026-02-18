// ignore: file_names
import 'package:shared_preferences/shared_preferences.dart';

class PrefData {
  static String prefName = "com.example.shopping";

  static String introAvailable = prefName + "isIntroAvailable";
  static String isLoggedIn = prefName + "isLoggedIn";
  static String userName = prefName + "userName";
  static String userEmail = prefName + "userEmail";
  static String apiKey = prefName + "apiKey";

  static Future<SharedPreferences> getPrefInstance() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences;
  }

  static Future<bool> isIntroAvailable() async {
    SharedPreferences preferences = await getPrefInstance();
    bool isIntroAvailable = preferences.getBool(introAvailable) ?? true;
    return isIntroAvailable;
  }

  static setIntroAvailable(bool avail) async {
    SharedPreferences preferences = await getPrefInstance();
    preferences.setBool(introAvailable, avail);
  }

  static setLogIn(bool avail) async {
    SharedPreferences preferences = await getPrefInstance();
    preferences.setBool(isLoggedIn, avail);
  }

  static Future<bool> isLogIn() async {
    SharedPreferences preferences = await getPrefInstance();
    return preferences.getBool(isLoggedIn) ?? false;
  }

  static Future<void> setUserName(String? name) async {
    SharedPreferences preferences = await getPrefInstance();
    if (name == null || name.isEmpty) {
      preferences.remove(userName);
    } else {
      preferences.setString(userName, name);
    }
  }

  static Future<String?> getUserName() async {
    SharedPreferences preferences = await getPrefInstance();
    return preferences.getString(userName);
  }

  static Future<void> setUserEmail(String? email) async {
    SharedPreferences preferences = await getPrefInstance();
    if (email == null || email.isEmpty) {
      preferences.remove(userEmail);
    } else {
      preferences.setString(userEmail, email);
    }
  }

  static Future<String?> getUserEmail() async {
    SharedPreferences preferences = await getPrefInstance();
    return preferences.getString(userEmail);
  }

  static Future<void> setApiKey(String? key) async {
    SharedPreferences preferences = await getPrefInstance();
    if (key == null || key.isEmpty) {
      preferences.remove(apiKey);
    } else {
      preferences.setString(apiKey, key);
    }
  }

  static Future<String?> getApiKey() async {
    SharedPreferences preferences = await getPrefInstance();
    return preferences.getString(apiKey);
  }
}
