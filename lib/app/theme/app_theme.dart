import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Premium Apple-inspired theme configuration
/// Provides both dark (primary) and light themes
class AppTheme {
  AppTheme._();

  // ============================================
  // DARK THEME (PRIMARY)
  // ============================================

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        primaryColor: AppColors.accentBlue,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentBlue,
          secondary: AppColors.accentPurple,
          tertiary: AppColors.accentTeal,
          surface: AppColors.darkSurface,
          error: AppColors.accentRed,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.darkTextPrimary,
          onError: Colors.white,
          outline: AppColors.darkBorder,
          outlineVariant: AppColors.darkDivider,
        ),
        textTheme: _buildTextTheme(isDark: true),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBackground,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkDivider,
          thickness: 0.5,
          space: 0,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.darkTextSecondary,
          size: 24,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.accentBlue,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.accentRed,
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintStyle: AppTypography.bodyMedium(AppColors.darkTextTertiary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTypography.labelLarge(Colors.white),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accentBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: AppTypography.labelMedium(AppColors.accentBlue),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentBlue,
            side: const BorderSide(color: AppColors.accentBlue, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTypography.labelLarge(AppColors.accentBlue),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.darkSurfaceElevated,
          selectedColor: AppColors.accentBlue.withValues(alpha: 0.2),
          labelStyle: AppTypography.labelMedium(AppColors.darkTextPrimary),
          secondaryLabelStyle:
              AppTypography.labelMedium(AppColors.darkTextSecondary),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.darkSurface,
          elevation: 24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: AppTypography.headlineMedium(AppColors.darkTextPrimary),
          contentTextStyle: AppTypography.bodyMedium(AppColors.darkTextSecondary),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.darkSurface,
          modalBackgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.darkSurfaceElevated,
          contentTextStyle: AppTypography.bodyMedium(AppColors.darkTextPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.accentBlue,
          unselectedLabelColor: AppColors.darkTextSecondary,
          indicatorColor: AppColors.accentBlue,
          labelStyle: AppTypography.labelMedium(AppColors.accentBlue),
          unselectedLabelStyle:
              AppTypography.labelMedium(AppColors.darkTextSecondary),
          dividerColor: Colors.transparent,
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: AppColors.darkSurface,
          selectedIconTheme: const IconThemeData(
            color: AppColors.accentBlue,
            size: 24,
          ),
          unselectedIconTheme: const IconThemeData(
            color: AppColors.darkTextSecondary,
            size: 24,
          ),
          selectedLabelTextStyle: AppTypography.labelSmall(AppColors.accentBlue),
          unselectedLabelTextStyle:
              AppTypography.labelSmall(AppColors.darkTextSecondary),
          indicatorColor: AppColors.accentBlue.withValues(alpha: 0.15),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(AppColors.darkTextTertiary.withValues(alpha: 0.4)),
          trackColor: WidgetStateProperty.all(Colors.transparent),
          radius: const Radius.circular(4),
          thickness: WidgetStateProperty.all(6),
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceHighlight,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.caption(AppColors.darkTextPrimary),
        ),
      );

  // ============================================
  // LIGHT THEME
  // ============================================

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBackground,
        primaryColor: AppColors.accentBlue,
        colorScheme: const ColorScheme.light(
          primary: AppColors.accentBlue,
          secondary: AppColors.accentPurple,
          tertiary: AppColors.accentTeal,
          surface: AppColors.lightSurface,
          error: AppColors.accentRed,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.lightTextPrimary,
          onError: Colors.white,
          outline: AppColors.lightBorder,
          outlineVariant: AppColors.lightDivider,
        ),
        textTheme: _buildTextTheme(isDark: false),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightBackground,
          foregroundColor: AppColors.lightTextPrimary,
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        cardTheme: CardThemeData(
          color: AppColors.lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.lightDivider,
          thickness: 0.5,
          space: 0,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.lightTextSecondary,
          size: 24,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightSurfaceHighlight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.accentBlue,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.accentRed,
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintStyle: AppTypography.bodyMedium(AppColors.lightTextTertiary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTypography.labelLarge(Colors.white),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accentBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: AppTypography.labelMedium(AppColors.accentBlue),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentBlue,
            side: const BorderSide(color: AppColors.accentBlue, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTypography.labelLarge(AppColors.accentBlue),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.lightSurfaceHighlight,
          selectedColor: AppColors.accentBlue.withValues(alpha: 0.15),
          labelStyle: AppTypography.labelMedium(AppColors.lightTextPrimary),
          secondaryLabelStyle:
              AppTypography.labelMedium(AppColors.lightTextSecondary),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.lightSurface,
          elevation: 24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle:
              AppTypography.headlineMedium(AppColors.lightTextPrimary),
          contentTextStyle:
              AppTypography.bodyMedium(AppColors.lightTextSecondary),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.lightSurface,
          modalBackgroundColor: AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.lightTextPrimary,
          contentTextStyle: AppTypography.bodyMedium(AppColors.lightSurface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.accentBlue,
          unselectedLabelColor: AppColors.lightTextSecondary,
          indicatorColor: AppColors.accentBlue,
          labelStyle: AppTypography.labelMedium(AppColors.accentBlue),
          unselectedLabelStyle:
              AppTypography.labelMedium(AppColors.lightTextSecondary),
          dividerColor: Colors.transparent,
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: AppColors.lightSurface,
          selectedIconTheme: const IconThemeData(
            color: AppColors.accentBlue,
            size: 24,
          ),
          unselectedIconTheme: const IconThemeData(
            color: AppColors.lightTextSecondary,
            size: 24,
          ),
          selectedLabelTextStyle: AppTypography.labelSmall(AppColors.accentBlue),
          unselectedLabelTextStyle:
              AppTypography.labelSmall(AppColors.lightTextSecondary),
          indicatorColor: AppColors.accentBlue.withValues(alpha: 0.1),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(AppColors.lightTextTertiary.withValues(alpha: 0.4)),
          trackColor: WidgetStateProperty.all(Colors.transparent),
          radius: const Radius.circular(4),
          thickness: WidgetStateProperty.all(6),
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.lightTextPrimary,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.caption(AppColors.lightSurface),
        ),
      );

  // ============================================
  // TEXT THEME BUILDER
  // ============================================

  static TextTheme _buildTextTheme({required bool isDark}) {
    final primaryColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return TextTheme(
      displayLarge: AppTypography.displayLarge(primaryColor),
      displayMedium: AppTypography.displayMedium(primaryColor),
      displaySmall: AppTypography.displaySmall(primaryColor),
      headlineLarge: AppTypography.headlineLarge(primaryColor),
      headlineMedium: AppTypography.headlineMedium(primaryColor),
      headlineSmall: AppTypography.headlineSmall(primaryColor),
      titleLarge: AppTypography.titleLarge(primaryColor),
      titleMedium: AppTypography.titleMedium(primaryColor),
      titleSmall: AppTypography.titleSmall(secondaryColor),
      bodyLarge: AppTypography.bodyLarge(primaryColor),
      bodyMedium: AppTypography.bodyMedium(primaryColor),
      bodySmall: AppTypography.bodySmall(secondaryColor),
      labelLarge: AppTypography.labelLarge(primaryColor),
      labelMedium: AppTypography.labelMedium(primaryColor),
      labelSmall: AppTypography.labelSmall(secondaryColor),
    );
  }
}
