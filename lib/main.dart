import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager for desktop
  // Note: On Linux, some window_manager methods may not be fully supported,
  // which is expected and handled gracefully. GTK warnings may appear in console
  // but don't affect app functionality.
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    try {
      await windowManager.ensureInitialized();

      // Configure window for desktop app
      const windowOptions = WindowOptions(
        size: Size(1400, 900),
        minimumSize: Size(1200, 800), // Increased minimum size to prevent overflow
        center: true,
        backgroundColor: Color(0xFF0D0D0F), // Dark background color
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
        title: 'Personal Finance Tracker',
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        try {
          await windowManager.show();
          await windowManager.focus();
        } catch (e) {
          debugPrint('Failed to show window: $e');
        }
      });

      // Explicitly set minimum size to ensure it's enforced (especially on Linux)
      // Try multiple times with a small delay to ensure it takes effect
      for (int i = 0; i < 3; i++) {
        try {
          await windowManager.setMinimumSize(const Size(1200, 800));
          // Also set geometry hints if available
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          if (kDebugMode && i == 2) {
            debugPrint('Failed to set minimum size after retries: $e');
          }
        }
      }

      // Enable window controls (with error handling for Linux compatibility)
      final windowControls = [
        () => windowManager.setResizable(true),
        () => windowManager.setMovable(true),
        () => windowManager.setMinimizable(true),
        () => windowManager.setMaximizable(true),
        () => windowManager.setClosable(true),
      ];

      for (final control in windowControls) {
        try {
          await control();
        } catch (e) {
          // Ignore if not supported on this platform
          // Only print in debug mode and suppress repeated errors
          if (kDebugMode) {
            // Suppress verbose window_manager errors on Linux
            final errorStr = e.toString();
            if (!errorStr.contains('MissingPluginException') || 
                !Platform.isLinux) {
              debugPrint('Window control failed (this is OK on some platforms): $e');
            }
          }
        }
      }
    } catch (e) {
      // If window_manager fails completely, continue anyway - the app should still work
      debugPrint('Window manager initialization failed: $e');
      debugPrint('App will continue without window manager features');
    }
  }

  runApp(
    const ProviderScope(
      child: PersonalFinanceApp(),
    ),
  );
}

/// Root application widget
class PersonalFinanceApp extends ConsumerWidget {
  const PersonalFinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Personal Finance Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
