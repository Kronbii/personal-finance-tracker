import 'package:drift/drift.dart';

/// Savings Contributions table - tracks contributions to savings goals
@DataClassName('SavingsContributionEntity')
class SavingsContributions extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text()();

  /// Associated savings goal ID
  TextColumn get savingsGoalId => text()();

  /// Contribution amount (positive for deposit, negative for withdrawal)
  RealColumn get amount => real()();

  /// Associated wallet ID (source of contribution)
  TextColumn get walletId => text().nullable()();

  /// Contribution date
  DateTimeColumn get date => dateTime()();

  /// Optional note
  TextColumn get note => text().nullable()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

