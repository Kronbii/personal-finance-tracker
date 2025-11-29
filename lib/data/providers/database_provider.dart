import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../drift/database.dart';

/// Provider for the main database instance
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => database.close());
  return database;
});

/// Provider for WalletsDao
final walletsDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).walletsDao;
});

/// Provider for CategoriesDao
final categoriesDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).categoriesDao;
});

/// Provider for TransactionsDao
final transactionsDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).transactionsDao;
});

/// Provider for SubscriptionsDao
final subscriptionsDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).subscriptionsDao;
});

/// Provider for DebtsDao
final debtsDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).debtsDao;
});

/// Provider for SavingsGoalsDao
final savingsGoalsDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).savingsGoalsDao;
});

/// Provider for SavingsContributionsDao
final savingsContributionsDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).savingsContributionsDao;
});

/// Provider for SettingsDao
final settingsDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).settingsDao;
});

