import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/drift/database.dart';
import '../../../../data/providers/database_provider.dart';

/// Insights tab selection
enum InsightsTab { spending, income, savings, subscriptions, debts }

/// Provider for selected insights tab
final selectedInsightsTabProvider =
    NotifierProvider<InsightsTabNotifier, InsightsTab>(
  InsightsTabNotifier.new,
);

class InsightsTabNotifier extends Notifier<InsightsTab> {
  @override
  InsightsTab build() => InsightsTab.spending;

  void setTab(InsightsTab tab) => state = tab;
}

/// Provider for selected year in insights
final selectedInsightsYearProvider =
    NotifierProvider<SelectedInsightsYearNotifier, int>(
  SelectedInsightsYearNotifier.new,
);

class SelectedInsightsYearNotifier extends Notifier<int> {
  @override
  int build() => DateTime.now().year;

  void setYear(int year) => state = year;
}

/// Provider for monthly spending data (12 months for selected year)
final monthlySpendingProvider =
    FutureProvider<List<MonthlyData>>((ref) async {
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final selectedYear = ref.watch(selectedInsightsYearProvider);
  final results = <MonthlyData>[];

  for (int i = 1; i <= 12; i++) {
    final month = DateTime(selectedYear, i, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final expenses = await transactionsDao.getTotalExpenses(month, end);
    results.add(MonthlyData(
      month: month,
      amount: expenses,
    ));
  }

  return results;
});

/// Provider for monthly income data (12 months for selected year)
final monthlyIncomeDataProvider =
    FutureProvider<List<MonthlyData>>((ref) async {
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final selectedYear = ref.watch(selectedInsightsYearProvider);
  final results = <MonthlyData>[];

  for (int i = 1; i <= 12; i++) {
    final month = DateTime(selectedYear, i, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final income = await transactionsDao.getTotalIncome(month, end);
    results.add(MonthlyData(
      month: month,
      amount: income,
    ));
  }

  return results;
});

/// Provider for monthly savings (income - expenses) for selected year
final monthlySavingsDataProvider =
    FutureProvider<List<MonthlyData>>((ref) async {
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final selectedYear = ref.watch(selectedInsightsYearProvider);
  final results = <MonthlyData>[];

  for (int i = 1; i <= 12; i++) {
    final month = DateTime(selectedYear, i, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final income = await transactionsDao.getTotalIncome(month, end);
    final expenses = await transactionsDao.getTotalExpenses(month, end);
    results.add(MonthlyData(
      month: month,
      amount: income - expenses,
    ));
  }

  return results;
});

/// Provider for spending by category this month
final currentMonthSpendingByCategoryProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  return transactionsDao.getSpendingByCategory(start, end);
});

/// Provider for income by category this month
final currentMonthIncomeByCategoryProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  return transactionsDao.getIncomeByCategory(start, end);
});

/// Provider for all active subscriptions
final activeSubscriptionsProvider =
    StreamProvider<List<SubscriptionEntity>>((ref) {
  return ref.watch(subscriptionsDaoProvider).watchActiveSubscriptions();
});

/// Provider for total monthly subscription cost
final totalMonthlySubscriptionCostProvider =
    FutureProvider<double>((ref) async {
  return ref.watch(subscriptionsDaoProvider).getTotalMonthlySubscriptionCost();
});

/// Provider for all active debts
final activeDebtsProvider = StreamProvider<List<DebtEntity>>((ref) {
  return ref.watch(debtsDaoProvider).watchActiveDebts();
});

/// Provider for total owed
final totalOwedProvider = FutureProvider<double>((ref) async {
  return ref.watch(debtsDaoProvider).getTotalOwed();
});

/// Provider for total lent
final totalLentProvider = FutureProvider<double>((ref) async {
  return ref.watch(debtsDaoProvider).getTotalLent();
});

/// Provider for active savings goals
final activeSavingsGoalsProvider =
    StreamProvider<List<SavingsGoalEntity>>((ref) {
  return ref.watch(savingsGoalsDaoProvider).watchActiveGoals();
});

/// Provider for total savings goal progress
final savingsGoalProgressProvider = FutureProvider<double>((ref) async {
  return ref.watch(savingsGoalsDaoProvider).getOverallProgress();
});

/// Data class for monthly chart data
class MonthlyData {
  final DateTime month;
  final double amount;

  MonthlyData({required this.month, required this.amount});
}

/// Provider for top spending categories
final topSpendingCategoriesProvider =
    FutureProvider<List<CategorySpending>>((ref) async {
  final spending = await ref.watch(currentMonthSpendingByCategoryProvider.future);
  final categoriesDao = ref.watch(categoriesDaoProvider);

  final results = <CategorySpending>[];
  for (final entry in spending.entries) {
    final category = await categoriesDao.getCategoryById(entry.key);
    if (category != null) {
      results.add(CategorySpending(
        category: category,
        amount: entry.value,
      ));
    }
  }

  results.sort((a, b) => b.amount.compareTo(a.amount));
  return results.take(5).toList();
});

/// Data class for category spending
class CategorySpending {
  final CategoryEntity category;
  final double amount;

  CategorySpending({required this.category, required this.amount});
}

