import 'package:drift/drift.dart';

/// Debt type - money owed or lent
enum DebtType { owed, lent }

/// Debts table - tracks money owed to or by others
@DataClassName('DebtEntity')
class Debts extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text()();

  /// Person/entity name
  TextColumn get personName => text().withLength(min: 1, max: 100)();

  /// Original debt amount
  RealColumn get originalAmount => real()();

  /// Current remaining amount
  RealColumn get remainingAmount => real()();

  /// Currency code
  TextColumn get currency => text().withLength(min: 3, max: 3).withDefault(const Constant('USD'))();

  /// Debt type: money you owe (owed) or money owed to you (lent)
  TextColumn get type => text().map(const DebtTypeConverter())();

  /// Optional description/reason
  TextColumn get description => text().nullable()();

  /// Due date (nullable)
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// Associated wallet for payments
  TextColumn get walletId => text().nullable()();

  /// Interest rate (percentage, nullable)
  RealColumn get interestRate => real().nullable()();

  /// Whether debt is fully paid
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();

  /// Contact information (phone/email)
  TextColumn get contactInfo => text().nullable()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Converter for DebtType enum
class DebtTypeConverter extends TypeConverter<DebtType, String> {
  const DebtTypeConverter();

  @override
  DebtType fromSql(String fromDb) {
    return DebtType.values.firstWhere(
      (e) => e.name == fromDb,
      orElse: () => DebtType.owed,
    );
  }

  @override
  String toSql(DebtType value) => value.name;
}

