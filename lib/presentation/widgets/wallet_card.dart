import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../data/services/currency_formatter.dart';

/// Premium wallet card with gradient background
/// Displays wallet name, balance, and currency
class WalletCard extends StatelessWidget {
  final String name;
  final double balance;
  final String currency;
  final int gradientIndex;
  final VoidCallback? onTap;
  final bool isCompact;
  final bool isFullWidth;
  final int animationDelay;

  const WalletCard({
    super.key,
    required this.name,
    required this.balance,
    this.currency = 'USD',
    this.gradientIndex = 0,
    this.onTap,
    this.isCompact = false,
    this.isFullWidth = false,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = AppColors.getWalletGradient(gradientIndex);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: isFullWidth ? double.infinity : (isCompact ? 180 : 240),
          padding: EdgeInsets.all(isFullWidth ? 24 : (isCompact ? 16 : 20)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: isFullWidth
              ? Row(
                  children: [
                    // Icon section
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        LucideIcons.wallet,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Content section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: AppTypography.titleMedium(Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  currency,
                                  style: AppTypography.labelSmall(Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatCurrency(balance, currency),
                            style: AppTypography.moneyLarge(Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Chevron icon
                    Icon(
                      LucideIcons.chevronRight,
                      size: 24,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: isCompact ? 32 : 40,
                          height: isCompact ? 32 : 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
                          ),
                          child: Icon(
                            LucideIcons.wallet,
                            size: isCompact ? 16 : 20,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            currency,
                            style: AppTypography.labelSmall(Colors.white),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isCompact ? 12 : 20),
                    Text(
                      name,
                      style: AppTypography.labelMedium(
                        Colors.white.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(balance, currency),
                      style: isCompact
                          ? AppTypography.moneySmall(Colors.white)
                          : AppTypography.moneyMedium(Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isCompact) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Spacer(),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.2, end: 0);
  }

  String _formatCurrency(double amount, String currency) {
    return CurrencyFormatter.format(amount, currencyCode: currency);
  }
}

/// Add wallet card with plus icon
class AddWalletCard extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isCompact;

  const AddWalletCard({
    super.key,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: isCompact ? 100 : 140,
          padding: EdgeInsets.all(isCompact ? 16 : 20),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.darkDivider,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.plus,
                  size: 24,
                  color: AppColors.accentBlue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Add Wallet',
                style: AppTypography.labelMedium(AppColors.accentBlue),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

