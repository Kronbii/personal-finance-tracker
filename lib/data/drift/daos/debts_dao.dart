import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/debts_table.dart';

part 'debts_dao.g.dart';

/// Data Access Object for Debts table
@DriftAccessor(tables: [Debts])
class DebtsDao extends DatabaseAccessor<AppDatabase> with _$DebtsDaoMixin {
  DebtsDao(super.db);

  // ============================================
  // CRUD Operations
  // ============================================

  /// Get all debts
  Future<List<DebtEntity>> getAllDebts() {
    return (select(debts)..orderBy([(d) => OrderingTerm.asc(d.dueDate)])).get();
  }

  /// Watch all debts
  Stream<List<DebtEntity>> watchAllDebts() {
    return (select(debts)..orderBy([(d) => OrderingTerm.asc(d.dueDate)]))
        .watch();
  }

  /// Get active (unpaid) debts
  Future<List<DebtEntity>> getActiveDebts() {
    return (select(debts)
          ..where((d) => d.isPaid.equals(false))
          ..orderBy([(d) => OrderingTerm.asc(d.dueDate)]))
        .get();
  }

  /// Watch active debts
  Stream<List<DebtEntity>> watchActiveDebts() {
    return (select(debts)
          ..where((d) => d.isPaid.equals(false))
          ..orderBy([(d) => OrderingTerm.asc(d.dueDate)]))
        .watch();
  }

  /// Get debts by type
  Future<List<DebtEntity>> getDebtsByType(DebtType type) {
    return (select(debts)
          ..where((d) => d.type.equals(type.name) & d.isPaid.equals(false))
          ..orderBy([(d) => OrderingTerm.asc(d.dueDate)]))
        .get();
  }

  /// Watch debts by type
  Stream<List<DebtEntity>> watchDebtsByType(DebtType type) {
    return (select(debts)
          ..where((d) => d.type.equals(type.name) & d.isPaid.equals(false))
          ..orderBy([(d) => OrderingTerm.asc(d.dueDate)]))
        .watch();
  }

  /// Get debt by ID
  Future<DebtEntity?> getDebtById(String id) {
    return (select(debts)..where((d) => d.id.equals(id))).getSingleOrNull();
  }

  /// Insert new debt
  Future<void> insertDebt(DebtsCompanion debt) {
    return into(debts).insert(debt);
  }

  /// Update debt by ID
  Future<int> updateDebtById(String id, DebtsCompanion debt) {
    return (update(debts)..where((d) => d.id.equals(id))).write(
      debt.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  /// Delete debt
  Future<int> deleteDebt(String id) {
    return (delete(debts)..where((d) => d.id.equals(id))).go();
  }

  /// Mark debt as paid
  Future<int> markDebtAsPaid(String id) {
    return (update(debts)..where((d) => d.id.equals(id))).write(
      DebtsCompanion(
        isPaid: const Value(true),
        remainingAmount: const Value(0),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update remaining amount
  Future<int> updateRemainingAmount(String id, double amount) {
    return (update(debts)..where((d) => d.id.equals(id))).write(
      DebtsCompanion(
        remainingAmount: Value(amount),
        isPaid: Value(amount <= 0),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ============================================
  // Analytics Queries
  // ============================================

  /// Get total amount owed (debts you owe)
  Future<double> getTotalOwed() async {
    final sum = debts.remainingAmount.sum();
    final query = selectOnly(debts)
      ..addColumns([sum])
      ..where(
        debts.type.equals(DebtType.owed.name) & debts.isPaid.equals(false),
      );
    final result = await query.getSingle();
    return result.read(sum) ?? 0.0;
  }

  /// Get total amount lent (money owed to you)
  Future<double> getTotalLent() async {
    final sum = debts.remainingAmount.sum();
    final query = selectOnly(debts)
      ..addColumns([sum])
      ..where(
        debts.type.equals(DebtType.lent.name) & debts.isPaid.equals(false),
      );
    final result = await query.getSingle();
    return result.read(sum) ?? 0.0;
  }

  /// Get net debt position (positive = more lent than owed)
  Future<double> getNetDebtPosition() async {
    final lent = await getTotalLent();
    final owed = await getTotalOwed();
    return lent - owed;
  }

  /// Get overdue debts
  Future<List<DebtEntity>> getOverdueDebts() {
    final now = DateTime.now();
    return (select(debts)
          ..where(
            (d) =>
                d.isPaid.equals(false) &
                d.dueDate.isNotNull() &
                d.dueDate.isSmallerThanValue(now),
          )
          ..orderBy([(d) => OrderingTerm.asc(d.dueDate)]))
        .get();
  }

  /// Get debts due soon (within days)
  Future<List<DebtEntity>> getDebtsDueSoon(int days) {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));
    return (select(debts)
          ..where(
            (d) =>
                d.isPaid.equals(false) &
                d.dueDate.isNotNull() &
                d.dueDate.isBiggerOrEqualValue(now) &
                d.dueDate.isSmallerOrEqualValue(futureDate),
          )
          ..orderBy([(d) => OrderingTerm.asc(d.dueDate)]))
        .get();
  }
}

