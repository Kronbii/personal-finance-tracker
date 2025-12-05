import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/drift/database.dart';
import '../../../../data/providers/database_provider.dart';
import '../../transactions/providers/transaction_providers.dart';

/// Provider for all wallets
final walletsProvider = StreamProvider<List<WalletEntity>>((ref) {
  return ref.watch(walletsDaoProvider).watchAllWallets();
});

/// Provider for all expense categories (includes disabled - for management)
final expenseCategoriesProvider = StreamProvider<List<CategoryEntity>>((ref) {
  return ref.watch(categoriesDaoProvider).watchExpenseCategories();
});

/// Provider for all income categories (includes disabled - for management)
final incomeCategoriesProvider = StreamProvider<List<CategoryEntity>>((ref) {
  return ref.watch(categoriesDaoProvider).watchIncomeCategories();
});

/// Provider for enabled expense categories only (for dropdowns/selectors)
final enabledExpenseCategoriesProvider = StreamProvider<List<CategoryEntity>>((ref) {
  return ref.watch(categoriesDaoProvider).watchEnabledExpenseCategories();
});

/// Provider for enabled income categories only (for dropdowns/selectors)
final enabledIncomeCategoriesProvider = StreamProvider<List<CategoryEntity>>((ref) {
  return ref.watch(categoriesDaoProvider).watchEnabledIncomeCategories();
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

/// Provider for wallet balances (from latest monthly balance entries)
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
/// Automatically updates when transactions change
final monthlyIncomeProvider = FutureProvider<double>((ref) async {
  // Watch transactions stream to trigger recalculation when transactions change
  ref.watch(currentMonthTransactionsProvider);
  
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return ref.watch(transactionsDaoProvider).getTotalIncome(start, end);
});

/// Provider for monthly expenses total
/// Automatically updates when transactions change
final monthlyExpensesProvider = FutureProvider<double>((ref) async {
  // Watch transactions stream to trigger recalculation when transactions change
  ref.watch(currentMonthTransactionsProvider);
  
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return ref.watch(transactionsDaoProvider).getTotalExpenses(start, end);
});

/// Provider for all-time net savings
/// Automatically updates when transactions change
final allTimeSavingsProvider = FutureProvider<double>((ref) async {
  // Watch all transactions stream to trigger recalculation when transactions change
  // (all-time savings need all transactions, not just current month)
  ref.watch(allTransactionsProvider);
  
  return ref.watch(transactionsDaoProvider).getAllTimeNetSavings();
});

/// Provider for spending by category this month
/// Automatically updates when transactions change
final monthlySpendingByCategoryProvider =
    FutureProvider<Map<String, double>>((ref) async {
  // Watch transactions stream to trigger recalculation when transactions change
  ref.watch(currentMonthTransactionsProvider);
  
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

