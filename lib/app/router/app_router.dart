import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/transactions/transactions_screen.dart';
import '../../presentation/screens/insights/insights_screen.dart';
import '../../presentation/screens/bulk_entry/bulk_entry_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../shell/app_shell.dart';

/// Route names for type-safe navigation
class AppRoutes {
  AppRoutes._();

  static const String dashboard = '/';
  static const String transactions = '/transactions';
  static const String insights = '/insights';
  static const String bulkEntry = '/bulk-entry';
  static const String settings = '/settings';
}

/// Provider for GoRouter instance
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: AppRoutes.transactions,
            name: 'transactions',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const TransactionsScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: AppRoutes.insights,
            name: 'insights',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const InsightsScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: AppRoutes.bulkEntry,
            name: 'bulk-entry',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const BulkEntryScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});

/// Smooth fade transition for page changes
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
    child: child,
  );
}

