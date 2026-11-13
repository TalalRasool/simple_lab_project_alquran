import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

ThemeData buildAppTheme(AppPalette palette, Brightness brightness) {
  TextStyle style({
    required double size,
    required FontWeight weight,
    required Color color,
    double height = 1.4,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: palette.background,
    canvasColor: palette.background,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      secondary: brightness == Brightness.dark
          ? palette.accent
          : AppColors.lightGreen,
      onSecondary: brightness == Brightness.dark
          ? palette.background
          : AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: palette.surface,
      onSurface: palette.textPrimary,
    ),
    dividerColor: palette.border,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.appBar,
      foregroundColor: palette.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: style(
        size: 18,
        weight: FontWeight.w600,
        color: palette.textPrimary,
        height: 1.3,
      ),
      iconTheme: IconThemeData(color: palette.textPrimary),
    ),
    iconTheme: IconThemeData(color: palette.textPrimary),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.icon),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      titleTextStyle: style(
        size: 18,
        weight: FontWeight.w600,
        color: palette.textPrimary,
        height: 1.3,
      ),
      contentTextStyle: style(
        size: 14,
        weight: FontWeight.w400,
        color: palette.textSecondary,
        height: 1.5,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      modalBackgroundColor: palette.surface,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.card,
      indicatorColor: palette.accent.withValues(alpha: 0.18),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.input,
      hintStyle: style(
        size: 14,
        weight: FontWeight.w400,
        color: palette.textSecondary,
      ),
      labelStyle: style(
        size: 14,
        weight: FontWeight.w500,
        color: palette.textSecondary,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.accent, width: 1.5),
      ),
    ),
    textTheme: TextTheme(
      headlineMedium: style(
        size: 28,
        weight: FontWeight.w700,
        color: palette.textPrimary,
        height: 1.2,
      ),
      titleLarge: style(
        size: 18,
        weight: FontWeight.w600,
        color: palette.textPrimary,
        height: 1.3,
      ),
      titleMedium: style(
        size: 14,
        weight: FontWeight.w500,
        color: palette.textSecondary,
      ),
      bodyMedium: style(
        size: 14,
        weight: FontWeight.w400,
        color: palette.textPrimary,
        height: 1.5,
      ),
      bodySmall: style(
        size: 12,
        weight: FontWeight.w400,
        color: palette.textSecondary,
      ),
      labelLarge: style(
        size: 16,
        weight: FontWeight.w600,
        color: palette.textPrimary,
        height: 1.2,
      ),
    ),
  );
}
