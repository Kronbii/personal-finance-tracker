import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/theme_provider.dart';

/// Custom Apple-style window title bar with traffic light buttons
class WindowTitleBar extends ConsumerStatefulWidget {
  const WindowTitleBar({super.key});

  @override
  ConsumerState<WindowTitleBar> createState() => _WindowTitleBarState();
}

class _WindowTitleBarState extends ConsumerState<WindowTitleBar>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    try {
      windowManager.addListener(this);
      _checkMaximized();
    } catch (e) {
      // Ignore if window_manager is not available
    }
  }

  @override
  void dispose() {
    try {
      windowManager.removeListener(this);
    } catch (e) {
      // Ignore if window_manager is not available
    }
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  Future<void> _checkMaximized() async {
    try {
      final isMaximized = await windowManager.isMaximized();
      if (mounted) {
        setState(() => _isMaximized = isMaximized);
      }
    } catch (e) {
      // Ignore if window_manager is not available
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Apple-style traffic light buttons
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                _buildTrafficLightButton(
                  color: const Color(0xFFFF5F57), // Red - Close
                  onTap: () async {
                    try {
                      await windowManager.close();
                    } catch (e) {
                      // Ignore if not available
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildTrafficLightButton(
                  color: const Color(0xFFFFBD2E), // Yellow - Minimize
                  onTap: () async {
                    try {
                      await windowManager.minimize();
                    } catch (e) {
                      // Ignore if not available
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildTrafficLightButton(
                  color: const Color(0xFF28CA42), // Green - Maximize/Restore
                  onTap: () async {
                    try {
                      if (_isMaximized) {
                        await windowManager.restore();
                      } else {
                        await windowManager.maximize();
                      }
                    } catch (e) {
                      // Ignore if not available
                    }
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          // Window title
          Text(
            'REE',
            style: AppTypography.bodySmall(
              isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const Spacer(),
          // Spacer to balance the traffic lights
          const SizedBox(width: 100),
        ],
      ),
    );
  }

  Widget _buildTrafficLightButton({
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.2),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

