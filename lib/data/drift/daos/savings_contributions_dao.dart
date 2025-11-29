import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/savings_contributions_table.dart';

part 'savings_contributions_dao.g.dart';

/// Data Access Object for SavingsContributions table
@DriftAccessor(tables: [SavingsContributions])
class SavingsContributionsDao extends DatabaseAccessor<AppDatabase>
    with _$SavingsContributionsDaoMixin {
  SavingsContributionsDao(super.db);

  // ============================================
  // CRUD Operations
  // ============================================

  /// Get all contributions for a savings goal
  Future<List<SavingsContributionEntity>> getContributionsForGoal(
    String goalId,
  ) {
    return (select(savingsContributions)
          ..where((c) => c.savingsGoalId.equals(goalId))
          ..orderBy([(c) => OrderingTerm.desc(c.date)]))
        .get();
  }

  /// Watch contributions for a goal
  Stream<List<SavingsContributionEntity>> watchContributionsForGoal(
    String goalId,
  ) {
    return (select(savingsContributions)
          ..where((c) => c.savingsGoalId.equals(goalId))
          ..orderBy([(c) => OrderingTerm.desc(c.date)]))
        .watch();
  }

  /// Get contribution by ID
  Future<SavingsContributionEntity?> getContributionById(String id) {
    return (select(savingsContributions)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert new contribution
  Future<void> insertContribution(SavingsContributionsCompanion contribution) {
    return into(savingsContributions).insert(contribution);
  }

  /// Update contribution
  Future<int> updateContributionById(
    String id,
    SavingsContributionsCompanion contribution,
  ) {
    return (update(savingsContributions)..where((c) => c.id.equals(id))).write(
      contribution.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  /// Delete contribution
  Future<int> deleteContribution(String id) {
    return (delete(savingsContributions)..where((c) => c.id.equals(id))).go();
  }

  /// Delete all contributions for a goal
  Future<int> deleteContributionsForGoal(String goalId) {
    return (delete(savingsContributions)
          ..where((c) => c.savingsGoalId.equals(goalId)))
        .go();
  }

  // ============================================
  // Analytics Queries
  // ============================================

  /// Get total contributions for a goal
  Future<double> getTotalContributionsForGoal(String goalId) async {
    final sum = savingsContributions.amount.sum();
    final query = selectOnly(savingsContributions)
      ..addColumns([sum])
      ..where(savingsContributions.savingsGoalId.equals(goalId));
    final result = await query.getSingle();
    return result.read(sum) ?? 0.0;
  }

  /// Get contributions in date range
  Future<List<SavingsContributionEntity>> getContributionsInRange(
    DateTime start,
    DateTime end, {
    String? goalId,
  }) {
    final query = select(savingsContributions)
      ..where(
        (c) =>
            c.date.isBiggerOrEqualValue(start) &
            c.date.isSmallerOrEqualValue(end),
      )
      ..orderBy([(c) => OrderingTerm.desc(c.date)]);

    if (goalId != null) {
      query.where((c) => c.savingsGoalId.equals(goalId));
    }

    return query.get();
  }

  /// Get total contributions for a period
  Future<double> getTotalContributionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final sum = savingsContributions.amount.sum();
    final query = selectOnly(savingsContributions)
      ..addColumns([sum])
      ..where(
        savingsContributions.date.isBiggerOrEqualValue(start) &
            savingsContributions.date.isSmallerOrEqualValue(end),
      );
    final result = await query.getSingle();
    return result.read(sum) ?? 0.0;
  }

  /// Get recent contributions (last N)
  Future<List<SavingsContributionEntity>> getRecentContributions(int limit) {
    return (select(savingsContributions)
          ..orderBy([(c) => OrderingTerm.desc(c.date)])
          ..limit(limit))
        .get();
  }
}

