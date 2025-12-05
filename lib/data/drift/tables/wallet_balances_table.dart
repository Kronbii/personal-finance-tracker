import 'package:drift/drift.dart';

/// Wallet balances table - stores monthly balance snapshots for each wallet
@DataClassName('WalletBalanceEntity')
class WalletBalances extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text()();

  /// Wallet ID (foreign key to wallets)
  TextColumn get walletId => text()();

  /// Year of the balance entry
  IntColumn get year => integer()();

  /// Month of the balance entry (1-12)
  IntColumn get month => integer()();

  /// Balance amount at the end of this month
  RealColumn get balance => real()();

  /// Optional note about this balance entry
  TextColumn get note => text().nullable()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

