import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.deepPurple,
    );
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F6F8),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardColor: Colors.white,
      textTheme: _textTheme(base.textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      textTheme: _textTheme(base.textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    final baloo = base.apply(fontFamily: 'Baloo2');
    return baloo.copyWith(
      headlineMedium: baloo.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      bodyLarge: baloo.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
    );
  }
}
