import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/savings_goals_table.dart';

part 'savings_goals_dao.g.dart';

/// Data Access Object for SavingsGoals table
@DriftAccessor(tables: [SavingsGoals])
class SavingsGoalsDao extends DatabaseAccessor<AppDatabase>
    with _$SavingsGoalsDaoMixin {
  SavingsGoalsDao(super.db);

  // ============================================
  // CRUD Operations
  // ============================================

  /// Get all savings goals
  Future<List<SavingsGoalEntity>> getAllSavingsGoals() {
    return (select(savingsGoals)
          ..orderBy([(g) => OrderingTerm.asc(g.sortOrder)]))
        .get();
  }

  /// Watch all savings goals
  Stream<List<SavingsGoalEntity>> watchAllSavingsGoals() {
    return (select(savingsGoals)
          ..orderBy([(g) => OrderingTerm.asc(g.sortOrder)]))
        .watch();
  }

  /// Get active (non-completed, non-archived) goals
  Future<List<SavingsGoalEntity>> getActiveGoals() {
    return (select(savingsGoals)
          ..where(
            (g) => g.isCompleted.equals(false) & g.isArchived.equals(false),
          )
          ..orderBy([(g) => OrderingTerm.asc(g.sortOrder)]))
        .get();
  }

  /// Watch active goals
  Stream<List<SavingsGoalEntity>> watchActiveGoals() {
    return (select(savingsGoals)
          ..where(
            (g) => g.isCompleted.equals(false) & g.isArchived.equals(false),
          )
          ..orderBy([(g) => OrderingTerm.asc(g.sortOrder)]))
        .watch();
  }

  /// Get completed goals
  Future<List<SavingsGoalEntity>> getCompletedGoals() {
    return (select(savingsGoals)
          ..where((g) => g.isCompleted.equals(true))
          ..orderBy([(g) => OrderingTerm.desc(g.updatedAt)]))
        .get();
  }

  /// Get savings goal by ID
  Future<SavingsGoalEntity?> getSavingsGoalById(String id) {
    return (select(savingsGoals)..where((g) => g.id.equals(id)))
        .getSingleOrNull();
  }

  /// Watch savings goal by ID
  Stream<SavingsGoalEntity?> watchSavingsGoalById(String id) {
    return (select(savingsGoals)..where((g) => g.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Insert new savings goal
  Future<void> insertSavingsGoal(SavingsGoalsCompanion goal) {
    return into(savingsGoals).insert(goal);
  }

  /// Update savings goal by ID
  Future<int> updateSavingsGoalById(String id, SavingsGoalsCompanion goal) {
    return (update(savingsGoals)..where((g) => g.id.equals(id))).write(
      goal.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  /// Delete savings goal
  Future<int> deleteSavingsGoal(String id) {
    return (delete(savingsGoals)..where((g) => g.id.equals(id))).go();
  }

  /// Archive savings goal
  Future<int> archiveSavingsGoal(String id) {
    return (update(savingsGoals)..where((g) => g.id.equals(id))).write(
      SavingsGoalsCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Mark goal as completed
  Future<int> markGoalCompleted(String id) {
    return (update(savingsGoals)..where((g) => g.id.equals(id))).write(
      SavingsGoalsCompanion(
        isCompleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update current amount
  Future<int> updateCurrentAmount(String id, double amount) async {
    // Get the goal to check if it should be marked complete
    final goal = await getSavingsGoalById(id);
    if (goal == null) return 0;

    final isCompleted = amount >= goal.targetAmount;
    return (update(savingsGoals)..where((g) => g.id.equals(id))).write(
      SavingsGoalsCompanion(
        currentAmount: Value(amount),
        isCompleted: Value(isCompleted),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ============================================
  // Analytics Queries
  // ============================================

  /// Get total saved across all active goals
  Future<double> getTotalSaved() async {
    final sum = savingsGoals.currentAmount.sum();
    final query = selectOnly(savingsGoals)
      ..addColumns([sum])
      ..where(
        savingsGoals.isArchived.equals(false),
      );
    final result = await query.getSingle();
    return result.read(sum) ?? 0.0;
  }

  /// Get total target across all active goals
  Future<double> getTotalTarget() async {
    final sum = savingsGoals.targetAmount.sum();
    final query = selectOnly(savingsGoals)
      ..addColumns([sum])
      ..where(
        savingsGoals.isArchived.equals(false) &
            savingsGoals.isCompleted.equals(false),
      );
    final result = await query.getSingle();
    return result.read(sum) ?? 0.0;
  }

  /// Get overall progress percentage
  Future<double> getOverallProgress() async {
    final saved = await getTotalSaved();
    final target = await getTotalTarget();
    if (target == 0) return 0;
    return (saved / target * 100).clamp(0, 100);
  }

  /// Reorder goals
  Future<void> reorderGoals(List<String> orderedIds) async {
    await batch((batch) {
      for (int i = 0; i < orderedIds.length; i++) {
        batch.update(
          savingsGoals,
          SavingsGoalsCompanion(
            sortOrder: Value(i),
            updatedAt: Value(DateTime.now()),
          ),
          where: (g) => g.id.equals(orderedIds[i]),
        );
      }
    });
  }
}

