import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../data/drift/database.dart';
import '../../../data/services/currency_formatter.dart';
import '../../../data/providers/currency_provider.dart';
import '../../widgets/apple_dropdown.dart';
import '../../widgets/category_pie_chart.dart';
import '../../widgets/line_chart_widget.dart';
import '../../widgets/stat_card.dart';
import '../dashboard/providers/dashboard_providers.dart';
import 'providers/insights_providers.dart';

/// Insights screen - Analytics and visualizations
/// Features: Tabbed view (Spending, Income, Savings)
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final selectedTab = ref.watch(selectedInsightsTabProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      floatingActionButton: _buildFloatingActionButton(context, ref, selectedTab),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: CustomScrollView(
        slivers: [
          // Header with year selector
          SliverToBoxAdapter(
            child: _buildHeaderWithYearSelector(ref, isDark),
          ),

          // Tab bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _buildTabBar(context, ref, isDark, selectedTab),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Tab content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            sliver: SliverToBoxAdapter(
              child: _buildTabContent(ref, isDark, selectedTab),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeaderWithYearSelector(WidgetRef ref, bool isDark) {
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
                  'Insights',
                  style: AppTypography.displaySmall(
                    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
                const SizedBox(height: 8),
                Text(
                  'Deep dive into your financial patterns',
                  style: AppTypography.bodyMedium(
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),
          _buildYearSelector(ref, isDark),
        ],
      ),
    );
  }

  Widget _buildYearSelector(WidgetRef ref, bool isDark) {
    final selectedYear = ref.watch(selectedInsightsYearProvider);
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (i) => currentYear - i);

    return AppleDropdown<int>(
      value: selectedYear,
      isDark: isDark,
      leadingIcon: LucideIcons.calendar,
      items: years
          .map((y) => AppleDropdownItem(
                value: y,
                label: y.toString(),
              ))
          .toList(),
      onChanged: (value) {
        ref.read(selectedInsightsYearProvider.notifier).setYear(value);
      },
    ).animate(delay: 150.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildTabBar(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    InsightsTab selectedTab,
  ) {
    final tabs = [
      (InsightsTab.spending, 'Spending', LucideIcons.trendingDown),
      (InsightsTab.income, 'Income', LucideIcons.trendingUp),
      (InsightsTab.savings, 'Savings', LucideIcons.piggyBank),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 1,
        ),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = selectedTab == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(selectedInsightsTabProvider.notifier).setTab(tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.$3,
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tab.$2,
                      style: AppTypography.labelMedium(
                        isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildTabContent(WidgetRef ref, bool isDark, InsightsTab tab) {
    switch (tab) {
      case InsightsTab.spending:
        return _buildSpendingTab(ref, isDark);
      case InsightsTab.income:
        return _buildIncomeTab(ref, isDark);
      case InsightsTab.savings:
        return _buildSavingsTab(ref, isDark);
      case InsightsTab.subscriptions:
      case InsightsTab.debts:
        // These tabs have been moved to separate screens
        return const SizedBox.shrink();
    }
  }

  Widget _buildSpendingTab(WidgetRef ref, bool isDark) {
    final monthlySpending = ref.watch(monthlySpendingProvider);
    final spendingByCategory = ref.watch(currentMonthSpendingByCategoryProvider);
    final categoryMap = ref.watch(categoryMapProvider);
    final topCategories = ref.watch(topSpendingCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Monthly trend chart
        monthlySpending.when(
          data: (data) => PremiumLineChart(
            title: 'Monthly Spending Trend',
            data: data
                .map((d) => ChartDataPoint(date: d.month, value: d.amount))
                .toList(),
            lineColor: AppColors.expense,
            isDark: isDark,
          ),
          loading: () => _buildLoadingCard(isDark),
          error: (_, __) => _buildErrorCard(isDark, 'Unable to load data'),
        ),

        const SizedBox(height: 24),

        // Category breakdown
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: spendingByCategory.when(
                data: (spending) => categoryMap.when(
                  data: (categories) {
                    final chartData = spending.entries.map((entry) {
                      final category = categories[entry.key];
                      return CategoryChartData(
                        id: entry.key,
                        name: category?.name ?? 'Unknown',
                        amount: entry.value,
                        color: _parseHexColor(category?.colorHex ?? '#8E8E93'),
                      );
                    }).toList();

                    final total =
                        spending.values.fold(0.0, (sum, val) => sum + val);

                    return CategoryPieChart(
                      data: chartData,
                      totalAmount: total,
                      isDark: isDark,
                      centerLabel: 'This Month',
                    );
                  },
                  loading: () => _buildLoadingCard(isDark, height: 280),
                  error: (_, __) => _buildErrorCard(isDark, 'Error'),
                ),
                loading: () => _buildLoadingCard(isDark, height: 280),
                error: (_, __) => _buildErrorCard(isDark, 'Error'),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: _buildTopSpendingCategories(ref, isDark, topCategories),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopSpendingCategories(
    WidgetRef ref,
    bool isDark,
    AsyncValue<List<CategorySpending>> topCategories,
  ) {
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
          Text(
            'Top Categories',
            style: AppTypography.titleLarge(
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          topCategories.when(
            data: (categories) {
              if (categories.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No spending data',
                      style: AppTypography.bodyMedium(
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                );
              }

              final maxAmount = categories.first.amount;

              return Column(
                children: categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final progress = item.amount / maxAmount;

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < categories.length - 1 ? 16 : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _parseHexColor(item.category.colorHex),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.category.name,
                                style: AppTypography.bodySmall(
                                  isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                            Text(
                              _formatCurrency(item.amount, ref),
                              style: AppTypography.moneySmall(
                                isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: isDark
                                ? AppColors.darkSurfaceElevated
                                : AppColors.lightSurfaceHighlight,
                            valueColor: AlwaysStoppedAnimation(
                              _parseHexColor(item.category.colorHex),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => Center(
              child: Text(
                'Error loading data',
                style: AppTypography.bodyMedium(AppColors.accentRed),
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildIncomeTab(WidgetRef ref, bool isDark) {
    final monthlyIncome = ref.watch(monthlyIncomeDataProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        monthlyIncome.when(
          data: (data) => PremiumLineChart(
            title: 'Monthly Income Trend',
            data: data
                .map((d) => ChartDataPoint(date: d.month, value: d.amount))
                .toList(),
            lineColor: AppColors.income,
            isDark: isDark,
          ),
          loading: () => _buildLoadingCard(isDark),
          error: (_, __) => _buildErrorCard(isDark, 'Unable to load data'),
        ),
      ],
    );
  }

  Widget _buildSavingsTab(WidgetRef ref, bool isDark) {
    final monthlySavings = ref.watch(monthlySavingsDataProvider);
    final savingsGoals = ref.watch(activeSavingsGoalsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        monthlySavings.when(
          data: (data) => PremiumLineChart(
            title: 'Monthly Savings Trend',
            data: data
                .map((d) => ChartDataPoint(date: d.month, value: d.amount))
                .toList(),
            lineColor: AppColors.savings,
            isDark: isDark,
          ),
          loading: () => _buildLoadingCard(isDark),
          error: (_, __) => _buildErrorCard(isDark, 'Unable to load data'),
        ),

        const SizedBox(height: 24),

        // Savings goals
        savingsGoals.when(
          data: (goals) {
            if (goals.isEmpty) {
              return _buildEmptyState(
                isDark,
                'No savings goals',
                'Create a savings goal to track your progress',
                LucideIcons.target,
              );
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Savings Goals',
                    style: AppTypography.titleLarge(
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...goals.map((goal) => _buildSavingsGoalItem(goal, ref, isDark)),
                ],
              ),
            );
          },
          loading: () => _buildLoadingCard(isDark),
          error: (_, __) => _buildErrorCard(isDark, 'Error loading goals'),
        ),
      ],
    );
  }

  Widget _buildSavingsGoalItem(dynamic goal, WidgetRef ref, bool isDark) {
    final progress = goal.currentAmount / goal.targetAmount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: AppTypography.titleMedium(
                    isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: AppTypography.labelMedium(AppColors.savings),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceHighlight,
              valueColor: const AlwaysStoppedAnimation(AppColors.savings),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatCurrency(goal.currentAmount, ref),
                style: AppTypography.bodySmall(
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const Spacer(),
              Text(
                _formatCurrency(goal.targetAmount, ref),
                style: AppTypography.bodySmall(
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildEmptyState(
    bool isDark,
    String title,
    String subtitle,
    IconData icon,
  ) {
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
              icon,
              size: 48,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.titleMedium(
                isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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

  Widget? _buildFloatingActionButton(
    BuildContext context,
    WidgetRef ref,
    InsightsTab selectedTab,
  ) {
    // No FAB for insights tabs
    return null;
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
}
