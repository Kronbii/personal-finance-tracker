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
import '../../../data/drift/tables/subscriptions_table.dart';
import '../../../data/services/currency_formatter.dart';
import '../../../data/providers/currency_provider.dart';
import '../../widgets/category_pie_chart.dart';
import '../../widgets/line_chart_widget.dart';
import '../../widgets/stat_card.dart';
import '../dashboard/providers/dashboard_providers.dart';
import 'providers/insights_providers.dart';
import 'widgets/add_subscription_modal.dart';
import 'widgets/add_debt_modal.dart';

/// Insights screen - Analytics and visualizations
/// Features: Tabbed view (Spending, Income, Savings, Subscriptions, Debts)
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
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(isDark),
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

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
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
    );
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
      (InsightsTab.subscriptions, 'Subscriptions', LucideIcons.repeat),
      (InsightsTab.debts, 'Debts', LucideIcons.banknote),
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
        return _buildSubscriptionsTab(ref, isDark);
      case InsightsTab.debts:
        return _buildDebtsTab(ref, isDark);
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

  Widget _buildSubscriptionsTab(WidgetRef ref, bool isDark) {
    final subscriptions = ref.watch(activeSubscriptionsProvider);
    final totalMonthlyCost = ref.watch(totalMonthlySubscriptionCostProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total cost card
        totalMonthlyCost.when(
          data: (cost) => StatCard(
            title: 'Monthly Subscriptions',
            value: _formatCurrency(cost, ref),
            subtitle: 'Total recurring costs',
            icon: LucideIcons.repeat,
            iconColor: AppColors.accentPurple,
            isDark: isDark,
          ),
          loading: () => _buildLoadingCard(isDark, height: 120),
          error: (_, __) => _buildErrorCard(isDark, 'Error'),
        ),

        const SizedBox(height: 24),

        // Subscription list
        subscriptions.when(
          data: (subs) {
            if (subs.isEmpty) {
              return _buildEmptyState(
                isDark,
                'No subscriptions',
                'Add subscriptions to track recurring payments',
                LucideIcons.creditCard,
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
                    'Active Subscriptions',
                    style: AppTypography.titleLarge(
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...subs.map((sub) => _buildSubscriptionItem(sub, ref, isDark)),
                ],
              ),
            );
          },
          loading: () => _buildLoadingCard(isDark),
          error: (_, __) => _buildErrorCard(isDark, 'Error'),
        ),
      ],
    );
  }

  Widget _buildSubscriptionItem(SubscriptionEntity sub, WidgetRef ref, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _parseHexColor(sub.colorHex).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.repeat,
              size: 20,
              color: _parseHexColor(sub.colorHex),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: AppTypography.titleMedium(
                    isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  'Next: ${DateFormat('MMM d').format(sub.nextBillingDate)}',
                  style: AppTypography.caption(
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(sub.amount, ref),
                style: AppTypography.moneySmall(
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                _getFrequencyLabel(sub.frequency),
                style: AppTypography.caption(
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

  Widget _buildDebtsTab(WidgetRef ref, bool isDark) {
    final debts = ref.watch(activeDebtsProvider);
    final totalOwed = ref.watch(totalOwedProvider);
    final totalLent = ref.watch(totalLentProvider);

    return Column(
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
              return _buildEmptyState(
                isDark,
                'No active debts',
                'Track money you owe or are owed',
                LucideIcons.banknote,
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
                    'Active Debts',
                    style: AppTypography.titleLarge(
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...debtList.map((debt) => _buildDebtItem(debt, ref, isDark)),
                ],
              ),
            );
          },
          loading: () => _buildLoadingCard(isDark),
          error: (_, __) => _buildErrorCard(isDark, 'Error loading debts'),
        ),
      ],
    );
  }

  Widget _buildDebtItem(DebtEntity debt, WidgetRef ref, bool isDark) {
    final isOwed = debt.type == DebtType.owed;
    final progress = 1 - (debt.remainingAmount / debt.originalAmount);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
    if (selectedTab == InsightsTab.subscriptions) {
      return FloatingActionButton.extended(
        onPressed: () => _showAddSubscription(context, ref),
        backgroundColor: AppColors.accentPurple,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(
          'Add Subscription',
          style: AppTypography.labelMedium(Colors.white),
        ),
      );
    } else if (selectedTab == InsightsTab.debts) {
      return FloatingActionButton.extended(
        onPressed: () => _showAddDebt(context, ref),
        backgroundColor: AppColors.accentBlue,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(
          'Add Debt',
          style: AppTypography.labelMedium(Colors.white),
        ),
      );
    }
    return null;
  }

  Future<void> _showAddSubscription(BuildContext context, WidgetRef ref) async {
    final result = await AddSubscriptionModal.show(context);
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.check, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Text(
                'Subscription added successfully',
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

  String _getFrequencyLabel(BillingFrequency frequency) {
    switch (frequency) {
      case BillingFrequency.daily:
        return '/day';
      case BillingFrequency.weekly:
        return '/week';
      case BillingFrequency.biweekly:
        return '/2 weeks';
      case BillingFrequency.monthly:
        return '/month';
      case BillingFrequency.quarterly:
        return '/quarter';
      case BillingFrequency.yearly:
        return '/year';
    }
  }

  Color _parseHexColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return AppColors.accentBlue;
  }
}
