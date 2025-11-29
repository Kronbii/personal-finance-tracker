import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/wallets_table.dart';

part 'wallets_dao.g.dart';

/// Data Access Object for Wallets table
@DriftAccessor(tables: [Wallets])
class WalletsDao extends DatabaseAccessor<AppDatabase> with _$WalletsDaoMixin {
  WalletsDao(super.db);

  // ============================================
  // CRUD Operations
  // ============================================

  /// Get all wallets, optionally including archived
  Future<List<WalletEntity>> getAllWallets({bool includeArchived = false}) {
    final query = select(wallets);
    if (!includeArchived) {
      query.where((w) => w.isArchived.equals(false));
    }
    query.orderBy([(w) => OrderingTerm.asc(w.sortOrder)]);
    return query.get();
  }

  /// Watch all wallets (stream)
  Stream<List<WalletEntity>> watchAllWallets({bool includeArchived = false}) {
    final query = select(wallets);
    if (!includeArchived) {
      query.where((w) => w.isArchived.equals(false));
    }
    query.orderBy([(w) => OrderingTerm.asc(w.sortOrder)]);
    return query.watch();
  }

  /// Get wallet by ID
  Future<WalletEntity?> getWalletById(String id) {
    return (select(wallets)..where((w) => w.id.equals(id))).getSingleOrNull();
  }

  /// Watch wallet by ID
  Stream<WalletEntity?> watchWalletById(String id) {
    return (select(wallets)..where((w) => w.id.equals(id))).watchSingleOrNull();
  }

  /// Insert new wallet
  Future<void> insertWallet(WalletsCompanion wallet) {
    return into(wallets).insert(wallet);
  }

  /// Update existing wallet
  Future<bool> updateWallet(WalletsCompanion wallet) {
    return update(wallets).replace(WalletEntity(
      id: wallet.id.value,
      name: wallet.name.value,
      initialBalance: wallet.initialBalance.value,
      currency: wallet.currency.value,
      iconName: wallet.iconName.value,
      gradientIndex: wallet.gradientIndex.value,
      isArchived: wallet.isArchived.value,
      sortOrder: wallet.sortOrder.value,
      createdAt: wallet.createdAt.value,
      updatedAt: DateTime.now(),
    ));
  }

  /// Update wallet by ID with partial data
  Future<int> updateWalletById(String id, WalletsCompanion wallet) {
    return (update(wallets)..where((w) => w.id.equals(id))).write(
      wallet.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  /// Delete wallet
  Future<int> deleteWallet(String id) {
    return (delete(wallets)..where((w) => w.id.equals(id))).go();
  }

  /// Archive wallet (soft delete)
  Future<int> archiveWallet(String id) {
    return (update(wallets)..where((w) => w.id.equals(id))).write(
      WalletsCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Unarchive wallet
  Future<int> unarchiveWallet(String id) {
    return (update(wallets)..where((w) => w.id.equals(id))).write(
      WalletsCompanion(
        isArchived: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ============================================
  // Query Helpers
  // ============================================

  /// Get wallet count
  Future<int> getWalletCount() async {
    final count = wallets.id.count();
    final query = selectOnly(wallets)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Check if wallet name exists
  Future<bool> walletNameExists(String name, {String? excludeId}) async {
    final query = select(wallets)
      ..where((w) => w.name.lower().equals(name.toLowerCase()));
    if (excludeId != null) {
      query.where((w) => w.id.equals(excludeId).not());
    }
    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Reorder wallets
  Future<void> reorderWallets(List<String> orderedIds) async {
    await batch((batch) {
      for (int i = 0; i < orderedIds.length; i++) {
        batch.update(
          wallets,
          WalletsCompanion(
            sortOrder: Value(i),
            updatedAt: Value(DateTime.now()),
          ),
          where: (w) => w.id.equals(orderedIds[i]),
        );
      }
    });
  }
}

