import 'package:flutter/material.dart';

/// Common hex color codes to display names (lowercase hex key).
const Map<String, String> _hexToColorName = {
  'ff0000': 'Red',
  'red': 'Red',
  '0000ff': 'Blue',
  'blue': 'Blue',
  '008000': 'Green',
  'green': 'Green',
  'ffff00': 'Yellow',
  'yellow': 'Yellow',
  '000000': 'Black',
  'black': 'Black',
  'ffffff': 'White',
  'white': 'White',
  '808080': 'Grey',
  'gray': 'Grey',
  'grey': 'Grey',
  'ffa500': 'Orange',
  'orange': 'Orange',
  '800080': 'Purple',
  'purple': 'Purple',
  'ffc0cb': 'Pink',
  'pink': 'Pink',
  'a52a2a': 'Brown',
  'brown': 'Brown',
  '00ffff': 'Cyan',
  'cyan': 'Cyan',
  'ffd700': 'Gold',
  'gold': 'Gold',
  'c0c0c0': 'Silver',
  'silver': 'Silver',
  '4b0082': 'Indigo',
  'indigo': 'Indigo',
  'ff6347': 'Tomato',
  'dc143c': 'Crimson',
  '2e8b57': 'Sea Green',
  '4169e1': 'Royal Blue',
  '9370db': 'Medium Purple',
  'dda0dd': 'Plum',
  'f0e68c': 'Khaki',
  'cd853f': 'Peru',
  'bc8f8f': 'Rosy Brown',
  '778899': 'Light Slate Grey',
  '2f4f4f': 'Dark Slate Grey',
};

/// Returns true if [s] looks like a hex color code (#RGB, #RRGGBB, RRGGBB, etc.).
bool isHexColorCode(String? s) {
  if (s == null || s.isEmpty) return false;
  final t = s.trim().toLowerCase().replaceFirst('#', '');
  if (t.length == 6 && int.tryParse(t, radix: 16) != null) return true;
  if (t.length == 3 &&
      int.tryParse(t[0] + t[0] + t[1] + t[1] + t[2] + t[2], radix: 16) != null) {
    return true;
  }
  return false;
}

/// Parse hex string to Color. Supports #RRGGBB, #RGB, RRGGBB.
Color? tryParseHexColor(String? s) {
  if (s == null || s.isEmpty) return null;
  var t = s.trim().replaceFirst('#', '');
  if (t.length == 3) {
    t = '${t[0]}${t[0]}${t[1]}${t[1]}${t[2]}${t[2]}';
  }
  if (t.length != 6) return null;
  final n = int.tryParse(t, radix: 16);
  if (n == null) return null;
  return Color(0xFF000000 + n);
}

/// Returns a display name for a hex color (e.g. "Red") or null if unknown.
String? getColorNameFromHex(String? s) {
  if (s == null || s.isEmpty) return null;
  final t = s.trim().toLowerCase().replaceFirst('#', '');
  if (t.length == 3) {
    final expanded =
        '${t[0]}${t[0]}${t[1]}${t[1]}${t[2]}${t[2]}';
    return _hexToColorName[expanded];
  }
  return _hexToColorName[t];
}

/// For variant option: if [optionName] is a hex color, return display label (color name or "Color") and the Color; otherwise return null color and null label (use optionName as-is).
({String displayLabel, Color? color}) variantOptionDisplay(
  String? optionName,
  String priceFormatted,
) {
  if (optionName == null || optionName.isEmpty) {
    return (displayLabel: priceFormatted, color: null);
  }
  final trimmed = optionName.trim();
  if (!isHexColorCode(trimmed)) {
    return (displayLabel: '$trimmed — $priceFormatted', color: null);
  }
  final color = tryParseHexColor(trimmed);
  final name = getColorNameFromHex(trimmed) ?? 'Color';
  return (displayLabel: '$name — $priceFormatted', color: color);
}
