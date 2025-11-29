import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing the app's theme mode
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Notifier for theme mode management
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark; // Dark mode is primary

  /// Toggle between dark and light mode
  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  /// Set a specific theme mode
  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  /// Check if currently in dark mode
  bool get isDark => state == ThemeMode.dark;
}

/// Provider to check if dark mode is active
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeModeProvider) == ThemeMode.dark;
});
