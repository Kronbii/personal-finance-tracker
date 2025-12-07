import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../app/utils/responsive.dart';
import '../../../data/drift/database.dart';
import '../../../data/drift/daos/transactions_dao.dart';
import '../../../data/drift/tables/transactions_table.dart';
import '../../../data/services/currency_formatter.dart';
import '../../../data/providers/currency_provider.dart';
import '../../widgets/apple_dropdown.dart';
import '../../widgets/category_pie_chart.dart';
import '../../widgets/stat_card.dart';
import '../settings/widgets/manage_wallet_balances_modal.dart';
import '../dashboard/providers/dashboard_providers.dart';
import 'providers/monthly_insights_providers.dart';

/// Monthly Insights Screen - Detailed view of a specific month's finances
class MonthlyInsightsScreen extends ConsumerWidget {
  const MonthlyInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // Header with month selector
          SliverToBoxAdapter(
            child: _buildHeader(context, ref, isDark, selectedMonth),
          ),

          // Summary cards
          SliverPadding(
            padding: Responsive.horizontalPaddingInsets(context),
            sliver: SliverToBoxAdapter(
              child: _buildSummaryCards(ref, isDark),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: Responsive.rowSpacing(context))),

          // Wallet balances section
          SliverPadding(
            padding: Responsive.horizontalPaddingInsets(context),
            sliver: SliverToBoxAdapter(
              child: _buildWalletBalancesSection(context, ref, isDark, selectedMonth),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: Responsive.rowSpacing(context))),

          // Category breakdowns
          SliverPadding(
            padding: Responsive.horizontalPaddingInsets(context),
            sliver: SliverToBoxAdapter(
              child: _buildCategoryBreakdowns(ref, isDark),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: Responsive.rowSpacing(context))),

          // Detailed stats
          SliverPadding(
            padding: Responsive.horizontalPaddingInsets(context),
            sliver: SliverToBoxAdapter(
              child: _buildDetailedStats(ref, isDark),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: Responsive.rowSpacing(context))),

          // Income breakdown section
          SliverPadding(
            padding: Responsive.horizontalPaddingInsets(context),
            sliver: SliverToBoxAdapter(
              child: _buildIncomeBreakdownSection(ref, isDark),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Top transactions
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            sliver: SliverToBoxAdapter(
              child: _buildTopTransactions(ref, isDark),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    DateTime selectedMonth,
  ) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Details',
                      style: AppTypography.displaySmall(
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      'Detailed breakdown of your finances',
                      style: AppTypography.bodyMedium(
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
                  ],
                ),
              ),
              // Month/Year selector
              _buildMonthYearSelector(context, ref, isDark, selectedMonth),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthYearSelector(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    DateTime selectedMonth,
  ) {
    return AppleDateSelector(
      selectedDate: selectedMonth,
      isDark: isDark,
      onDateChanged: (newDate) {
        ref.read(selectedMonthProvider.notifier).setMonth(newDate);
      },
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildSummaryCards(WidgetRef ref, bool isDark) {
    final monthSummary = ref.watch(monthSummaryProvider);

    return monthSummary.when(
      data: (summary) => Row(
        children: [
          Expanded(
            child: StatCard(
              title: 'Total Income',
              value: _formatCurrency(summary.totalIncome, ref),
              subtitle: 'This month',
              icon: LucideIcons.trendingUp,
              iconColor: AppColors.income,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: StatCard(
              title: 'Total Expenses',
              value: _formatCurrency(summary.totalExpenses, ref),
              subtitle: 'This month',
              icon: LucideIcons.trendingDown,
              iconColor: AppColors.expense,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: StatCard(
              title: 'Net Savings',
              value: _formatCurrency(summary.netSavings, ref),
              subtitle: summary.netSavings >= 0 ? 'Saved' : 'Overspent',
              icon: LucideIcons.piggyBank,
              iconColor: summary.netSavings >= 0
                  ? AppColors.savings
                  : AppColors.expense,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: StatCard(
              title: 'Transactions',
              value: summary.transactionCount.toString(),
              subtitle: 'Total count',
              icon: LucideIcons.receipt,
              iconColor: AppColors.accentBlue,
              isDark: isDark,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
      loading: () => _buildLoadingRow(isDark, 4),
      error: (_, __) => _buildErrorCard(isDark, 'Unable to load summary'),
    );
  }

  Widget _buildCategoryBreakdowns(WidgetRef ref, bool isDark) {
    final expensesByCategory = ref.watch(monthExpensesByCategoryProvider);
    final incomeByCategory = ref.watch(monthIncomeByCategoryProvider);
    final categoryMap = ref.watch(monthCategoryMapProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expense breakdown
        Expanded(
          child: _buildCategoryCard(
            isDark: isDark,
            title: 'Expense Breakdown',
            icon: LucideIcons.trendingDown,
            iconColor: AppColors.expense,
            dataAsync: expensesByCategory,
            categoryMapAsync: categoryMap,
            ref: ref,
          ),
        ),
        const SizedBox(width: 24),
        // Income breakdown
        Expanded(
          child: _buildCategoryCard(
            isDark: isDark,
            title: 'Income Breakdown',
            icon: LucideIcons.trendingUp,
            iconColor: AppColors.income,
            dataAsync: incomeByCategory,
            categoryMapAsync: categoryMap,
            ref: ref,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required AsyncValue<Map<String, double>> dataAsync,
    required AsyncValue<Map<String, CategoryEntity>> categoryMapAsync,
    required WidgetRef ref,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTypography.titleLarge(
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          dataAsync.when(
            data: (spending) => categoryMapAsync.when(
              data: (categories) {
                if (spending.isEmpty) {
                  return _buildEmptyState(isDark, 'No data for this month');
                }

                final chartData = spending.entries.map((entry) {
                  final category = categories[entry.key];
                  return CategoryChartData(
                    id: entry.key,
                    name: category?.name ?? 'Unknown',
                    amount: entry.value,
                    color: _parseHexColor(category?.colorHex ?? '#8E8E93'),
                  );
                }).toList();

                final total = spending.values.fold(0.0, (sum, val) => sum + val);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 160,
                      child: CategoryPieChart(
                        data: chartData,
                        totalAmount: total,
                        isDark: isDark,
                        centerLabel: title.contains('Expense') ? 'Expenses' : 'Income',
                        centerValue: _formatCurrency(total, ref),
                        showContainer: false,
                        showLegend: false,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Limited to 4 categories to prevent overflow
                    ...chartData.take(4).map((item) => _buildCategoryRow(
                          isDark: isDark,
                          name: item.name,
                          amount: item.amount,
                          color: item.color,
                          percentage: total > 0 ? (item.amount / total * 100) : 0.0,
                          ref: ref,
                        )),
                    if (chartData.length > 4)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+${chartData.length - 4} more categories',
                          style: AppTypography.caption(
                            isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildEmptyState(isDark, 'Error loading data'),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => _buildEmptyState(isDark, 'Error loading data'),
          ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildCategoryRow({
    required bool isDark,
    required String name,
    required double amount,
    required Color color,
    required double percentage,
    required WidgetRef ref,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: AppTypography.bodyMedium(
                isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: AppTypography.caption(
              isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatCurrency(amount, ref),
            style: AppTypography.moneySmall(
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(WidgetRef ref, bool isDark) {
    final monthSummary = ref.watch(monthSummaryProvider);
    final dailyAverage = ref.watch(dailyAverageProvider);
    final comparisonData = ref.watch(monthComparisonProvider);

    return Container(
      padding: const EdgeInsets.all(24),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.barChart3,
                  size: 20,
                  color: AppColors.accentPurple,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Detailed Statistics',
                style: AppTypography.titleLarge(
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: dailyAverage.when(
                  data: (avg) => _buildStatItem(
                    isDark: isDark,
                    label: 'Daily Avg Spending',
                    value: _formatCurrency(avg.avgExpense, ref),
                    icon: LucideIcons.calendar,
                    color: AppColors.expense,
                  ),
                  loading: () => _buildStatItemLoading(isDark),
                  error: (_, __) => _buildStatItem(
                    isDark: isDark,
                    label: 'Daily Avg Spending',
                    value: '-',
                    icon: LucideIcons.calendar,
                    color: AppColors.expense,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: dailyAverage.when(
                  data: (avg) => _buildStatItem(
                    isDark: isDark,
                    label: 'Daily Avg Income',
                    value: _formatCurrency(avg.avgIncome, ref),
                    icon: LucideIcons.calendar,
                    color: AppColors.income,
                  ),
                  loading: () => _buildStatItemLoading(isDark),
                  error: (_, __) => _buildStatItem(
                    isDark: isDark,
                    label: 'Daily Avg Income',
                    value: '-',
                    icon: LucideIcons.calendar,
                    color: AppColors.income,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: monthSummary.when(
                  data: (summary) => _buildStatItem(
                    isDark: isDark,
                    label: 'Savings Rate',
                    value: summary.totalIncome > 0
                        ? '${(summary.netSavings / summary.totalIncome * 100).toStringAsFixed(1)}%'
                        : '0%',
                    icon: LucideIcons.percent,
                    color: AppColors.savings,
                  ),
                  loading: () => _buildStatItemLoading(isDark),
                  error: (_, __) => _buildStatItem(
                    isDark: isDark,
                    label: 'Savings Rate',
                    value: '-',
                    icon: LucideIcons.percent,
                    color: AppColors.savings,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: comparisonData.when(
                  data: (comparison) => _buildStatItem(
                    isDark: isDark,
                    label: 'vs Last Month',
                    value: comparison.expenseChange >= 0
                        ? '+${comparison.expenseChange.toStringAsFixed(1)}%'
                        : '${comparison.expenseChange.toStringAsFixed(1)}%',
                    icon: comparison.expenseChange >= 0
                        ? LucideIcons.trendingUp
                        : LucideIcons.trendingDown,
                    color: comparison.expenseChange >= 0
                        ? AppColors.expense
                        : AppColors.income,
                  ),
                  loading: () => _buildStatItemLoading(isDark),
                  error: (_, __) => _buildStatItem(
                    isDark: isDark,
                    label: 'vs Last Month',
                    value: '-',
                    icon: LucideIcons.minus,
                    color: AppColors.accentBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildStatItem({
    required bool isDark,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceHighlight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.caption(
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.titleLarge(
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItemLoading(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceHighlight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildTopTransactions(WidgetRef ref, bool isDark) {
    final topExpenses = ref.watch(topMonthExpensesProvider);
    final topIncomes = ref.watch(topMonthIncomesProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTransactionList(
            isDark: isDark,
            title: 'Top Expenses',
            icon: LucideIcons.arrowUpRight,
            iconColor: AppColors.expense,
            transactionsAsync: topExpenses,
            ref: ref,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildTransactionList(
            isDark: isDark,
            title: 'Top Income',
            icon: LucideIcons.arrowDownLeft,
            iconColor: AppColors.income,
            transactionsAsync: topIncomes,
            ref: ref,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required AsyncValue<List<TransactionWithDetails>> transactionsAsync,
    required WidgetRef ref,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTypography.titleLarge(
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return _buildEmptyState(isDark, 'No transactions');
              }

              return Column(
                children: transactions
                    .map((tx) => _buildTransactionItem(isDark, tx, ref))
                    .toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => _buildEmptyState(isDark, 'Error loading data'),
          ),
        ],
      ),
    ).animate(delay: 500.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildTransactionItem(
    bool isDark,
    TransactionWithDetails tx,
    WidgetRef ref,
  ) {
    final color = _parseHexColor(tx.category?.colorHex ?? '#8E8E93');
    final isExpense = tx.transaction.type == TransactionType.expense;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconForCategory(tx.category?.iconName),
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.transaction.note ?? tx.category?.name ?? 'Transaction',
                  style: AppTypography.titleMedium(
                    isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(tx.transaction.date),
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
            '${isExpense ? '-' : '+'}${_formatCurrency(tx.transaction.amount, ref)}',
            style: AppTypography.moneySmall(
              isExpense ? AppColors.expense : AppColors.income,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingRow(bool isDark, int count) {
    return Row(
      children: List.generate(
        count,
        (index) => Expanded(
          child: Container(
            height: 120,
            margin: EdgeInsets.only(right: index < count - 1 ? 16 : 0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: CircularProgressIndicator()),
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
          const Icon(LucideIcons.alertCircle, color: AppColors.accentRed),
          const SizedBox(width: 12),
          Text(message, style: AppTypography.bodyMedium(AppColors.accentRed)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: AppTypography.bodyMedium(
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ),
    );
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

  Color _parseHexColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return AppColors.accentBlue;
  }

  IconData _getIconForCategory(String? iconName) {
    const iconMap = {
      'utensils': LucideIcons.utensils,
      'car': LucideIcons.car,
      'shopping-bag': LucideIcons.shoppingBag,
      'file-text': LucideIcons.fileText,
      'gamepad-2': LucideIcons.gamepad2,
      'heart-pulse': LucideIcons.heartPulse,
      'graduation-cap': LucideIcons.graduationCap,
      'plane': LucideIcons.plane,
      'briefcase': LucideIcons.briefcase,
      'laptop': LucideIcons.laptop,
      'trending-up': LucideIcons.trendingUp,
      'gift': LucideIcons.gift,
      'home': LucideIcons.home,
      'coffee': LucideIcons.coffee,
      'music': LucideIcons.music,
      'film': LucideIcons.film,
      'dumbbell': LucideIcons.dumbbell,
      'book': LucideIcons.book,
      'wallet': LucideIcons.wallet,
      'credit-card': LucideIcons.creditCard,
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

  Widget _buildIncomeBreakdownSection(WidgetRef ref, bool isDark) {
    final monthSummary = ref.watch(monthSummaryProvider);
    final expensesByCategory = ref.watch(monthExpensesByCategoryProvider);
    final categoryMap = ref.watch(monthCategoryMapProvider);

    return monthSummary.when(
      data: (summary) => expensesByCategory.when(
        data: (expenses) => categoryMap.when(
          data: (categories) {
            if (summary.totalIncome <= 0) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'No income data for this month',
                    style: AppTypography.bodyMedium(
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              );
            }

            final savingsPercentage = summary.totalIncome > 0
                ? (summary.netSavings / summary.totalIncome * 100).clamp(0.0, 100.0)
                : 0.0;
            final expensesPercentage = summary.totalIncome > 0
                ? (summary.totalExpenses / summary.totalIncome * 100).clamp(0.0, 100.0)
                : 0.0;

            // Sort expenses by amount (descending)
            final sortedExpenses = expenses.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return Container(
              padding: const EdgeInsets.all(24),
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
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.pieChart,
                          size: 20,
                          color: AppColors.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Income Breakdown',
                        style: AppTypography.titleLarge(
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Total income header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurfaceHighlight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total Income',
                            style: AppTypography.titleMedium(
                              isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        Text(
                          _formatCurrency(summary.totalIncome, ref),
                          style: AppTypography.moneyLarge(
                            AppColors.income,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Savings row
                  _buildIncomeBreakdownRow(
                    isDark: isDark,
                    label: 'Savings',
                    amount: summary.netSavings,
                    percentage: savingsPercentage,
                    color: summary.netSavings >= 0
                        ? AppColors.savings
                        : AppColors.expense,
                    ref: ref,
                  ),
                  const SizedBox(height: 12),
                  // Total expenses row
                  _buildIncomeBreakdownRow(
                    isDark: isDark,
                    label: 'Total Expenses',
                    amount: summary.totalExpenses,
                    percentage: expensesPercentage,
                    color: AppColors.expense,
                    ref: ref,
                  ),
                  if (sortedExpenses.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Expenses by Category',
                      style: AppTypography.titleSmall(
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Expense categories
                    ...sortedExpenses.map((entry) {
                      final category = categories[entry.key];
                      final categoryPercentage = summary.totalIncome > 0
                          ? (entry.value / summary.totalIncome * 100).clamp(0.0, 100.0)
                          : 0.0;
                      final color = _parseHexColor(category?.colorHex ?? '#8E8E93');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildIncomeBreakdownRow(
                          isDark: isDark,
                          label: category?.name ?? 'Unknown',
                          amount: entry.value,
                          percentage: categoryPercentage,
                          color: color,
                          ref: ref,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ).animate(delay: 250.ms).fadeIn(duration: 400.ms);
          },
          loading: () => Container(
            height: 200,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                width: 1,
              ),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => _buildErrorCard(isDark, 'Error loading categories'),
        ),
        loading: () => Container(
          height: 200,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              width: 1,
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => _buildErrorCard(isDark, 'Error loading expenses'),
      ),
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 1,
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _buildErrorCard(isDark, 'Error loading summary'),
    );
  }

  Widget _buildIncomeBreakdownRow({
    required bool isDark,
    required String label,
    required double amount,
    required double percentage,
    required Color color,
    required WidgetRef ref,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceHighlight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium(
                    isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: AppTypography.titleMedium(
                  color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: isDark
                  ? AppColors.darkDivider
                  : AppColors.lightDivider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(amount, ref),
                style: AppTypography.moneySmall(
                  isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletBalancesSection(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    DateTime selectedMonth,
  ) {
    final wallets = ref.watch(walletsProvider);
    final monthBalances = ref.watch(monthWalletBalancesProvider(selectedMonth));
    final monthSummary = ref.watch(monthSummaryProvider);
    
    // Get previous month for comparison
    final previousMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    final previousMonthBalances = ref.watch(monthWalletBalancesProvider(previousMonth));

    return wallets.when(
      data: (walletList) => monthBalances.when(
        data: (balances) => previousMonthBalances.when(
          data: (prevBalances) => monthSummary.when(
            data: (summary) {
              final totalBalance = balances.values.fold(0.0, (sum, val) => sum + val);
              final totalPrevBalance = prevBalances.values.fold(0.0, (sum, val) => sum + val);
              final walletBalanceChange = totalBalance - totalPrevBalance;
              final netSavings = summary.netSavings;
              
              // Check if there's a discrepancy (allow small rounding differences)
              final discrepancy = (walletBalanceChange - netSavings).abs();
              final hasDiscrepancy = discrepancy > 0.01; // Allow 1 cent difference for rounding
              
              return Column(
                children: [
                  // Warning banner if there's a discrepancy
                  if (hasDiscrepancy) ...[
                    _buildDiscrepancyWarning(
                      isDark: isDark,
                      netSavings: netSavings,
                      walletBalanceChange: walletBalanceChange,
                      discrepancy: discrepancy,
                      ref: ref,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
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
                        'Wallet Balances',
                        style: AppTypography.titleLarge(
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showManageBalances(context, ref, selectedMonth),
                      icon: const Icon(LucideIcons.edit, size: 16),
                      label: Text(
                        'Update',
                        style: AppTypography.labelMedium(AppColors.accentBlue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (walletList.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No wallets found',
                        style: AppTypography.bodyMedium(
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      ...walletList.map((wallet) {
                        final balance = balances[wallet.id] ?? wallet.initialBalance;
                        final color = AppColors.getWalletGradient(wallet.gradientIndex)[0];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  LucideIcons.wallet,
                                  size: 20,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      wallet.name,
                                      style: AppTypography.titleMedium(
                                        isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMMM yyyy').format(selectedMonth),
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
                                CurrencyFormatter.format(
                                  balance,
                                  currencyCode: wallet.currency,
                                ),
                                style: AppTypography.moneySmall(
                                  isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Total',
                              style: AppTypography.titleMedium(
                                isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(
                              totalBalance,
                              currencyCode: walletList.isNotEmpty
                                  ? walletList.first.currency
                                  : 'USD',
                            ),
                            style: AppTypography.moneyLarge(
                              AppColors.accentBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
                  ),
                ],
              );
            },
            loading: () => Container(
              height: 200,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  width: 1,
                ),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => _buildErrorCard(isDark, 'Error loading summary'),
          ),
          loading: () => Container(
            height: 200,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                width: 1,
              ),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => _buildErrorCard(isDark, 'Error loading previous balances'),
        ),
        loading: () => Container(
          height: 200,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              width: 1,
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => _buildErrorCard(isDark, 'Error loading balances'),
      ),
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 1,
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _buildErrorCard(isDark, 'Error loading wallets'),
    );
  }

  Widget _buildDiscrepancyWarning({
    required bool isDark,
    required double netSavings,
    required double walletBalanceChange,
    required double discrepancy,
    required WidgetRef ref,
  }) {
    final isMissing = walletBalanceChange < netSavings;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentRed.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.alertTriangle,
              size: 20,
              color: AppColors.accentRed,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Missing Money Detected',
                  style: AppTypography.titleMedium(
                    AppColors.accentRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMissing
                      ? 'Your wallet balances increased by ${_formatCurrency(walletBalanceChange, ref)}, but your net savings are ${_formatCurrency(netSavings, ref)}. There is ${_formatCurrency(discrepancy, ref)} missing.'
                      : 'Your wallet balances increased by ${_formatCurrency(walletBalanceChange, ref)}, but your net savings are ${_formatCurrency(netSavings, ref)}. There is ${_formatCurrency(discrepancy, ref)} unaccounted for.',
                  style: AppTypography.bodySmall(
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showManageBalances(BuildContext context, WidgetRef ref, DateTime month) async {
    final result = await ManageWalletBalancesModal.show(context);
    if (result == true && context.mounted) {
      // Invalidate the provider to refresh the balances
      ref.invalidate(monthWalletBalancesProvider(month));
    }
  }
}
