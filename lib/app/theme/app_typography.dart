import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium typography system using Inter (Apple-like sans-serif)
/// with carefully crafted font weights and letter spacing
class AppTypography {
  AppTypography._();

  /// Base font family - Inter provides excellent readability
  /// and has similar characteristics to San Francisco
  static String get _fontFamily => GoogleFonts.inter().fontFamily!;

  /// Alternative display font - Outfit for larger headings
  static String get _displayFontFamily => GoogleFonts.outfit().fontFamily!;

  // ============================================
  // DISPLAY STYLES (Large headings)
  // ============================================

  static TextStyle displayLarge(Color color) => TextStyle(
        fontFamily: _displayFontFamily,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        height: 1.1,
        color: color,
      );

  static TextStyle displayMedium(Color color) => TextStyle(
        fontFamily: _displayFontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.0,
        height: 1.15,
        color: color,
      );

  static TextStyle displaySmall(Color color) => TextStyle(
        fontFamily: _displayFontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.2,
        color: color,
      );

  // ============================================
  // HEADLINE STYLES (Section headings)
  // ============================================

  static TextStyle headlineLarge(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.25,
        color: color,
      );

  static TextStyle headlineMedium(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
        color: color,
      );

  static TextStyle headlineSmall(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
        color: color,
      );

  // ============================================
  // TITLE STYLES (Card titles, list items)
  // ============================================

  static TextStyle titleLarge(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.4,
        color: color,
      );

  static TextStyle titleMedium(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        height: 1.4,
        color: color,
      );

  static TextStyle titleSmall(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.4,
        color: color,
      );

  // ============================================
  // BODY STYLES (Main content text)
  // ============================================

  static TextStyle bodyLarge(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        height: 1.5,
        color: color,
      );

  static TextStyle bodyMedium(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        height: 1.5,
        color: color,
      );

  static TextStyle bodySmall(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
        color: color,
      );

  // ============================================
  // LABEL STYLES (Buttons, tabs, small text)
  // ============================================

  static TextStyle labelLarge(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.4,
        color: color,
      );

  static TextStyle labelMedium(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.4,
        color: color,
      );

  static TextStyle labelSmall(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.4,
        color: color,
      );

  // ============================================
  // SPECIAL STYLES
  // ============================================

  /// Large monetary amounts
  static TextStyle moneyLarge(Color color) => TextStyle(
        fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.0,
        height: 1.1,
        color: color,
      );

  /// Medium monetary amounts
  static TextStyle moneyMedium(Color color) => TextStyle(
        fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
        height: 1.2,
        color: color,
      );

  /// Small monetary amounts (in lists)
  static TextStyle moneySmall(Color color) => TextStyle(
        fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
        height: 1.3,
        color: color,
      );

  /// Caption text
  static TextStyle caption(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.4,
        color: color,
      );

  /// Overline text (all caps labels)
  static TextStyle overline(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        height: 1.4,
        color: color,
      );
}

