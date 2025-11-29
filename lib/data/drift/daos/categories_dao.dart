import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/categories_table.dart';

part 'categories_dao.g.dart';

/// Data Access Object for Categories table
@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  // ============================================
  // CRUD Operations
  // ============================================

  /// Get all categories
  Future<List<CategoryEntity>> getAllCategories() {
    return (select(categories)
          ..orderBy([
            (c) => OrderingTerm.asc(c.type),
            (c) => OrderingTerm.asc(c.sortOrder),
          ]))
        .get();
  }

  /// Watch all categories
  Stream<List<CategoryEntity>> watchAllCategories() {
    return (select(categories)
          ..orderBy([
            (c) => OrderingTerm.asc(c.type),
            (c) => OrderingTerm.asc(c.sortOrder),
          ]))
        .watch();
  }

  /// Get categories by type
  Future<List<CategoryEntity>> getCategoriesByType(CategoryType type) {
    return (select(categories)
          ..where((c) => c.type.equals(type.name))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  /// Watch categories by type
  Stream<List<CategoryEntity>> watchCategoriesByType(CategoryType type) {
    return (select(categories)
          ..where((c) => c.type.equals(type.name))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  /// Get expense categories
  Future<List<CategoryEntity>> getExpenseCategories() =>
      getCategoriesByType(CategoryType.expense);

  /// Get income categories
  Future<List<CategoryEntity>> getIncomeCategories() =>
      getCategoriesByType(CategoryType.income);

  /// Watch expense categories
  Stream<List<CategoryEntity>> watchExpenseCategories() =>
      watchCategoriesByType(CategoryType.expense);

  /// Watch income categories
  Stream<List<CategoryEntity>> watchIncomeCategories() =>
      watchCategoriesByType(CategoryType.income);

  /// Get category by ID
  Future<CategoryEntity?> getCategoryById(String id) {
    return (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// Watch category by ID
  Stream<CategoryEntity?> watchCategoryById(String id) {
    return (select(categories)..where((c) => c.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Insert new category
  Future<void> insertCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  /// Update category by ID
  Future<int> updateCategoryById(String id, CategoriesCompanion category) {
    return (update(categories)..where((c) => c.id.equals(id))).write(
      category.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  /// Delete category
  Future<int> deleteCategory(String id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  // ============================================
  // Query Helpers
  // ============================================

  /// Check if category name exists for a type
  Future<bool> categoryNameExists(
    String name,
    CategoryType type, {
    String? excludeId,
  }) async {
    final query = select(categories)
      ..where(
        (c) =>
            c.name.lower().equals(name.toLowerCase()) &
            c.type.equals(type.name),
      );
    if (excludeId != null) {
      query.where((c) => c.id.equals(excludeId).not());
    }
    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Get parent categories only
  Future<List<CategoryEntity>> getParentCategories() {
    return (select(categories)
          ..where((c) => c.parentId.isNull())
          ..orderBy([
            (c) => OrderingTerm.asc(c.type),
            (c) => OrderingTerm.asc(c.sortOrder),
          ]))
        .get();
  }

  /// Get subcategories of a parent
  Future<List<CategoryEntity>> getSubcategories(String parentId) {
    return (select(categories)
          ..where((c) => c.parentId.equals(parentId))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  /// Reorder categories
  Future<void> reorderCategories(List<String> orderedIds) async {
    await batch((batch) {
      for (int i = 0; i < orderedIds.length; i++) {
        batch.update(
          categories,
          CategoriesCompanion(
            sortOrder: Value(i),
            updatedAt: Value(DateTime.now()),
          ),
          where: (c) => c.id.equals(orderedIds[i]),
        );
      }
    });
  }
}

