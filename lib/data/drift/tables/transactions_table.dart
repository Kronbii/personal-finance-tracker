import 'package:drift/drift.dart';

/// Transaction type enum
enum TransactionType { expense, income, transfer }

/// Transactions table - stores all financial transactions
@DataClassName('TransactionEntity')
class Transactions extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text()();

  /// Transaction amount (positive value)
  RealColumn get amount => real()();

  /// Transaction type: expense, income, or transfer
  TextColumn get type => text().map(const TransactionTypeConverter())();

  /// Associated wallet ID (source wallet for transfers)
  TextColumn get walletId => text()();

  /// Category ID (nullable for transfers)
  TextColumn get categoryId => text().nullable()();

  /// Destination wallet ID for transfers (nullable)
  TextColumn get toWalletId => text().nullable()();

  /// Transaction date
  DateTimeColumn get date => dateTime()();

  /// Optional note/description
  TextColumn get note => text().nullable()();

  /// Optional tags (comma-separated)
  TextColumn get tags => text().nullable()();

  /// Whether this transaction is confirmed/verified
  BoolColumn get isConfirmed => boolean().withDefault(const Constant(true))();

  /// Optional attachment/receipt path
  TextColumn get attachmentPath => text().nullable()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Converter for TransactionType enum
class TransactionTypeConverter extends TypeConverter<TransactionType, String> {
  const TransactionTypeConverter();

  @override
  TransactionType fromSql(String fromDb) {
    return TransactionType.values.firstWhere(
      (e) => e.name == fromDb,
      orElse: () => TransactionType.expense,
    );
  }

  @override
  String toSql(TransactionType value) => value.name;
}

