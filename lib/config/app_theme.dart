import 'package:flutter/material.dart';

import 'colors.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      primary: AppColors.primaryBlue,
      secondary: AppColors.softBlue,
      surface: Colors.white,
    ),
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.darkGray,
      elevation: 0,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryBlue,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
