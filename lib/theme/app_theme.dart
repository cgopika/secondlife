import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2F6B4F);
  static const darkGreen = Color(0xFF18352A);
  static const lightMint = Color(0xFFE8F3EC);
  static const softGreen = Color(0xFFF1F7F2);
  static const warmBg = Color(0xFFF7F8F4);
  static const darkText = Color(0xFF17231D);
  static const secondaryText = Color(0xFF69756D);
  static const accent = Color(0xFFE6A84B);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.from(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        background: AppColors.warmBg,
        onPrimary: Colors.white,
      ),
      textTheme: Typography.material2018().englishLike,
    );

    return base.copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.warmBg,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.darkText,
        displayColor: AppColors.darkText,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkText,
          side: BorderSide(color: AppColors.lightMint),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
