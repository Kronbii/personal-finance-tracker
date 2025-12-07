import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Apple-style dropdown item
class AppleDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const AppleDropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// Premium Apple-style dropdown selector
/// Features smooth animations, blur effects, and elegant interactions
class AppleDropdown<T> extends StatefulWidget {
  final T value;
  final List<AppleDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final bool isDark;
  final IconData? leadingIcon;
  final double? width;
  final String? hint;
  final FocusNode? focusNode;
  final VoidCallback? onSubmitted;

  const AppleDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDark,
    this.leadingIcon,
    this.width,
    this.hint,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  State<AppleDropdown<T>> createState() => _AppleDropdownState<T>();
}

class _AppleDropdownState<T> extends State<AppleDropdown<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late FocusNode _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<double>(begin: -8, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Don't auto-open dropdown on focus - user must click/tap to open
    // This allows Enter key to skip dropdowns and navigate between text fields only
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    HapticFeedback.lightImpact();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
    setState(() => _isOpen = true);
  }

  Future<void> _closeDropdown() async {
    await _animationController.reverse();
    _removeOverlay();
    setState(() => _isOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectItem(T value) {
    HapticFeedback.selectionClick();
    widget.onChanged(value);
    _closeDropdown();
  }

  String get _selectedLabel {
    if (widget.items.isEmpty) {
      return widget.hint ?? '';
    }
    
    // Handle nullable types - check if value is null
    if (widget.value == null) {
      // Try to find a null item, otherwise return first item or hint
      try {
        final nullItem = widget.items.firstWhere((item) => item.value == null);
        return nullItem.label;
      } catch (e) {
        // No null item found, return hint or first item
        return widget.hint ?? widget.items.first.label;
      }
    }
    
    // Find matching item
    final item = widget.items.firstWhere(
      (item) => item.value == widget.value,
      orElse: () => widget.items.first,
    );
    return item.label;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Tap outside to close
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown menu
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 8,
            width: widget.width ?? size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              offset: Offset(0, size.height + 8),
              showWhenUnlinked: false,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) => Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      alignment: Alignment.topCenter,
                      child: child,
                    ),
                  ),
                ),
                child: _buildDropdownMenu(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownMenu() {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: widget.isDark
              ? AppColors.darkSurface.withValues(alpha: 0.98)
              : AppColors.lightSurface.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isDark
                ? AppColors.darkDivider.withValues(alpha: 0.5)
                : AppColors.lightDivider.withValues(alpha: 0.5),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.4 : 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.items.map((item) {
                final isSelected = item.value == widget.value;
                return _buildDropdownItem(item, isSelected);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownItem(AppleDropdownItem<T> item, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectItem(item.value),
        splashColor: AppColors.accentBlue.withValues(alpha: 0.1),
        highlightColor: AppColors.accentBlue.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentBlue.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.accentBlue
                      : (widget.isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  item.label,
                  style: AppTypography.bodyMedium(
                    isSelected
                        ? AppColors.accentBlue
                        : (widget.isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  LucideIcons.check,
                  size: 16,
                  color: AppColors.accentBlue,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      skipTraversal: false, // Allow focus but don't handle Enter
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            // If dropdown has focus and onSubmitted is provided, move to next field
            // This allows navigation to skip dropdowns when coming from text fields
            if (widget.onSubmitted != null && _focusNode.hasFocus) {
              widget.onSubmitted!();
              return KeyEventResult.handled;
            }
            // Otherwise, ignore Enter so text fields can handle it
            return KeyEventResult.ignored;
          } else if (_isOpen && event.logicalKey == LogicalKeyboardKey.escape) {
            _closeDropdown();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _isOpen
                ? (widget.isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightSurfaceHighlight)
                : (widget.isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.8)
                    : AppColors.lightSurface.withValues(alpha: 0.8)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isOpen
                  ? AppColors.accentBlue.withValues(alpha: 0.5)
                  : (widget.isDark
                      ? AppColors.darkDivider.withValues(alpha: 0.5)
                      : AppColors.lightDivider.withValues(alpha: 0.5)),
              width: _isOpen ? 1.5 : 1,
            ),
            boxShadow: _isOpen
                ? [
                    BoxShadow(
                      color: AppColors.accentBlue.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leadingIcon != null) ...[
                Icon(
                  widget.leadingIcon,
                  size: 18,
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 10),
              ],
              Text(
                _selectedLabel,
                style: AppTypography.titleMedium(
                  widget.isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: _isOpen
                      ? AppColors.accentBlue
                      : (widget.isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Apple-style segmented month/year selector with navigation arrows
class AppleDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final bool isDark;
  final bool showMonth;
  final bool showYear;

  const AppleDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.isDark,
    this.showMonth = true,
    this.showYear = true,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (i) => currentYear - i);
    final months = List.generate(12, (i) => i + 1);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.9)
            : AppColors.lightSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkDivider.withValues(alpha: 0.5)
              : AppColors.lightDivider.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Previous button
          _buildNavButton(
            icon: LucideIcons.chevronLeft,
            onTap: () {
              HapticFeedback.lightImpact();
              final newDate = DateTime(
                selectedDate.year,
                selectedDate.month - 1,
                1,
              );
              onDateChanged(newDate);
            },
          ),
          const SizedBox(width: 4),
          // Month dropdown
          if (showMonth)
            AppleDropdown<int>(
              value: selectedDate.month,
              isDark: isDark,
              items: months
                  .map((m) => AppleDropdownItem(
                        value: m,
                        label: _getMonthName(m),
                      ))
                  .toList(),
              onChanged: (value) {
                onDateChanged(DateTime(selectedDate.year, value, 1));
              },
            ),
          if (showMonth && showYear) const SizedBox(width: 8),
          // Year dropdown
          if (showYear)
            AppleDropdown<int>(
              value: selectedDate.year,
              isDark: isDark,
              items: years
                  .map((y) => AppleDropdownItem(
                        value: y,
                        label: y.toString(),
                      ))
                  .toList(),
              onChanged: (value) {
                onDateChanged(DateTime(value, selectedDate.month, 1));
              },
            ),
          const SizedBox(width: 4),
          // Next button
          _buildNavButton(
            icon: LucideIcons.chevronRight,
            onTap: () {
              HapticFeedback.lightImpact();
              final newDate = DateTime(
                selectedDate.year,
                selectedDate.month + 1,
                1,
              );
              onDateChanged(newDate);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: AppColors.accentBlue.withValues(alpha: 0.1),
        highlightColor: AppColors.accentBlue.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
