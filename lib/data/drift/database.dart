import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'tables/tables.dart';
import 'daos/wallets_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/transactions_dao.dart';
import 'daos/subscriptions_dao.dart';
import 'daos/debts_dao.dart';
import 'daos/savings_goals_dao.dart';
import 'daos/savings_contributions_dao.dart';
import 'daos/settings_dao.dart';

part 'database.g.dart';

/// Main application database using Drift
@DriftDatabase(
  tables: [
    Wallets,
    Categories,
    Transactions,
    Subscriptions,
    Debts,
    SavingsGoals,
    SavingsContributions,
    Settings,
  ],
  daos: [
    WalletsDao,
    CategoriesDao,
    TransactionsDao,
    SubscriptionsDao,
    DebtsDao,
    SavingsGoalsDao,
    SavingsContributionsDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing with in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // Seed default categories
          await _seedDefaultCategories();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Handle future migrations here
        },
      );

  /// Seed default expense and income categories
  Future<void> _seedDefaultCategories() async {
    final defaultCategories = [
      // Expense categories
      CategoriesCompanion.insert(
        id: 'cat_food',
        name: 'Food & Dining',
        type: CategoryType.expense,
        iconName: const Value('utensils'),
        colorHex: const Value('#FF9F0A'),
        isDefault: const Value(true),
        sortOrder: const Value(0),
      ),
      CategoriesCompanion.insert(
        id: 'cat_transport',
        name: 'Transportation',
        type: CategoryType.expense,
        iconName: const Value('car'),
        colorHex: const Value('#0A84FF'),
        isDefault: const Value(true),
        sortOrder: const Value(1),
      ),
      CategoriesCompanion.insert(
        id: 'cat_shopping',
        name: 'Shopping',
        type: CategoryType.expense,
        iconName: const Value('shopping-bag'),
        colorHex: const Value('#FF375F'),
        isDefault: const Value(true),
        sortOrder: const Value(2),
      ),
      CategoriesCompanion.insert(
        id: 'cat_bills',
        name: 'Bills & Utilities',
        type: CategoryType.expense,
        iconName: const Value('file-text'),
        colorHex: const Value('#64D2FF'),
        isDefault: const Value(true),
        sortOrder: const Value(3),
      ),
      CategoriesCompanion.insert(
        id: 'cat_entertainment',
        name: 'Entertainment',
        type: CategoryType.expense,
        iconName: const Value('gamepad-2'),
        colorHex: const Value('#BF5AF2'),
        isDefault: const Value(true),
        sortOrder: const Value(4),
      ),
      CategoriesCompanion.insert(
        id: 'cat_health',
        name: 'Health & Medical',
        type: CategoryType.expense,
        iconName: const Value('heart-pulse'),
        colorHex: const Value('#FF453A'),
        isDefault: const Value(true),
        sortOrder: const Value(5),
      ),
      CategoriesCompanion.insert(
        id: 'cat_education',
        name: 'Education',
        type: CategoryType.expense,
        iconName: const Value('graduation-cap'),
        colorHex: const Value('#5E5CE6'),
        isDefault: const Value(true),
        sortOrder: const Value(6),
      ),
      CategoriesCompanion.insert(
        id: 'cat_travel',
        name: 'Travel',
        type: CategoryType.expense,
        iconName: const Value('plane'),
        colorHex: const Value('#30D158'),
        isDefault: const Value(true),
        sortOrder: const Value(7),
      ),
      CategoriesCompanion.insert(
        id: 'cat_other_expense',
        name: 'Other Expenses',
        type: CategoryType.expense,
        iconName: const Value('more-horizontal'),
        colorHex: const Value('#8E8E93'),
        isDefault: const Value(true),
        sortOrder: const Value(99),
      ),

      // Income categories
      CategoriesCompanion.insert(
        id: 'cat_salary',
        name: 'Salary',
        type: CategoryType.income,
        iconName: const Value('briefcase'),
        colorHex: const Value('#30D158'),
        isDefault: const Value(true),
        sortOrder: const Value(0),
      ),
      CategoriesCompanion.insert(
        id: 'cat_freelance',
        name: 'Freelance',
        type: CategoryType.income,
        iconName: const Value('laptop'),
        colorHex: const Value('#0A84FF'),
        isDefault: const Value(true),
        sortOrder: const Value(1),
      ),
      CategoriesCompanion.insert(
        id: 'cat_investment',
        name: 'Investment',
        type: CategoryType.income,
        iconName: const Value('trending-up'),
        colorHex: const Value('#FFD60A'),
        isDefault: const Value(true),
        sortOrder: const Value(2),
      ),
      CategoriesCompanion.insert(
        id: 'cat_gift_income',
        name: 'Gifts Received',
        type: CategoryType.income,
        iconName: const Value('gift'),
        colorHex: const Value('#FF375F'),
        isDefault: const Value(true),
        sortOrder: const Value(3),
      ),
      CategoriesCompanion.insert(
        id: 'cat_refund',
        name: 'Refunds',
        type: CategoryType.income,
        iconName: const Value('rotate-ccw'),
        colorHex: const Value('#64D2FF'),
        isDefault: const Value(true),
        sortOrder: const Value(4),
      ),
      CategoriesCompanion.insert(
        id: 'cat_other_income',
        name: 'Other Income',
        type: CategoryType.income,
        iconName: const Value('plus-circle'),
        colorHex: const Value('#8E8E93'),
        isDefault: const Value(true),
        sortOrder: const Value(99),
      ),
    ];

    await batch((batch) {
      batch.insertAll(categories, defaultCategories);
    });
  }

  /// Clears all data from the database and reseeds default categories
  Future<void> clearAllData() async {
    // Delete all data from tables in proper order (respecting foreign keys)
    await delete(transactions).go();
    await delete(savingsContributions).go();
    await delete(savingsGoals).go();
    await delete(debts).go();
    await delete(subscriptions).go();
    await delete(wallets).go();
    await delete(categories).go();
    await delete(settings).go();
    
    // Reseed default categories
    await _seedDefaultCategories();
  }
}

/// Opens a connection to the SQLite database
/// - Debug mode: uses test database inside the project repo
/// - Release mode: uses production database in ~/.local/share/ree/
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final String dbPath;
    
    if (kDebugMode) {
      // DEVELOPMENT: Use test database inside the repo
      // This keeps your production data safe during testing
      final repoDir = Directory.current.path;
      final testDbFolder = Directory(p.join(repoDir, '.test_data'));
      
      if (!await testDbFolder.exists()) {
        await testDbFolder.create(recursive: true);
      }
      
      dbPath = p.join(testDbFolder.path, 'ree_test.db');
      debugPrint('📦 DEV MODE: Using test database at $dbPath');
    } else {
      // PRODUCTION: Use XDG standard location ~/.local/share/ree/
      // This is the sacred production database
      final home = Platform.environment['HOME'] ?? '/home';
      final dbFolder = Directory(p.join(home, '.local', 'share', 'ree'));
      
      if (!await dbFolder.exists()) {
        await dbFolder.create(recursive: true);
      }
      
      dbPath = p.join(dbFolder.path, 'ree.db');
      
      // Migration: copy old database if it exists and new one doesn't
      final file = File(dbPath);
      if (!await file.exists()) {
        final oldDbPath = p.join(home, 'Documents', 'personal_finance.db');
        final oldFile = File(oldDbPath);
        if (await oldFile.exists()) {
          await oldFile.copy(dbPath);
        }
      }
    }
    
    return NativeDatabase.createInBackground(File(dbPath));
  });
}

