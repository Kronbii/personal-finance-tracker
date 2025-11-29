import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/transactions_table.dart';
import '../tables/categories_table.dart';
import '../tables/wallets_table.dart';

part 'transactions_dao.g.dart';

/// Transaction with joined category and wallet data
class TransactionWithDetails {
  final TransactionEntity transaction;
  final CategoryEntity? category;
  final WalletEntity wallet;
  final WalletEntity? toWallet;

  TransactionWithDetails({
    required this.transaction,
    this.category,
    required this.wallet,
    this.toWallet,
  });
}

/// Data Access Object for Transactions table
@DriftAccessor(tables: [Transactions, Categories, Wallets])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  // ============================================
  // CRUD Operations
  // ============================================

  /// Get all transactions ordered by date
  Future<List<TransactionEntity>> getAllTransactions() {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Watch all transactions
  Stream<List<TransactionEntity>> watchAllTransactions() {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Get transaction by ID
  Future<TransactionEntity?> getTransactionById(String id) {
    return (select(transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert new transaction
  Future<void> insertTransaction(TransactionsCompanion transaction) {
    return into(transactions).insert(transaction);
  }

  /// Insert multiple transactions (batch)
  Future<void> insertTransactions(List<TransactionsCompanion> txns) {
    return batch((batch) {
      batch.insertAll(transactions, txns);
    });
  }

  /// Update transaction by ID
  Future<int> updateTransactionById(String id, TransactionsCompanion txn) {
    return (update(transactions)..where((t) => t.id.equals(id))).write(
      txn.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  /// Delete transaction
  Future<int> deleteTransaction(String id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  /// Delete multiple transactions
  Future<int> deleteTransactions(List<String> ids) {
    return (delete(transactions)..where((t) => t.id.isIn(ids))).go();
  }

  // ============================================
  // Filtered Queries
  // ============================================

  /// Get transactions by wallet
  Future<List<TransactionEntity>> getTransactionsByWallet(String walletId) {
    return (select(transactions)
          ..where(
            (t) => t.walletId.equals(walletId) | t.toWalletId.equals(walletId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Watch transactions by wallet
  Stream<List<TransactionEntity>> watchTransactionsByWallet(String walletId) {
    return (select(transactions)
          ..where(
            (t) => t.walletId.equals(walletId) | t.toWalletId.equals(walletId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Get transactions by category
  Future<List<TransactionEntity>> getTransactionsByCategory(String categoryId) {
    return (select(transactions)
          ..where((t) => t.categoryId.equals(categoryId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Get transactions by type
  Future<List<TransactionEntity>> getTransactionsByType(TransactionType type) {
    return (select(transactions)
          ..where((t) => t.type.equals(type.name))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Watch transactions by type
  Stream<List<TransactionEntity>> watchTransactionsByType(TransactionType type) {
    return (select(transactions)
          ..where((t) => t.type.equals(type.name))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Get transactions in date range
  Future<List<TransactionEntity>> getTransactionsInRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerOrEqualValue(end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Watch transactions in date range
  Stream<List<TransactionEntity>> watchTransactionsInRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerOrEqualValue(end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Get transactions for a specific month
  Future<List<TransactionEntity>> getTransactionsForMonth(
    int year,
    int month,
  ) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return getTransactionsInRange(start, end);
  }

  /// Watch transactions for current month
  Stream<List<TransactionEntity>> watchTransactionsForMonth(
    int year,
    int month,
  ) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return watchTransactionsInRange(start, end);
  }

  // ============================================
  // Analytics Queries
  // ============================================

  /// Get total income for a period
  Future<double> getTotalIncome(DateTime start, DateTime end) async {
    final sum = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([sum])
      ..where(
        transactions.type.equals(TransactionType.income.name) &
            transactions.date.isBiggerOrEqualValue(start) &
            transactions.date.isSmallerOrEqualValue(end),
      );
    final result = await query.getSingle();
    return result.read(sum) ?? 0.0;
  }

  /// Get total expenses for a period
  Future<double> getTotalExpenses(DateTime start, DateTime end) async {
    final sum = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([sum])
      ..where(
        transactions.type.equals(TransactionType.expense.name) &
            transactions.date.isBiggerOrEqualValue(start) &
            transactions.date.isSmallerOrEqualValue(end),
      );
    final result = await query.getSingle();
    return result.read(sum) ?? 0.0;
  }

  /// Get spending by category for a period
  Future<Map<String, double>> getSpendingByCategory(
    DateTime start,
    DateTime end,
  ) async {
    final sum = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([transactions.categoryId, sum])
      ..where(
        transactions.type.equals(TransactionType.expense.name) &
            transactions.date.isBiggerOrEqualValue(start) &
            transactions.date.isSmallerOrEqualValue(end),
      )
      ..groupBy([transactions.categoryId]);

    final results = await query.get();
    return Map.fromEntries(
      results
          .where((r) => r.read(transactions.categoryId) != null)
          .map((r) => MapEntry(
                r.read(transactions.categoryId)!,
                r.read(sum) ?? 0.0,
              )),
    );
  }

  /// Get income by category for a period
  Future<Map<String, double>> getIncomeByCategory(
    DateTime start,
    DateTime end,
  ) async {
    final sum = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([transactions.categoryId, sum])
      ..where(
        transactions.type.equals(TransactionType.income.name) &
            transactions.date.isBiggerOrEqualValue(start) &
            transactions.date.isSmallerOrEqualValue(end),
      )
      ..groupBy([transactions.categoryId]);

    final results = await query.get();
    return Map.fromEntries(
      results
          .where((r) => r.read(transactions.categoryId) != null)
          .map((r) => MapEntry(
                r.read(transactions.categoryId)!,
                r.read(sum) ?? 0.0,
              )),
    );
  }

  /// Calculate wallet balance from transactions
  Future<double> calculateWalletBalance(String walletId) async {
    // Get initial balance
    final wallet = await (select(wallets)..where((w) => w.id.equals(walletId)))
        .getSingleOrNull();
    double balance = wallet?.initialBalance ?? 0.0;

    // Add income
    final incomeSum = transactions.amount.sum();
    final incomeQuery = selectOnly(transactions)
      ..addColumns([incomeSum])
      ..where(
        transactions.walletId.equals(walletId) &
            transactions.type.equals(TransactionType.income.name),
      );
    final incomeResult = await incomeQuery.getSingle();
    balance += incomeResult.read(incomeSum) ?? 0.0;

    // Subtract expenses
    final expenseSum = transactions.amount.sum();
    final expenseQuery = selectOnly(transactions)
      ..addColumns([expenseSum])
      ..where(
        transactions.walletId.equals(walletId) &
            transactions.type.equals(TransactionType.expense.name),
      );
    final expenseResult = await expenseQuery.getSingle();
    balance -= expenseResult.read(expenseSum) ?? 0.0;

    // Add incoming transfers
    final transferInSum = transactions.amount.sum();
    final transferInQuery = selectOnly(transactions)
      ..addColumns([transferInSum])
      ..where(
        transactions.toWalletId.equals(walletId) &
            transactions.type.equals(TransactionType.transfer.name),
      );
    final transferInResult = await transferInQuery.getSingle();
    balance += transferInResult.read(transferInSum) ?? 0.0;

    // Subtract outgoing transfers
    final transferOutSum = transactions.amount.sum();
    final transferOutQuery = selectOnly(transactions)
      ..addColumns([transferOutSum])
      ..where(
        transactions.walletId.equals(walletId) &
            transactions.type.equals(TransactionType.transfer.name),
      );
    final transferOutResult = await transferOutQuery.getSingle();
    balance -= transferOutResult.read(transferOutSum) ?? 0.0;

    return balance;
  }

  /// Get all-time net savings (total income - total expenses)
  Future<double> getAllTimeNetSavings() async {
    final incomeSum = transactions.amount.sum();
    final incomeQuery = selectOnly(transactions)
      ..addColumns([incomeSum])
      ..where(transactions.type.equals(TransactionType.income.name));
    final incomeResult = await incomeQuery.getSingle();
    final totalIncome = incomeResult.read(incomeSum) ?? 0.0;

    final expenseSum = transactions.amount.sum();
    final expenseQuery = selectOnly(transactions)
      ..addColumns([expenseSum])
      ..where(transactions.type.equals(TransactionType.expense.name));
    final expenseResult = await expenseQuery.getSingle();
    final totalExpenses = expenseResult.read(expenseSum) ?? 0.0;

    return totalIncome - totalExpenses;
  }

  /// Search transactions by note
  Future<List<TransactionEntity>> searchTransactions(String query) {
    return (select(transactions)
          ..where((t) => t.note.like('%$query%'))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }
}

