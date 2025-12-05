import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../data/drift/database.dart';
import '../../../data/drift/tables/debts_table.dart';
import '../../../data/services/currency_formatter.dart';
import '../../../data/providers/currency_provider.dart';
import '../../widgets/stat_card.dart';
import '../insights/providers/insights_providers.dart';
import '../insights/widgets/add_debt_modal.dart';

/// Debts screen - Manage money you owe or are owed
class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final debts = ref.watch(activeDebtsProvider);
    final totalOwed = ref.watch(totalOwedProvider);
    final totalLent = ref.watch(totalLentProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDebt(context, ref),
        backgroundColor: AppColors.accentBlue,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(
          'Add Debt',
          style: AppTypography.labelMedium(Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(isDark),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: totalOwed.when(
                          data: (amount) => CompactStatCard(
                            title: 'You Owe',
                            value: _formatCurrency(amount, ref),
                            icon: LucideIcons.arrowUpRight,
                            color: AppColors.expense,
                            isDark: isDark,
                          ),
                          loading: () => _buildLoadingCard(isDark, height: 80),
                          error: (_, __) => _buildErrorCard(isDark, 'Error'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: totalLent.when(
                          data: (amount) => CompactStatCard(
                            title: 'Owed to You',
                            value: _formatCurrency(amount, ref),
                            icon: LucideIcons.arrowDownLeft,
                            color: AppColors.income,
                            isDark: isDark,
                          ),
                          loading: () => _buildLoadingCard(isDark, height: 80),
                          error: (_, __) => _buildErrorCard(isDark, 'Error'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Debts list
                  debts.when(
                    data: (debtList) {
                      if (debtList.isEmpty) {
                        return _buildEmptyState(isDark);
                      }

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkDivider
                                : AppColors.lightDivider,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Debts',
                              style: AppTypography.titleLarge(
                                isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...debtList.map((debt) =>
                                _buildDebtItem(debt, ref, isDark, context)),
                          ],
                        ),
                      );
                    },
                    loading: () => _buildLoadingCard(isDark),
                    error: (_, __) => _buildErrorCard(isDark, 'Error loading debts'),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debts',
            style: AppTypography.displaySmall(
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 8),
          Text(
            'Track money you owe or are owed',
            style: AppTypography.bodyMedium(
              isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildDebtItem(
    DebtEntity debt,
    WidgetRef ref,
    bool isDark,
    BuildContext context,
  ) {
    final isOwed = debt.type == DebtType.owed;
    final progress = 1 - (debt.remainingAmount / debt.originalAmount);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showEditDebt(context, ref, debt),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isOwed ? AppColors.expense : AppColors.income)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isOwed ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                    size: 20,
                    color: isOwed ? AppColors.expense : AppColors.income,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.personName,
                        style: AppTypography.titleMedium(
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        isOwed ? 'You owe' : 'Owes you',
                        style: AppTypography.caption(
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatCurrency(debt.remainingAmount, ref),
                  style: AppTypography.moneySmall(
                    isOwed ? AppColors.expense : AppColors.income,
                  ),
                ),
              ],
            ),
            if (debt.dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    LucideIcons.calendar,
                    size: 14,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Due: ${DateFormat('MMM d, yyyy').format(debt.dueDate!)}',
                    style: AppTypography.caption(
                      isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightSurfaceHighlight,
                valueColor: AlwaysStoppedAnimation(
                  isOwed ? AppColors.expense : AppColors.income,
                ),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark, {double height = 200}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 1,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorCard(bool isDark, String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentRed.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, color: AppColors.accentRed),
          const SizedBox(width: 12),
          Text(message, style: AppTypography.bodyMedium(AppColors.accentRed)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              LucideIcons.banknote,
              size: 48,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No active debts',
              style: AppTypography.titleMedium(
                isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track money you owe or are owed',
              style: AppTypography.bodySmall(
                isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDebt(BuildContext context, WidgetRef ref) async {
    final result = await AddDebtModal.show(context);
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.check, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Text(
                'Debt added successfully',
                style: AppTypography.bodyMedium(Colors.white),
              ),
            ],
          ),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _showEditDebt(
    BuildContext context,
    WidgetRef ref,
    DebtEntity debt,
  ) async {
    final result = await AddDebtModal.show(
      context,
      existingDebt: debt,
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.check, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Text(
                'Debt updated successfully',
                style: AppTypography.bodyMedium(Colors.white),
              ),
            ],
          ),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  String _formatCurrency(double amount, WidgetRef ref) {
    final currencySettings = ref.watch(currencySettingsProvider);
    return currencySettings.when(
      data: (settings) => CurrencyFormatter.format(
        amount,
        currencyCode: settings.currencyCode,
        conversionRate: settings.conversionRate != 1.0
            ? settings.conversionRate
            : null,
      ),
      loading: () => CurrencyFormatter.format(amount),
      error: (_, __) => CurrencyFormatter.format(amount),
    );
  }
}

