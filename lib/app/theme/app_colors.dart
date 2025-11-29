import 'package:flutter/material.dart';

/// Premium color palette inspired by Apple's design language
/// Uses deep charcoal backgrounds with vibrant accent colors
class AppColors {
  AppColors._();

  // ============================================
  // DARK THEME COLORS (PRIMARY)
  // ============================================

  // Backgrounds - Deep charcoal with subtle layering
  static const Color darkBackground = Color(0xFF0D0D0F);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkSurfaceElevated = Color(0xFF2C2C2E);
  static const Color darkSurfaceHighlight = Color(0xFF3A3A3C);

  // Text colors
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkTextTertiary = Color(0xFF636366);

  // Accent colors - Vibrant and distinct
  static const Color accentBlue = Color(0xFF0A84FF);
  static const Color accentGreen = Color(0xFF30D158);
  static const Color accentRed = Color(0xFFFF453A);
  static const Color accentOrange = Color(0xFFFF9F0A);
  static const Color accentYellow = Color(0xFFFFD60A);
  static const Color accentPurple = Color(0xFFBF5AF2);
  static const Color accentPink = Color(0xFFFF375F);
  static const Color accentTeal = Color(0xFF64D2FF);
  static const Color accentIndigo = Color(0xFF5E5CE6);
  static const Color accentMint = Color(0xFF00C7BE);

  // Semantic colors
  static const Color income = Color(0xFF30D158);
  static const Color expense = Color(0xFFFF453A);
  static const Color transfer = Color(0xFF0A84FF);
  static const Color savings = Color(0xFFFFD60A);

  // Gradient colors for cards
  static const List<Color> incomeGradient = [
    Color(0xFF30D158),
    Color(0xFF28A745),
  ];
  static const List<Color> expenseGradient = [
    Color(0xFFFF453A),
    Color(0xFFDC3545),
  ];
  // static const List<Color> savingsGradient = [
    // Color(0xFFFFD60A),
    // Color(0xFFE6C200),
  // ];
static const List<Color> savingsGradient = [
    Color(0xFF4361EE), // Vibrant Indigo
    Color(0xFF4CC9F0), // Electric Cyan
  ];
  
  static const List<Color> walletGradient1 = [
    Color(0xFF667EEA),
    Color(0xFF764BA2),
  ];
  static const List<Color> walletGradient2 = [
    Color(0xFF06B6D4),
    Color(0xFF3B82F6),
  ];
  static const List<Color> walletGradient3 = [
    Color(0xFFF97316),
    Color(0xFFEF4444),
  ];
  static const List<Color> walletGradient4 = [
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];
  static const List<Color> walletGradient5 = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];

  // Separator and divider
  static const Color darkDivider = Color(0xFF38383A);
  static const Color darkBorder = Color(0xFF48484A);

  // ============================================
  // LIGHT THEME COLORS
  // ============================================

  // Backgrounds
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightSurfaceHighlight = Color(0xFFF5F5F7);

  // Text colors
  static const Color lightTextPrimary = Color(0xFF1C1C1E);
  static const Color lightTextSecondary = Color(0xFF636366);
  static const Color lightTextTertiary = Color(0xFF8E8E93);

  // Separator and divider
  static const Color lightDivider = Color(0xFFE5E5EA);
  static const Color lightBorder = Color(0xFFD1D1D6);

  // ============================================
  // CATEGORY COLORS
  // ============================================

  static const Map<String, Color> categoryColors = {
    'food': Color(0xFFFF9F0A),
    'transport': Color(0xFF0A84FF),
    'entertainment': Color(0xFFBF5AF2),
    'shopping': Color(0xFFFF375F),
    'bills': Color(0xFF64D2FF),
    'health': Color(0xFFFF453A),
    'education': Color(0xFF5E5CE6),
    'travel': Color(0xFF30D158),
    'salary': Color(0xFF30D158),
    'investment': Color(0xFFFFD60A),
    'gift': Color(0xFFFF375F),
    'other': Color(0xFF8E8E93),
  };

  /// Get a wallet gradient by index (cycles through available gradients)
  static List<Color> getWalletGradient(int index) {
    final gradients = [
      walletGradient1,
      walletGradient2,
      walletGradient3,
      walletGradient4,
      walletGradient5,
    ];
    return gradients[index % gradients.length];
  }

  /// Get category color by name (case-insensitive)
  static Color getCategoryColor(String category) {
    return categoryColors[category.toLowerCase()] ?? accentBlue;
  }
}

