import 'package:drift/drift.dart';

/// Wallets table - stores user's financial accounts
/// Each wallet has a balance that is computed from transactions
@DataClassName('WalletEntity')
class Wallets extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text()();

  /// Wallet name (e.g., "Main Bank Account", "Cash")
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Initial balance when wallet was created
  RealColumn get initialBalance => real().withDefault(const Constant(0.0))();

  /// Currency code (ISO 4217, e.g., "USD", "EUR")
  TextColumn get currency => text().withLength(min: 3, max: 3).withDefault(const Constant('USD'))();

  /// Wallet icon name (for UI display)
  TextColumn get iconName => text().withDefault(const Constant('wallet'))();

  /// Gradient index for visual distinction (0-4)
  IntColumn get gradientIndex => integer().withDefault(const Constant(0))();

  /// Whether this wallet is archived/hidden
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Display order for sorting
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

