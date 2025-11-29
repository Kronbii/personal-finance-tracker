import 'package:drift/drift.dart';

/// Category type enum stored as text
enum CategoryType { expense, income }

/// Categories table - stores transaction categories
@DataClassName('CategoryEntity')
class Categories extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text()();

  /// Category name (e.g., "Food", "Salary")
  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// Category type: 'expense' or 'income'
  TextColumn get type => text().map(const CategoryTypeConverter())();

  /// Icon name for UI display
  TextColumn get iconName => text().withDefault(const Constant('circle'))();

  /// Color hex code (e.g., "#FF5733")
  TextColumn get colorHex => text().withDefault(const Constant('#0A84FF'))();

  /// Parent category ID for subcategories (nullable)
  TextColumn get parentId => text().nullable()();

  /// Whether this is a system default category
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// Display order for sorting
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Converter for CategoryType enum
class CategoryTypeConverter extends TypeConverter<CategoryType, String> {
  const CategoryTypeConverter();

  @override
  CategoryType fromSql(String fromDb) {
    return CategoryType.values.firstWhere(
      (e) => e.name == fromDb,
      orElse: () => CategoryType.expense,
    );
  }

  @override
  String toSql(CategoryType value) => value.name;
}

