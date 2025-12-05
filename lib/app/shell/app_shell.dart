import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/theme_provider.dart';
import 'window_title_bar.dart';
import 'package:window_manager/window_manager.dart';

/// The main app shell providing desktop navigation sidebar
/// Premium Apple-inspired design with smooth animations
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final currentLocation = GoRouterState.of(context).uri.toString();
    final selectedIndex = _getSelectedIndex(currentLocation);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          // Custom Apple-style title bar (draggable)
          _buildDraggableTitleBar(),
          // Main content with sidebar
          Expanded(
            child: Row(
              children: [
                // Premium Sidebar Navigation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: _isExpanded ? 260 : 80,
                  child: _buildSidebar(isDark, selectedIndex),
                ),
                // Main content area
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.lightBackground,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isDark, int selectedIndex) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // App Header
          _buildHeader(isDark),

          const SizedBox(height: 8),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildNavItem(
                  index: 0,
                  icon: LucideIcons.layoutDashboard,
                  label: 'Dashboard',
                  route: AppRoutes.dashboard,
                  selectedIndex: selectedIndex,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 1,
                  icon: LucideIcons.arrowLeftRight,
                  label: 'Transactions',
                  route: AppRoutes.transactions,
                  selectedIndex: selectedIndex,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 2,
                  icon: LucideIcons.pieChart,
                  label: 'Insights',
                  route: AppRoutes.insights,
                  selectedIndex: selectedIndex,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 3,
                  icon: LucideIcons.repeat,
                  label: 'Subscriptions',
                  route: AppRoutes.subscriptions,
                  selectedIndex: selectedIndex,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 4,
                  icon: LucideIcons.banknote,
                  label: 'Debts',
                  route: AppRoutes.debts,
                  selectedIndex: selectedIndex,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 5,
                  icon: LucideIcons.calendarDays,
                  label: 'Monthly Details',
                  route: AppRoutes.monthlyInsights,
                  selectedIndex: selectedIndex,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 6,
                  icon: LucideIcons.fileSpreadsheet,
                  label: 'Bulk Entry',
                  route: AppRoutes.bulkEntry,
                  selectedIndex: selectedIndex,
                  isDark: isDark,
                ),

                const SizedBox(height: 16),

                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Divider(
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                ),

                const SizedBox(height: 16),

                _buildNavItem(
                  index: 7,
                  icon: LucideIcons.settings,
                  label: 'Settings',
                  route: AppRoutes.settings,
                  selectedIndex: selectedIndex,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Collapse Toggle
          _buildCollapseToggle(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isExpanded ? 20 : 16,
        vertical: 24,
      ),
      child: Row(
        children: [
          // App Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accentBlue,
                  AppColors.accentIndigo,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentBlue.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.wallet,
              color: Colors.white,
              size: 22,
            ),
          ),

          if (_isExpanded) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REE',
                    style: AppTypography.titleLarge(
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    'Kronbii',
                    style: AppTypography.caption(
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required String route,
    required int selectedIndex,
    required bool isDark,
  }) {
    final isSelected = index == selectedIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? 16 : 0,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? AppColors.accentBlue.withValues(alpha: 0.15)
                      : AppColors.accentBlue.withValues(alpha: 0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment:
                  _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected
                        ? AppColors.accentBlue
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.titleMedium(
                        isSelected
                            ? AppColors.accentBlue
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                      ).copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceHighlight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment:
                  _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  _isExpanded
                      ? LucideIcons.panelLeftClose
                      : LucideIcons.panelLeftOpen,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Collapse',
                    style: AppTypography.labelMedium(
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableTitleBar() {
    return MouseRegion(
      cursor: SystemMouseCursors.move,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) async {
          try {
            await windowManager.startDragging();
          } catch (e) {
            // If startDragging doesn't exist or window_manager is not available,
            // the window may still be draggable through the window manager
            // or we can ignore the error
          }
        },
        child: const WindowTitleBar(),
      ),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith(AppRoutes.transactions)) return 1;
    if (location.startsWith(AppRoutes.insights)) return 2;
    if (location.startsWith(AppRoutes.subscriptions)) return 3;
    if (location.startsWith(AppRoutes.debts)) return 4;
    if (location.startsWith(AppRoutes.monthlyInsights)) return 5;
    if (location.startsWith(AppRoutes.bulkEntry)) return 6;
    if (location.startsWith(AppRoutes.settings)) return 7;
    return 0; // Dashboard
  }
}

