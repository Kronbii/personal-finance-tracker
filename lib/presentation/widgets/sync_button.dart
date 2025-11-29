import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Premium sync button with loading state
class SyncButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final DateTime? lastSyncTime;
  final bool isDark;

  const SyncButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.lastSyncTime,
    this.isDark = true,
  });

  @override
  State<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SyncButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isLoading && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.isLoading ? null : widget.onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightSurfaceHighlight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.accentBlue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _controller,
                child: Icon(
                  LucideIcons.refreshCw,
                  size: 18,
                  color: AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.isLoading ? 'Syncing...' : 'Sync Now',
                    style: AppTypography.labelMedium(AppColors.accentBlue),
                  ),
                  if (widget.lastSyncTime != null && !widget.isLoading)
                    Text(
                      _formatLastSync(widget.lastSyncTime!),
                      style: AppTypography.caption(
                        widget.isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastSync(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

