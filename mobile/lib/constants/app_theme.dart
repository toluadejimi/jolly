// ignore: file_names
import 'package:flutter/material.dart';

// Neon orange primary – main brand color
const Color _neonOrange = Color(0xFFFF5F1F);
const Color _neonOrangeLight = Color(0xFFFF7A3D);
const Color _neonOrangeDark = Color(0xFFE55518);
// Light orange for app bar (softer, visible in light mode)
const Color _appBarLightOrange = Color(0xFFFFB088);

// Light mode
const Color _lightBg = Color(0xFFFFFFFF);
const Color _lightCard = Color(0xFFF8F9FB);
const Color _lightPrimaryText = Color(0xFF111111);
const Color _lightSecondaryText = Color(0xFF555555);
const Color _lightBorder = Color(0xFFE5E7EB);

// Dark mode
const Color _darkBg = Color(0xFF0F0F12);
const Color _darkCard = Color(0xFF1A1A1F);
const Color _darkPrimaryText = Color(0xFFFFFFFF);
const Color _darkSecondaryText = Color(0xFFBBBBBB);

// Corner radius (12–16px) and transition
const double _radius = 14.0;
const Duration _transition = Duration(milliseconds: 300);

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: _neonOrange,
      colorScheme: ColorScheme.light(
        primary: _neonOrange,
        onPrimary: Colors.white,
        primaryContainer: _neonOrangeLight.withOpacity(0.2),
        secondary: _neonOrangeLight,
        onSecondary: Colors.white,
        surface: _lightCard,
        onSurface: _lightPrimaryText,
        onSurfaceVariant: _lightSecondaryText,
        outline: _lightBorder,
        error: const Color(0xFFB00020),
        onError: Colors.white,
        surfaceContainerHighest: _lightCard,
      ),
      scaffoldBackgroundColor: _lightBg,
      textTheme: _buildLightTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: _appBarLightOrange,
        foregroundColor: _lightPrimaryText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _lightPrimaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: _lightCard,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: _lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _neonOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          elevation: 0,
          animationDuration: _transition,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _neonOrange,
        foregroundColor: Colors.white,
        elevation: 2,
        focusElevation: 4,
        hoverElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(_radius)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: _neonOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: Color(0xFFB00020)),
        ),
        labelStyle: const TextStyle(color: _lightSecondaryText),
        hintStyle: const TextStyle(color: _lightSecondaryText),
      ),
      dividerTheme: const DividerThemeData(color: _lightBorder, thickness: 1),
      iconTheme: const IconThemeData(color: _lightPrimaryText, size: 24),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightCard,
        selectedItemColor: _neonOrange,
        unselectedItemColor: _lightSecondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: _neonOrange,
      colorScheme: ColorScheme.dark(
        primary: _neonOrange,
        onPrimary: Colors.black,
        primaryContainer: _neonOrange.withOpacity(0.2),
        secondary: _neonOrangeLight,
        onSecondary: Colors.black,
        surface: _darkCard,
        onSurface: _darkPrimaryText,
        onSurfaceVariant: _darkSecondaryText,
        outline: const Color(0xFF2E2E33),
        error: const Color(0xFFCF6679),
        onError: Colors.black,
        surfaceContainerHighest: const Color(0xFF25252B),
      ),
      scaffoldBackgroundColor: _darkBg,
      textTheme: _buildDarkTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkCard,
        foregroundColor: _darkPrimaryText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _darkPrimaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: _darkPrimaryText),
      ),
      cardTheme: CardThemeData(
        color: _darkCard,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: Color(0xFF2E2E33), width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _neonOrange,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          elevation: 0,
          animationDuration: _transition,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _neonOrange,
        foregroundColor: Colors.black,
        elevation: 2,
        focusElevation: 4,
        hoverElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(_radius)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: Color(0xFF2E2E33)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: _neonOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: Color(0xFFCF6679)),
        ),
        labelStyle: const TextStyle(color: _darkSecondaryText),
        hintStyle: const TextStyle(color: _darkSecondaryText),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2E2E33),
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: _darkPrimaryText, size: 24),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkCard,
        selectedItemColor: _neonOrange,
        unselectedItemColor: _darkSecondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static TextTheme _buildLightTextTheme() {
    return TextTheme(
      displayLarge: const TextStyle(color: _lightPrimaryText, fontWeight: FontWeight.bold),
      displayMedium: const TextStyle(color: _lightPrimaryText, fontWeight: FontWeight.bold),
      displaySmall: const TextStyle(color: _lightPrimaryText, fontWeight: FontWeight.bold),
      headlineLarge: const TextStyle(color: _lightPrimaryText, fontWeight: FontWeight.w600),
      headlineMedium: const TextStyle(color: _lightPrimaryText, fontWeight: FontWeight.w600),
      headlineSmall: const TextStyle(color: _lightPrimaryText, fontWeight: FontWeight.w600),
      titleLarge: const TextStyle(color: _lightPrimaryText, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(color: _lightPrimaryText, fontWeight: FontWeight.w600),
      titleSmall: const TextStyle(color: _lightPrimaryText, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(color: _lightPrimaryText),
      bodyMedium: const TextStyle(color: _lightPrimaryText),
      bodySmall: const TextStyle(color: _lightSecondaryText),
      labelLarge: const TextStyle(color: _lightPrimaryText, fontWeight: FontWeight.w600),
      labelMedium: const TextStyle(color: _lightSecondaryText),
      labelSmall: const TextStyle(color: _lightSecondaryText),
    );
  }

  static TextTheme _buildDarkTextTheme() {
    return TextTheme(
      displayLarge: const TextStyle(color: _darkPrimaryText, fontWeight: FontWeight.bold),
      displayMedium: const TextStyle(color: _darkPrimaryText, fontWeight: FontWeight.bold),
      displaySmall: const TextStyle(color: _darkPrimaryText, fontWeight: FontWeight.bold),
      headlineLarge: const TextStyle(color: _darkPrimaryText, fontWeight: FontWeight.w600),
      headlineMedium: const TextStyle(color: _darkPrimaryText, fontWeight: FontWeight.w600),
      headlineSmall: const TextStyle(color: _darkPrimaryText, fontWeight: FontWeight.w600),
      titleLarge: const TextStyle(color: _darkPrimaryText, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(color: _darkPrimaryText, fontWeight: FontWeight.w600),
      titleSmall: const TextStyle(color: _darkPrimaryText, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(color: _darkPrimaryText),
      bodyMedium: const TextStyle(color: _darkPrimaryText),
      bodySmall: const TextStyle(color: _darkSecondaryText),
      labelLarge: const TextStyle(color: _darkPrimaryText, fontWeight: FontWeight.w600),
      labelMedium: const TextStyle(color: _darkSecondaryText),
      labelSmall: const TextStyle(color: _darkSecondaryText),
    );
  }

  static Color get neonOrange => _neonOrange;
  static Color get neonOrangeLight => _neonOrangeLight;
  static Color get neonOrangeDark => _neonOrangeDark;
  static Color get appBarLightOrange => _appBarLightOrange;
  static double get radius => _radius;
  static Duration get transition => _transition;
}
