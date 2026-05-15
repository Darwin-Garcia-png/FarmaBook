// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Rei Ayanami Palette (White Plugsuit)
  static const ayanamiBlue = Color(0xFF6DABE4);
  static const offWhiteRei = Color(0xFFF8FAFC);
  static const darkSlate = Color(0xFF2D3748);
  static const greenMetal = Color(0xFF2F855A);
  static const reiOrangeRed = Color(0xFFE53E3E);
  static const reiDarkRed = Color(0xFF9B2C2C);
  static const deepBlueGray = Color(0xFF2A4365);
  static const softWhite = Color(0xFFEDF2F7);
  static const reiPurple = Color(0xFF805AD5); // Purple for Low Stock Alerts

  // Rei Ayanami Palette (Black Plugsuit - Dark Mode)
  static const blackReiBase = Color(0xFF0F1115);
  static const darkGrayRei = Color(0xFF1A1A1A);
  static const reiBlueDark = Color(0xFF5A8BCF);
  static const reiRedDark = Color(0xFF7E0202);
  static const reiGreenDark = Color(0xFF3C5A4A);

  // Legacy Compatibility (Mapped to Rei Palette)
  static const primaryBlue = ayanamiBlue;
  static const lightBlue = Color(0xFFB3D1FF);
  static const powderBlue = softWhite;
  static const steelBlue = deepBlueGray;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: ayanamiBlue,
      scaffoldBackgroundColor: offWhiteRei,
      colorScheme: const ColorScheme.light(
        primary: ayanamiBlue,
        secondary: greenMetal,
        error: reiOrangeRed,
        surface: Colors.white,
        onSurface: darkSlate,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ayanamiBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        color: Colors.white,
        shadowColor: Colors.black12,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: darkSlate),
        bodyMedium: TextStyle(color: darkSlate),
        titleLarge: TextStyle(color: darkSlate, fontWeight: FontWeight.bold),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: reiBlueDark,
      scaffoldBackgroundColor: blackReiBase,
      colorScheme: const ColorScheme.dark(
        primary: reiBlueDark,
        secondary: reiGreenDark,
        error: reiRedDark,
        surface: darkGrayRei,
        onSurface: softWhite,
        onSurfaceVariant: softWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkGrayRei,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        color: darkGrayRei,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: softWhite),
        bodyMedium: TextStyle(color: softWhite),
      ),
    );
  }
}