import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/subscriptions_table.dart';

part 'subscriptions_dao.g.dart';

/// Data Access Object for Subscriptions table
@DriftAccessor(tables: [Subscriptions])
class SubscriptionsDao extends DatabaseAccessor<AppDatabase>
    with _$SubscriptionsDaoMixin {
  SubscriptionsDao(super.db);

  // ============================================
  // CRUD Operations
  // ============================================

  /// Get all subscriptions
  Future<List<SubscriptionEntity>> getAllSubscriptions() {
    return (select(subscriptions)
          ..orderBy([(s) => OrderingTerm.asc(s.nextBillingDate)]))
        .get();
  }

  /// Watch all subscriptions
  Stream<List<SubscriptionEntity>> watchAllSubscriptions() {
    return (select(subscriptions)
          ..orderBy([(s) => OrderingTerm.asc(s.nextBillingDate)]))
        .watch();
  }

  /// Get active subscriptions
  Future<List<SubscriptionEntity>> getActiveSubscriptions() {
    return (select(subscriptions)
          ..where((s) => s.isActive.equals(true))
          ..orderBy([(s) => OrderingTerm.asc(s.nextBillingDate)]))
        .get();
  }

  /// Watch active subscriptions
  Stream<List<SubscriptionEntity>> watchActiveSubscriptions() {
    return (select(subscriptions)
          ..where((s) => s.isActive.equals(true))
          ..orderBy([(s) => OrderingTerm.asc(s.nextBillingDate)]))
        .watch();
  }

  /// Get subscription by ID
  Future<SubscriptionEntity?> getSubscriptionById(String id) {
    return (select(subscriptions)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert new subscription
  Future<void> insertSubscription(SubscriptionsCompanion subscription) {
    return into(subscriptions).insert(subscription);
  }

  /// Update subscription by ID
  Future<int> updateSubscriptionById(String id, SubscriptionsCompanion sub) {
    return (update(subscriptions)..where((s) => s.id.equals(id))).write(
      sub.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  /// Delete subscription
  Future<int> deleteSubscription(String id) {
    return (delete(subscriptions)..where((s) => s.id.equals(id))).go();
  }

  /// Toggle subscription active status
  Future<int> toggleSubscriptionActive(String id, bool isActive) {
    return (update(subscriptions)..where((s) => s.id.equals(id))).write(
      SubscriptionsCompanion(
        isActive: Value(isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ============================================
  // Query Helpers
  // ============================================

  /// Get subscriptions due within days
  Future<List<SubscriptionEntity>> getSubscriptionsDueSoon(int days) {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));
    return (select(subscriptions)
          ..where(
            (s) =>
                s.isActive.equals(true) &
                s.nextBillingDate.isBiggerOrEqualValue(now) &
                s.nextBillingDate.isSmallerOrEqualValue(futureDate),
          )
          ..orderBy([(s) => OrderingTerm.asc(s.nextBillingDate)]))
        .get();
  }

  /// Get total monthly subscription cost
  Future<double> getTotalMonthlySubscriptionCost() async {
    final subs = await getActiveSubscriptions();
    double total = 0;
    for (final sub in subs) {
      total += _normalizeToMonthly(sub.amount, sub.frequency);
    }
    return total;
  }

  /// Get total yearly subscription cost
  Future<double> getTotalYearlySubscriptionCost() async {
    final monthly = await getTotalMonthlySubscriptionCost();
    return monthly * 12;
  }

  /// Normalize subscription amount to monthly
  double _normalizeToMonthly(double amount, BillingFrequency frequency) {
    switch (frequency) {
      case BillingFrequency.daily:
        return amount * 30;
      case BillingFrequency.weekly:
        return amount * 4.33;
      case BillingFrequency.biweekly:
        return amount * 2.17;
      case BillingFrequency.monthly:
        return amount;
      case BillingFrequency.quarterly:
        return amount / 3;
      case BillingFrequency.yearly:
        return amount / 12;
    }
  }

  /// Update next billing date for a subscription
  Future<int> updateNextBillingDate(String id, DateTime nextDate) {
    return (update(subscriptions)..where((s) => s.id.equals(id))).write(
      SubscriptionsCompanion(
        nextBillingDate: Value(nextDate),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get subscriptions by wallet
  Future<List<SubscriptionEntity>> getSubscriptionsByWallet(String walletId) {
    return (select(subscriptions)
          ..where((s) => s.walletId.equals(walletId))
          ..orderBy([(s) => OrderingTerm.asc(s.nextBillingDate)]))
        .get();
  }
}

