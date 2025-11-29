import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/drift/database.dart';
import '../../../../data/providers/database_provider.dart';

/// Provider for all wallets
final walletsProvider = StreamProvider<List<WalletEntity>>((ref) {
  return ref.watch(walletsDaoProvider).watchAllWallets();
});

/// Provider for all expense categories
final expenseCategoriesProvider = StreamProvider<List<CategoryEntity>>((ref) {
  return ref.watch(categoriesDaoProvider).watchExpenseCategories();
});

/// Provider for all income categories
final incomeCategoriesProvider = StreamProvider<List<CategoryEntity>>((ref) {
  return ref.watch(categoriesDaoProvider).watchIncomeCategories();
});

/// Provider for current month's transactions
final currentMonthTransactionsProvider =
    StreamProvider<List<TransactionEntity>>((ref) {
  final now = DateTime.now();
  return ref.watch(transactionsDaoProvider).watchTransactionsForMonth(
        now.year,
        now.month,
      );
});

/// Provider for wallet balances (computed from transactions)
final walletBalancesProvider = FutureProvider<Map<String, double>>((ref) async {
  final wallets = await ref.watch(walletsProvider.future);
  final transactionsDao = ref.watch(transactionsDaoProvider);

  final balances = <String, double>{};
  for (final wallet in wallets) {
    balances[wallet.id] = await transactionsDao.calculateWalletBalance(wallet.id);
  }
  return balances;
});

/// Provider for monthly income total
final monthlyIncomeProvider = FutureProvider<double>((ref) async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return ref.watch(transactionsDaoProvider).getTotalIncome(start, end);
});

/// Provider for monthly expenses total
final monthlyExpensesProvider = FutureProvider<double>((ref) async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return ref.watch(transactionsDaoProvider).getTotalExpenses(start, end);
});

/// Provider for all-time net savings
final allTimeSavingsProvider = FutureProvider<double>((ref) async {
  return ref.watch(transactionsDaoProvider).getAllTimeNetSavings();
});

/// Provider for spending by category this month
final monthlySpendingByCategoryProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return ref.watch(transactionsDaoProvider).getSpendingByCategory(start, end);
});

/// Provider for category details map
final categoryMapProvider = FutureProvider<Map<String, CategoryEntity>>((ref) async {
  final categories = await ref.watch(categoriesDaoProvider).getAllCategories();
  return {for (final c in categories) c.id: c};
});

