import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/wallet_balances_table.dart';

part 'wallet_balances_dao.g.dart';

/// Data Access Object for Wallet Balances table
@DriftAccessor(tables: [WalletBalances])
class WalletBalancesDao extends DatabaseAccessor<AppDatabase>
    with _$WalletBalancesDaoMixin {
  WalletBalancesDao(super.db);

  // ============================================
  // CRUD Operations
  // ============================================

  /// Get all wallet balances
  Future<List<WalletBalanceEntity>> getAllBalances() {
    return (select(walletBalances)
          ..orderBy([
            (b) => OrderingTerm.desc(b.year),
            (b) => OrderingTerm.desc(b.month),
          ]))
        .get();
  }

  /// Watch all wallet balances
  Stream<List<WalletBalanceEntity>> watchAllBalances() {
    return (select(walletBalances)
          ..orderBy([
            (b) => OrderingTerm.desc(b.year),
            (b) => OrderingTerm.desc(b.month),
          ]))
        .watch();
  }

  /// Get balances for a specific wallet
  Future<List<WalletBalanceEntity>> getBalancesByWallet(String walletId) {
    return (select(walletBalances)
          ..where((b) => b.walletId.equals(walletId))
          ..orderBy([
            (b) => OrderingTerm.desc(b.year),
            (b) => OrderingTerm.desc(b.month),
          ]))
        .get();
  }

  /// Watch balances for a specific wallet
  Stream<List<WalletBalanceEntity>> watchBalancesByWallet(String walletId) {
    return (select(walletBalances)
          ..where((b) => b.walletId.equals(walletId))
          ..orderBy([
            (b) => OrderingTerm.desc(b.year),
            (b) => OrderingTerm.desc(b.month),
          ]))
        .watch();
  }

  /// Get balance for a specific wallet and month
  Future<WalletBalanceEntity?> getBalanceForMonth(
    String walletId,
    int year,
    int month,
  ) {
    return (select(walletBalances)
          ..where(
            (b) =>
                b.walletId.equals(walletId) &
                b.year.equals(year) &
                b.month.equals(month),
          ))
        .getSingleOrNull();
  }

  /// Get the latest balance for a wallet
  Future<WalletBalanceEntity?> getLatestBalance(String walletId) {
    return (select(walletBalances)
          ..where((b) => b.walletId.equals(walletId))
          ..orderBy([
            (b) => OrderingTerm.desc(b.year),
            (b) => OrderingTerm.desc(b.month),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Insert new balance entry
  Future<void> insertBalance(WalletBalancesCompanion balance) {
    return into(walletBalances).insert(balance);
  }

  /// Update balance entry by ID
  Future<int> updateBalanceById(
    String id,
    WalletBalancesCompanion balance,
  ) {
    return (update(walletBalances)..where((b) => b.id.equals(id))).write(
      balance.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  /// Upsert balance (insert or update if exists for same wallet/year/month)
  Future<void> upsertBalance(WalletBalancesCompanion balance) async {
    // Check if balance exists for this wallet/year/month
    final existing = await getBalanceForMonth(
      balance.walletId.value,
      balance.year.value,
      balance.month.value,
    );

    if (existing != null) {
      // Update existing
      await updateBalanceById(existing.id, balance);
    } else {
      // Insert new
      await insertBalance(balance);
    }
  }

  /// Delete balance entry
  Future<int> deleteBalance(String id) {
    return (delete(walletBalances)..where((b) => b.id.equals(id))).go();
  }
}

