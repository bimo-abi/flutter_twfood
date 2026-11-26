import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF171513) : AppColors.background;
    final surface = isDark ? const Color(0xFF24211E) : AppColors.surface;
    final foreground = isDark ? const Color(0xFFF5EEE6) : AppColors.textPrimary;
    final muted = isDark ? const Color(0xFFB7AAA0) : AppColors.textSecondary;
    final border = isDark ? const Color(0xFF403A35) : AppColors.border;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: isDark ? const Color(0xFFFF6B70) : AppColors.primary,
      onPrimary: Colors.white,
      secondary: isDark ? const Color(0xFF8CC49A) : AppColors.secondary,
      tertiary: AppColors.accent,
      surface: surface,
      onSurface: foreground,
      error: isDark ? const Color(0xFFFF7777) : AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      dividerColor: border,
      fontFamily: AppTextStyles.fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headingMedium.copyWith(color: foreground),
      ),
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.headingLarge.copyWith(color: foreground),
        headlineMedium: AppTextStyles.headingMedium.copyWith(color: foreground),
        headlineSmall: AppTextStyles.headingSmall.copyWith(color: foreground),
        titleLarge: AppTextStyles.headingMedium.copyWith(color: foreground),
        titleMedium: AppTextStyles.bodyLarge.copyWith(color: foreground, fontWeight: FontWeight.w600),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: foreground),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: foreground),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: muted),
        labelLarge: AppTextStyles.button.copyWith(color: foreground),
      ),
      iconTheme: IconThemeData(color: muted),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: AppTextStyles.button,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.secondary,
          minimumSize: const Size(double.infinity, 48),
          side: BorderSide(color: scheme.secondary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: AppTextStyles.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.6)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? scheme.primary : muted,
        )),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
