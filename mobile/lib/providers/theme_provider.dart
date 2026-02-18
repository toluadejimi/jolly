// ignore: file_names
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  set mode(ThemeMode value) {
    if (_mode == value) return;
    _mode = value;
    notifyListeners();
  }

  bool get isDark {
    if (_mode == ThemeMode.system) return false; // default to light when system unclear
    return _mode == ThemeMode.dark;
  }

  void setLight() => mode = ThemeMode.light;
  void setDark() => mode = ThemeMode.dark;
  void setSystem() => mode = ThemeMode.system;
}
