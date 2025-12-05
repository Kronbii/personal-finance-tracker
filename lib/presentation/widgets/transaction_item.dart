import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../data/drift/tables/transactions_table.dart';
import '../../data/services/currency_formatter.dart';

/// Premium transaction list item
/// Displays transaction with category icon, amount, and details
class TransactionItem extends StatelessWidget {
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final String? walletName;
  final String? toWalletName;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? note;
  final bool isDark;
  final VoidCallback? onTap;
  final int animationDelay;

  const TransactionItem({
    super.key,
    required this.categoryName,
    this.categoryIcon = 'circle',
    this.categoryColor = '#0A84FF',
    this.walletName,
    this.toWalletName,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    this.isDark = true,
    this.onTap,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor();
    final iconData = _getIconData(categoryIcon);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _parseHexColor(categoryColor).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  iconData,
                  size: 22,
                  color: _parseHexColor(categoryColor),
                ),
              ),
              const SizedBox(width: 16),

              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type == TransactionType.transfer
                          ? 'Transfer'
                          : categoryName,
                      style: AppTypography.titleMedium(
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (note != null && note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        note!,
                        style: AppTypography.bodySmall(
                          isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_getAmountPrefix()}${_formatCurrency(amount)}',
                    style: AppTypography.moneySmall(color),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getTypeLabel(),
                      style: AppTypography.labelSmall(color),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0);
  }

  String _getAmountPrefix() {
    switch (type) {
      case TransactionType.income:
        return '+';
      case TransactionType.expense:
        return '-';
      case TransactionType.transfer:
        return '';
    }
  }

  String _getTypeLabel() {
    switch (type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  Color _getTypeColor() {
    switch (type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.transfer:
        return AppColors.transfer;
    }
  }

  String _formatCurrency(double amount) {
    // Use default currency formatting (can be enhanced with provider later)
    return CurrencyFormatter.format(amount, currencyCode: 'USD');
  }

  Color _parseHexColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return AppColors.accentBlue;
  }

  IconData _getIconData(String iconName) {
    const iconMap = {
      'utensils': LucideIcons.utensils,
      'car': LucideIcons.car,
      'shopping-bag': LucideIcons.shoppingBag,
      'file-text': LucideIcons.fileText,
      'gamepad-2': LucideIcons.gamepad2,
      'heart-pulse': LucideIcons.heartPulse,
      'graduation-cap': LucideIcons.graduationCap,
      'plane': LucideIcons.plane,
      'more-horizontal': LucideIcons.moreHorizontal,
      'briefcase': LucideIcons.briefcase,
      'laptop': LucideIcons.laptop,
      'trending-up': LucideIcons.trendingUp,
      'gift': LucideIcons.gift,
      'rotate-ccw': LucideIcons.rotateCcw,
      'plus-circle': LucideIcons.plusCircle,
      'wallet': LucideIcons.wallet,
      'circle': LucideIcons.circle,
      'repeat': LucideIcons.repeat,
      'arrow-right-left': LucideIcons.arrowRightLeft,
      'book': LucideIcons.book,
      'film': LucideIcons.film,
      'zap': LucideIcons.zap,
      'droplet': LucideIcons.droplet,
      'wifi': LucideIcons.wifi,
      'phone': LucideIcons.phone,
      'shirt': LucideIcons.shirt,
      'baby': LucideIcons.baby,
      'dog': LucideIcons.dog,
      'fuel': LucideIcons.fuel,
      'lightbulb': LucideIcons.lightbulb,
      'battery': LucideIcons.battery,
      'battery-charging': LucideIcons.batteryCharging,
      'plug': LucideIcons.plug,
      'plug-zap': LucideIcons.plugZap,
      'power': LucideIcons.power,
    };
    return iconMap[iconName] ?? LucideIcons.circle;
  }
}

/// Day header for grouped transactions
class TransactionDayHeader extends StatelessWidget {
  final DateTime date;
  final double totalAmount;
  final bool isDark;

  const TransactionDayHeader({
    super.key,
    required this.date,
    required this.totalAmount,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            _formatDate(date),
            style: AppTypography.titleSmall(
              isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const Spacer(),
          Text(
            _formatCurrency(totalAmount),
            style: AppTypography.labelMedium(
              totalAmount >= 0 ? AppColors.income : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return '${_getMonthName(date.month)} ${date.day}';
    } else {
      return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _formatCurrency(double amount) {
    final formatted = amount.abs().toStringAsFixed(2);
    final sign = amount >= 0 ? '+' : '-';
    return '$sign\$$formatted';
  }
}

