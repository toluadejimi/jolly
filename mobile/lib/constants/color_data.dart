// ignore: file_names
import 'package:flutter/material.dart';
import 'app_theme.dart';

// Neon orange primary. Prefer Theme.of(context).colorScheme.primary in new code.
Color primaryColor = AppTheme.neonOrange;
// Light mode defaults (for static/legacy use; dark mode should use theme)
Color backgroundColor = const Color(0xFFF8F9FB);
Color fontBlack = const Color(0xFF111111);
Color greyFont = const Color(0xFF555555);
Color cardColor = const Color(0xFFF8F9FB);
Color shadowColor = Colors.black12;

extension ColorExtension on String {
  toColor() {
    var hexColor = replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
  }
}
