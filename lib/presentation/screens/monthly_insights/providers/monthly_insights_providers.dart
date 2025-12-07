import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/drift/database.dart';
import '../../../../data/drift/daos/transactions_dao.dart';
import '../../../../data/drift/tables/transactions_table.dart';
import '../../../../data/providers/database_provider.dart';
import '../../dashboard/providers/dashboard_providers.dart';

/// Selected month for monthly insights
final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month, 1);
  }
}

/// Month summary data class
class MonthSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netSavings;
  final int transactionCount;

  MonthSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netSavings,
    required this.transactionCount,
  });
}

/// Provider for month summary
final monthSummaryProvider = FutureProvider<MonthSummary>((ref) async {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final transactionsDao = ref.watch(transactionsDaoProvider);

  final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);

  final income = await transactionsDao.getTotalIncome(start, end);
  final expenses = await transactionsDao.getTotalExpenses(start, end);
  final transactions = await transactionsDao.getTransactionsInRange(start, end);

  return MonthSummary(
    totalIncome: income,
    totalExpenses: expenses,
    netSavings: income - expenses,
    transactionCount: transactions.length,
  );
});

/// Provider for expenses by category for selected month
final monthExpensesByCategoryProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final transactionsDao = ref.watch(transactionsDaoProvider);

  final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);

  return transactionsDao.getSpendingByCategory(start, end);
});

/// Provider for income by category for selected month
final monthIncomeByCategoryProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final transactionsDao = ref.watch(transactionsDaoProvider);

  final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);

  return transactionsDao.getIncomeByCategory(start, end);
});

/// Provider for category map
/// Uses StreamProvider to automatically update when categories change
final monthCategoryMapProvider =
    StreamProvider<Map<String, CategoryEntity>>((ref) {
  return ref.watch(categoriesDaoProvider).watchAllCategories().map((categories) {
    return {for (var c in categories) c.id: c};
  });
});

/// Daily average data class
class DailyAverage {
  final double avgExpense;
  final double avgIncome;

  DailyAverage({required this.avgExpense, required this.avgIncome});
}

/// Provider for daily averages
final dailyAverageProvider = FutureProvider<DailyAverage>((ref) async {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final transactionsDao = ref.watch(transactionsDaoProvider);

  final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);

  final income = await transactionsDao.getTotalIncome(start, end);
  final expenses = await transactionsDao.getTotalExpenses(start, end);

  // Calculate days in month (or days passed if current month)
  final now = DateTime.now();
  int daysInMonth;
  if (selectedMonth.year == now.year && selectedMonth.month == now.month) {
    daysInMonth = now.day;
  } else {
    daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
  }

  return DailyAverage(
    avgExpense: daysInMonth > 0 ? expenses / daysInMonth : 0,
    avgIncome: daysInMonth > 0 ? income / daysInMonth : 0,
  );
});

/// Month comparison data class
class MonthComparison {
  final double expenseChange;
  final double incomeChange;

  MonthComparison({required this.expenseChange, required this.incomeChange});
}

/// Provider for comparison with previous month
final monthComparisonProvider = FutureProvider<MonthComparison>((ref) async {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final transactionsDao = ref.watch(transactionsDaoProvider);

  // Current month
  final currentStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final currentEnd =
      DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);

  // Previous month
  final prevMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
  final prevStart = DateTime(prevMonth.year, prevMonth.month, 1);
  final prevEnd =
      DateTime(prevMonth.year, prevMonth.month + 1, 0, 23, 59, 59);

  final currentExpenses =
      await transactionsDao.getTotalExpenses(currentStart, currentEnd);
  final prevExpenses =
      await transactionsDao.getTotalExpenses(prevStart, prevEnd);

  final currentIncome =
      await transactionsDao.getTotalIncome(currentStart, currentEnd);
  final prevIncome = await transactionsDao.getTotalIncome(prevStart, prevEnd);

  double expenseChange = 0;
  if (prevExpenses > 0) {
    expenseChange = ((currentExpenses - prevExpenses) / prevExpenses) * 100;
  }

  double incomeChange = 0;
  if (prevIncome > 0) {
    incomeChange = ((currentIncome - prevIncome) / prevIncome) * 100;
  }

  return MonthComparison(
    expenseChange: expenseChange,
    incomeChange: incomeChange,
  );
});

/// Provider for top expenses in selected month
final topMonthExpensesProvider =
    FutureProvider<List<TransactionWithDetails>>((ref) async {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final categoriesDao = ref.watch(categoriesDaoProvider);
  final walletsDao = ref.watch(walletsDaoProvider);

  final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);

  final transactions = await transactionsDao.getTransactionsInRange(start, end);
  final expenses = transactions
      .where((t) => t.type == TransactionType.expense)
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  final topExpenses = expenses.take(5).toList();

  final results = <TransactionWithDetails>[];
  for (final tx in topExpenses) {
    final category = tx.categoryId != null
        ? await categoriesDao.getCategoryById(tx.categoryId!)
        : null;
    // Wallets are optional - only include if transaction has a wallet
    if (tx.walletId != null) {
      final wallet = await walletsDao.getWalletById(tx.walletId!);
      if (wallet != null) {
        results.add(TransactionWithDetails(
          transaction: tx,
          category: category,
          wallet: wallet,
        ));
      }
    } else {
      // Include transaction even without wallet
      results.add(TransactionWithDetails(
        transaction: tx,
        category: category,
        wallet: null,
      ));
    }
  }

  return results;
});

/// Provider for wallet balances for a specific month
final monthWalletBalancesProvider = FutureProvider.family<Map<String, double>, DateTime>((ref, month) async {
  final wallets = await ref.watch(walletsProvider.future);
  final walletBalancesDao = ref.watch(walletBalancesDaoProvider);
  
  final balances = <String, double>{};
  for (final wallet in wallets) {
    final balance = await walletBalancesDao.getBalanceForMonth(
      wallet.id,
      month.year,
      month.month,
    );
    if (balance != null) {
      balances[wallet.id] = balance.balance;
    } else {
      // Fallback to initial balance if no monthly entry exists
      balances[wallet.id] = wallet.initialBalance;
    }
  }
  return balances;
});

/// Provider for top incomes in selected month
final topMonthIncomesProvider =
    FutureProvider<List<TransactionWithDetails>>((ref) async {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final categoriesDao = ref.watch(categoriesDaoProvider);
  final walletsDao = ref.watch(walletsDaoProvider);

  final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);

  final transactions = await transactionsDao.getTransactionsInRange(start, end);
  final incomes = transactions
      .where((t) => t.type == TransactionType.income)
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  final topIncomes = incomes.take(5).toList();

  final results = <TransactionWithDetails>[];
  for (final tx in topIncomes) {
    final category = tx.categoryId != null
        ? await categoriesDao.getCategoryById(tx.categoryId!)
        : null;
    // Wallets are optional - only include if transaction has a wallet
    if (tx.walletId != null) {
      final wallet = await walletsDao.getWalletById(tx.walletId!);
      if (wallet != null) {
        results.add(TransactionWithDetails(
          transaction: tx,
          category: category,
          wallet: wallet,
        ));
      }
    } else {
      // Include transaction even without wallet
      results.add(TransactionWithDetails(
        transaction: tx,
        category: category,
        wallet: null,
      ));
    }
  }

  return results;
});
