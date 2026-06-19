import 'package:flutter/material.dart';

class AppTheme {
  static const ayanamiBlue = Color(0xFF6DABE4);
  static const offWhiteRei = Color(0xFFF8FAFC);
  static const darkSlate = Color(0xFF2D3748);
  static const greenMetal = Color(0xFF2F855A);
  static const reiOrangeRed = Color(0xFFE53E3E);
  static const reiDarkRed = Color(0xFF9B2C2C);
  static const deepBlueGray = Color(0xFF2A4365);
  static const softWhite = Color(0xFFEDF2F7);
  static const reiPurple = Color(0xFF805AD5);

  static const blackReiBase = Color(0xFF0F1115);
  static const darkGrayRei = Color(0xFF1A1A1A);
  static const reiBlueDark = Color(0xFF5A8BCF);
  static const reiRedDark = Color(0xFF7E0202);
  static const reiGreenDark = Color(0xFF3C5A4A);

  static const primaryBlue = ayanamiBlue;
  static const lightBlue = Color(0xFFB3D1FF);
  static const powderBlue = softWhite;
  static const steelBlue = deepBlueGray;

  static const _btnDuration = Duration(milliseconds: 200);

  static final ButtonStyle _elevatedStyle = ElevatedButton.styleFrom(
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
  );

  static final ButtonStyle _outlinedStyle = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
  );

  static final ButtonStyle _textStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
  );

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
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.white,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _elevatedStyle.copyWith(
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return 4;
            if (states.contains(WidgetState.pressed)) return 1;
            return 0;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return ayanamiBlue.withValues(alpha: 0.9);
            return ayanamiBlue;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.15)),
          shadowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return ayanamiBlue.withValues(alpha: 0.3);
            return Colors.transparent;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedStyle.copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return BorderSide(color: ayanamiBlue.withValues(alpha: 0.6));
            return BorderSide(color: ayanamiBlue.withValues(alpha: 0.3));
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return ayanamiBlue.withValues(alpha: 0.9);
            return ayanamiBlue.withValues(alpha: 0.8);
          }),
          overlayColor: WidgetStateProperty.all(ayanamiBlue.withValues(alpha: 0.08)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textStyle.copyWith(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return ayanamiBlue.withValues(alpha: 0.9);
            return ayanamiBlue;
          }),
          overlayColor: WidgetStateProperty.all(ayanamiBlue.withValues(alpha: 0.08)),
        ),
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
      cardTheme: CardThemeData(
        elevation: 4,
        color: darkGrayRei,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _elevatedStyle.copyWith(
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return 4;
            if (states.contains(WidgetState.pressed)) return 1;
            return 0;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return reiBlueDark.withValues(alpha: 0.9);
            return reiBlueDark;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.15)),
          shadowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return reiBlueDark.withValues(alpha: 0.3);
            return Colors.transparent;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedStyle.copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return BorderSide(color: reiBlueDark.withValues(alpha: 0.6));
            return BorderSide(color: reiBlueDark.withValues(alpha: 0.3));
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return reiBlueDark.withValues(alpha: 0.9);
            return reiBlueDark.withValues(alpha: 0.8);
          }),
          overlayColor: WidgetStateProperty.all(reiBlueDark.withValues(alpha: 0.08)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textStyle.copyWith(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return reiBlueDark.withValues(alpha: 0.9);
            return reiBlueDark;
          }),
          overlayColor: WidgetStateProperty.all(reiBlueDark.withValues(alpha: 0.08)),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: softWhite),
        bodyMedium: TextStyle(color: softWhite),
      ),
    );
  }
}
