import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1E6FD9);
  static const primaryDark = Color(0xFF0B57B7);
  static const primarySoft = Color(0xFFE6F0FD);
  static const green = Color(0xFF2EB872);
  static const greenSoft = Color(0xFFDFF5EA);
  static const orange = Color(0xFFF5A524);
  static const orangeSoft = Color(0xFFFEF0D6);
  static const deepOrange = Color(0xFFE8590C);
  static const red = Color(0xFFE5484D);
  static const redSoft = Color(0xFFFDE4E5);
  static const bg = Color(0xFFF7F9FC);
  static const text = Color(0xFF1B2433);
  static const muted = Color(0xFF6B7788);
  static const border = Color(0xFFE3E8F0);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
