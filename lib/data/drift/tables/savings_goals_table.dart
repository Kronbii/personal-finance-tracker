import 'package:drift/drift.dart';

/// Savings Goals table - tracks savings targets
@DataClassName('SavingsGoalEntity')
class SavingsGoals extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text()();

  /// Goal name (e.g., "Vacation", "Emergency Fund")
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Target amount to save
  RealColumn get targetAmount => real()();

  /// Current saved amount (computed from contributions)
  RealColumn get currentAmount => real().withDefault(const Constant(0.0))();

  /// Currency code
  TextColumn get currency => text().withLength(min: 3, max: 3).withDefault(const Constant('USD'))();

  /// Target date to reach goal (nullable)
  DateTimeColumn get targetDate => dateTime().nullable()();

  /// Icon name for UI
  TextColumn get iconName => text().withDefault(const Constant('target'))();

  /// Color hex for visual distinction
  TextColumn get colorHex => text().withDefault(const Constant('#30D158'))();

  /// Optional description
  TextColumn get description => text().nullable()();

  /// Whether goal is achieved
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// Whether goal is archived
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Display order
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

