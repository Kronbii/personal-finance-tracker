import 'package:supabase_flutter/supabase_flutter.dart';

import '../drift/database.dart';
import '../drift/tables/categories_table.dart';
import '../drift/tables/transactions_table.dart';

/// Service for synchronizing local Drift database with Supabase
/// Uses timestamp-based UPSERT logic for conflict resolution
class SyncService {
  final AppDatabase _database;
  final SupabaseClient? _supabase;

  SyncService({
    required AppDatabase database,
    SupabaseClient? supabase,
  })  : _database = database,
        _supabase = supabase;

  /// Check if Supabase is configured
  bool get isConfigured => _supabase != null;

  /// Get last sync timestamp from settings
  Future<DateTime?> getLastSyncTimestamp() async {
    return _database.settingsDao.getLastSyncTimestamp();
  }

  /// Set last sync timestamp
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    await _database.settingsDao.setLastSyncTimestamp(timestamp);
  }

  /// Perform full sync (push and pull)
  /// Returns the number of changes synced
  Future<SyncResult> syncNow() async {
    if (!isConfigured) {
      throw SyncException('Supabase is not configured');
    }

    final lastSync = await getLastSyncTimestamp();
    final syncStart = DateTime.now();

    int pushed = 0;
    int pulled = 0;

    try {
      // Push local changes
      pushed = await _pushChanges(lastSync);

      // Pull remote changes
      pulled = await _pullChanges(lastSync);

      // Update last sync timestamp
      await setLastSyncTimestamp(syncStart);

      return SyncResult(
        success: true,
        pushedCount: pushed,
        pulledCount: pulled,
        timestamp: syncStart,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        error: e.toString(),
        pushedCount: pushed,
        pulledCount: pulled,
      );
    }
  }

  /// Push local changes to Supabase
  Future<int> _pushChanges(DateTime? lastSync) async {
    int count = 0;

    // Push wallets
    count += await _pushTable(
      tableName: 'wallets',
      getLocalData: () => _database.walletsDao.getAllWallets(includeArchived: true),
      toJson: (wallet) => _walletToJson(wallet),
      lastSync: lastSync,
    );

    // Push categories
    count += await _pushTable(
      tableName: 'categories',
      getLocalData: () => _database.categoriesDao.getAllCategories(),
      toJson: (category) => _categoryToJson(category),
      lastSync: lastSync,
    );

    // Push transactions
    count += await _pushTable(
      tableName: 'transactions',
      getLocalData: () => _database.transactionsDao.getAllTransactions(),
      toJson: (transaction) => _transactionToJson(transaction),
      lastSync: lastSync,
    );

    // TODO: Push subscriptions, debts, savings_goals, savings_contributions

    return count;
  }

  /// Pull remote changes from Supabase
  Future<int> _pullChanges(DateTime? lastSync) async {
    int count = 0;

    // Pull wallets
    count += await _pullTable(
      tableName: 'wallets',
      fromJson: _walletFromJson,
      upsert: (data) => _upsertWallet(data),
      lastSync: lastSync,
    );

    // Pull categories
    count += await _pullTable(
      tableName: 'categories',
      fromJson: _categoryFromJson,
      upsert: (data) => _upsertCategory(data),
      lastSync: lastSync,
    );

    // Pull transactions
    count += await _pullTable(
      tableName: 'transactions',
      fromJson: _transactionFromJson,
      upsert: (data) => _upsertTransaction(data),
      lastSync: lastSync,
    );

    // TODO: Pull subscriptions, debts, savings_goals, savings_contributions

    return count;
  }

  /// Generic push table helper
  Future<int> _pushTable<T>({
    required String tableName,
    required Future<List<T>> Function() getLocalData,
    required Map<String, dynamic> Function(T) toJson,
    DateTime? lastSync,
  }) async {
    final data = await getLocalData();
    int count = 0;

    for (final item in data) {
      final json = toJson(item);
      final updatedAt = DateTime.tryParse(json['updated_at'] ?? '');

      // Only push if newer than last sync
      if (lastSync == null || (updatedAt != null && updatedAt.isAfter(lastSync))) {
        await _supabase!.from(tableName).upsert(json);
        count++;
      }
    }

    return count;
  }

  /// Generic pull table helper
  Future<int> _pullTable<T>({
    required String tableName,
    required T Function(Map<String, dynamic>) fromJson,
    required Future<void> Function(T) upsert,
    DateTime? lastSync,
  }) async {
    var query = _supabase!.from(tableName).select();

    if (lastSync != null) {
      query = query.gt('updated_at', lastSync.toIso8601String());
    }

    final response = await query;
    int count = 0;

    for (final row in response as List) {
      final item = fromJson(row);
      await upsert(item);
      count++;
    }

    return count;
  }

  // ============================================
  // Wallet conversions
  // ============================================

  Map<String, dynamic> _walletToJson(WalletEntity wallet) {
    return {
      'id': wallet.id,
      'name': wallet.name,
      'initial_balance': wallet.initialBalance,
      'currency': wallet.currency,
      'icon_name': wallet.iconName,
      'gradient_index': wallet.gradientIndex,
      'is_archived': wallet.isArchived,
      'sort_order': wallet.sortOrder,
      'created_at': wallet.createdAt.toIso8601String(),
      'updated_at': wallet.updatedAt.toIso8601String(),
    };
  }

  WalletEntity _walletFromJson(Map<String, dynamic> json) {
    return WalletEntity(
      id: json['id'],
      name: json['name'],
      initialBalance: (json['initial_balance'] as num).toDouble(),
      currency: json['currency'],
      iconName: json['icon_name'],
      gradientIndex: json['gradient_index'],
      isArchived: json['is_archived'],
      sortOrder: json['sort_order'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Future<void> _upsertWallet(WalletEntity wallet) async {
    final existing = await _database.walletsDao.getWalletById(wallet.id);
    if (existing == null || wallet.updatedAt.isAfter(existing.updatedAt)) {
      // Insert or update based on timestamp
      await _database.into(_database.wallets).insertOnConflictUpdate(wallet);
    }
  }

  // ============================================
  // Category conversions
  // ============================================

  Map<String, dynamic> _categoryToJson(CategoryEntity category) {
    return {
      'id': category.id,
      'name': category.name,
      'type': category.type.name,
      'icon_name': category.iconName,
      'color_hex': category.colorHex,
      'parent_id': category.parentId,
      'is_default': category.isDefault,
      'sort_order': category.sortOrder,
      'created_at': category.createdAt.toIso8601String(),
      'updated_at': category.updatedAt.toIso8601String(),
    };
  }

  CategoryEntity _categoryFromJson(Map<String, dynamic> json) {
    return CategoryEntity(
      id: json['id'],
      name: json['name'],
      type: CategoryType.values.firstWhere((e) => e.name == json['type']),
      iconName: json['icon_name'],
      colorHex: json['color_hex'],
      parentId: json['parent_id'],
      isDefault: json['is_default'],
      sortOrder: json['sort_order'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Future<void> _upsertCategory(CategoryEntity category) async {
    final existing = await _database.categoriesDao.getCategoryById(category.id);
    if (existing == null || category.updatedAt.isAfter(existing.updatedAt)) {
      await _database.into(_database.categories).insertOnConflictUpdate(category);
    }
  }

  // ============================================
  // Transaction conversions
  // ============================================

  Map<String, dynamic> _transactionToJson(TransactionEntity txn) {
    return {
      'id': txn.id,
      'amount': txn.amount,
      'type': txn.type.name,
      'wallet_id': txn.walletId,
      'category_id': txn.categoryId,
      'to_wallet_id': txn.toWalletId,
      'date': txn.date.toIso8601String(),
      'note': txn.note,
      'tags': txn.tags,
      'is_confirmed': txn.isConfirmed,
      'attachment_path': txn.attachmentPath,
      'created_at': txn.createdAt.toIso8601String(),
      'updated_at': txn.updatedAt.toIso8601String(),
    };
  }

  TransactionEntity _transactionFromJson(Map<String, dynamic> json) {
    return TransactionEntity(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
      walletId: json['wallet_id'],
      categoryId: json['category_id'],
      toWalletId: json['to_wallet_id'],
      date: DateTime.parse(json['date']),
      note: json['note'],
      tags: json['tags'],
      isConfirmed: json['is_confirmed'] ?? true,
      attachmentPath: json['attachment_path'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Future<void> _upsertTransaction(TransactionEntity txn) async {
    final existing = await _database.transactionsDao.getTransactionById(txn.id);
    if (existing == null || txn.updatedAt.isAfter(existing.updatedAt)) {
      await _database.into(_database.transactions).insertOnConflictUpdate(txn);
    }
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String? error;
  final int pushedCount;
  final int pulledCount;
  final DateTime? timestamp;

  SyncResult({
    required this.success,
    this.error,
    required this.pushedCount,
    required this.pulledCount,
    this.timestamp,
  });

  int get totalCount => pushedCount + pulledCount;
}

/// Exception thrown during sync operations
class SyncException implements Exception {
  final String message;
  SyncException(this.message);

  @override
  String toString() => 'SyncException: $message';
}

