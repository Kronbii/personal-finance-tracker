import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../data/services/currency_formatter.dart';
import '../../../data/providers/currency_provider.dart';
import '../../widgets/category_pie_chart.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/sync_button.dart';
import '../../widgets/wallet_card.dart';
import 'providers/dashboard_providers.dart';

/// Dashboard screen - Main overview of financial data
/// Features: Total savings, monthly income/expenses, category breakdown, wallet cards
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // Header with title and sync button
          SliverToBoxAdapter(
            child: _buildHeader(isDark),
          ),

          // Main content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary stats row
                  _buildSummaryStats(isDark),

                  const SizedBox(height: 24),

                  // Monthly summary text
                  _buildMonthlySummary(isDark),

                  const SizedBox(height: 32),

                  // Category breakdown and wallets row
                  _buildMainContent(isDark),

                  const SizedBox(height: 32),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: AppTypography.displaySmall(
                    isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
                const SizedBox(height: 8),
                Text(
                  _getGreeting(),
                  style: AppTypography.bodyMedium(
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),
          SyncButton(
            onPressed: _handleSync,
            isLoading: _isSyncing,
            lastSyncTime: _lastSyncTime,
            isDark: isDark,
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(bool isDark) {
    final allTimeSavings = ref.watch(allTimeSavingsProvider);
    final monthlyIncome = ref.watch(monthlyIncomeProvider);
    final monthlyExpenses = ref.watch(monthlyExpensesProvider);

    return Row(
      children: [
        // Total savings card with gradient
        Expanded(
          flex: 2,
          child: allTimeSavings.when(
            data: (savings) => StatCard(
              title: 'Total Savings',
              value: _formatCurrency(savings),
              subtitle: 'All-time net savings',
              icon: LucideIcons.piggyBank,
              iconColor: AppColors.savings,
              gradientColors: AppColors.savingsGradient,
              isDark: isDark,
            ),
            loading: () => _buildLoadingCard(isDark),
            error: (_, __) => _buildErrorCard(isDark, 'Unable to load'),
          ),
        ),
        const SizedBox(width: 16),

        // Monthly income
        Expanded(
          child: monthlyIncome.when(
            data: (income) => StatCard(
              title: 'Income',
              value: _formatCurrency(income),
              subtitle: _getCurrentMonthName(),
              icon: LucideIcons.trendingUp,
              iconColor: AppColors.income,
              isDark: isDark,
            ),
            loading: () => _buildLoadingCard(isDark),
            error: (_, __) => _buildErrorCard(isDark, 'Error'),
          ),
        ),
        const SizedBox(width: 16),

        // Monthly expenses
        Expanded(
          child: monthlyExpenses.when(
            data: (expenses) => StatCard(
              title: 'Expenses',
              value: _formatCurrency(expenses),
              subtitle: _getCurrentMonthName(),
              icon: LucideIcons.trendingDown,
              iconColor: AppColors.expense,
              isDark: isDark,
            ),
            loading: () => _buildLoadingCard(isDark),
            error: (_, __) => _buildErrorCard(isDark, 'Error'),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySummary(bool isDark) {
    final monthlyIncome = ref.watch(monthlyIncomeProvider);
    final monthlyExpenses = ref.watch(monthlyExpensesProvider);

    return monthlyIncome.when(
      data: (income) => monthlyExpenses.when(
        data: (expenses) {
          final netBalance = income - expenses;
          final isPositive = netBalance >= 0;

          return Container(
            padding: const EdgeInsets.all(20),
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isPositive ? AppColors.income : AppColors.expense)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isPositive
                        ? LucideIcons.arrowUpCircle
                        : LucideIcons.arrowDownCircle,
                    size: 24,
                    color: isPositive ? AppColors.income : AppColors.expense,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Summary',
                        style: AppTypography.titleMedium(
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.bodyMedium(
                            isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: isPositive
                                  ? "You're saving "
                                  : "You're overspending by ",
                            ),
                            TextSpan(
                              text: _formatCurrency(netBalance.abs()),
                              style: AppTypography.titleMedium(
                                isPositive
                                    ? AppColors.income
                                    : AppColors.expense,
                              ),
                            ),
                            TextSpan(
                              text: isPositive
                                  ? ' this month. Keep it up! 🎉'
                                  : ' this month. Consider reviewing expenses.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Net Balance',
                      style: AppTypography.caption(
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isPositive ? '+' : ''}${_formatCurrency(netBalance)}',
                      style: AppTypography.moneyMedium(
                        isPositive ? AppColors.income : AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
        },
        loading: () => _buildLoadingCard(isDark),
        error: (_, __) => _buildErrorCard(isDark, 'Unable to calculate'),
      ),
      loading: () => _buildLoadingCard(isDark),
      error: (_, __) => _buildErrorCard(isDark, 'Unable to calculate'),
    );
  }

  Widget _buildMainContent(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category breakdown chart
        Expanded(
          flex: 3,
          child: _buildCategoryBreakdown(isDark),
        ),
        const SizedBox(width: 24),

        // Wallets section
        Expanded(
          flex: 2,
          child: _buildWalletsSection(isDark),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(bool isDark) {
    final spendingByCategory = ref.watch(monthlySpendingByCategoryProvider);
    final categoryMap = ref.watch(categoryMapProvider);

    return spendingByCategory.when(
      data: (spending) => categoryMap.when(
        data: (categories) {
          final chartData = spending.entries.map((entry) {
            final category = categories[entry.key];
            return CategoryChartData(
              id: entry.key,
              name: category?.name ?? 'Unknown',
              amount: entry.value,
              color: _parseHexColor(category?.colorHex ?? '#8E8E93'),
              iconName: category?.iconName ?? 'circle',
            );
          }).toList();

          final total = spending.values.fold(0.0, (sum, val) => sum + val);

          return CategoryPieChart(
            data: chartData,
            totalAmount: total,
            isDark: isDark,
            centerLabel: 'Spent',
            centerValue: _formatCurrency(total),
          );
        },
        loading: () => _buildLoadingCard(isDark, height: 280),
        error: (_, __) => _buildErrorCard(isDark, 'Unable to load categories'),
      ),
      loading: () => _buildLoadingCard(isDark, height: 280),
      error: (_, __) => _buildErrorCard(isDark, 'Unable to load spending data'),
    );
  }

  Widget _buildWalletsSection(bool isDark) {
    final wallets = ref.watch(walletsProvider);
    final balances = ref.watch(walletBalancesProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Wallets',
                  style: AppTypography.titleLarge(
                    isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Navigate to add wallet
                },
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          wallets.when(
            data: (walletList) {
              if (walletList.isEmpty) {
                return _buildEmptyWalletsState(isDark);
              }

              return balances.when(
                data: (balanceMap) {
                  return Column(
                    children: walletList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final wallet = entry.value;
                      final balance = balanceMap[wallet.id] ?? 0.0;

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < walletList.length - 1 ? 12 : 0,
                        ),
                        child: WalletCard(
                          name: wallet.name,
                          balance: balance,
                          currency: wallet.currency,
                          gradientIndex: wallet.gradientIndex,
                          isCompact: true,
                          animationDelay: 400 + (index * 100),
                          onTap: () {
                            // TODO: Navigate to wallet details
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => _buildLoadingCard(isDark, height: 100),
                error: (_, __) => _buildErrorCard(isDark, 'Error'),
              );
            },
            loading: () => _buildLoadingCard(isDark, height: 150),
            error: (_, __) => _buildErrorCard(isDark, 'Unable to load wallets'),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildEmptyWalletsState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            LucideIcons.wallet,
            size: 48,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No wallets yet',
            style: AppTypography.titleMedium(
              isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a wallet to start tracking',
            style: AppTypography.bodySmall(
              isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to add wallet
            },
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Wallet'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark, {double height = 120}) {
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
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(
              isDark ? AppColors.accentBlue : AppColors.accentBlue,
            ),
          ),
        ),
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
          Icon(
            LucideIcons.alertCircle,
            size: 20,
            color: AppColors.accentRed,
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: AppTypography.bodyMedium(AppColors.accentRed),
          ),
        ],
      ),
    );
  }

  void _handleSync() async {
    setState(() => _isSyncing = true);

    // Simulate sync - will be replaced with actual Supabase sync
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSyncing = false;
      _lastSyncTime = DateTime.now();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.check, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Text(
                'Sync completed successfully',
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning! Here\'s your financial overview.';
    } else if (hour < 17) {
      return 'Good afternoon! Here\'s your financial overview.';
    } else {
      return 'Good evening! Here\'s your financial overview.';
    }
  }

  String _getCurrentMonthName() {
    return DateFormat('MMMM yyyy').format(DateTime.now());
  }

  String _formatCurrency(double amount) {
    final currencySettings = ref.watch(currencySettingsProvider);
    return currencySettings.when(
      data: (settings) {
        final formatted = CurrencyFormatter.format(
          amount,
          currencyCode: settings.currencyCode,
          conversionRate: settings.conversionRate != 1.0
              ? settings.conversionRate
              : null,
        );
        // Add sign for negative amounts
        if (amount < 0 && !formatted.startsWith('-')) {
          return '-$formatted';
        }
        return formatted;
      },
      loading: () => CurrencyFormatter.format(amount),
      error: (_, __) => CurrencyFormatter.format(amount),
    );
  }

  Color _parseHexColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return AppColors.accentBlue;
  }
}
