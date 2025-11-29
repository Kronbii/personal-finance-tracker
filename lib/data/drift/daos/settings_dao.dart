import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/settings_table.dart';

part 'settings_dao.g.dart';

/// Data Access Object for Settings table
@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  // ============================================
  // CRUD Operations
  // ============================================

  /// Get all settings
  Future<List<SettingEntity>> getAllSettings() {
    return select(settings).get();
  }

  /// Watch all settings
  Stream<List<SettingEntity>> watchAllSettings() {
    return select(settings).watch();
  }

  /// Get setting by key
  Future<SettingEntity?> getSetting(String key) {
    return (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull();
  }

  /// Watch setting by key
  Stream<SettingEntity?> watchSetting(String key) {
    return (select(settings)..where((s) => s.key.equals(key)))
        .watchSingleOrNull();
  }

  /// Get setting value by key
  Future<String?> getSettingValue(String key) async {
    final setting = await getSetting(key);
    return setting?.value;
  }

  /// Get settings by category
  Future<List<SettingEntity>> getSettingsByCategory(String category) {
    return (select(settings)..where((s) => s.category.equals(category))).get();
  }

  /// Set setting value (insert or update)
  Future<void> setSetting(String key, String value, {String? category}) async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(
        key: key,
        value: value,
        category: Value(category ?? 'general'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete setting
  Future<int> deleteSetting(String key) {
    return (delete(settings)..where((s) => s.key.equals(key))).go();
  }

  // ============================================
  // Typed Getters/Setters
  // ============================================

  /// Get string setting with default
  Future<String> getString(String key, {String defaultValue = ''}) async {
    final value = await getSettingValue(key);
    return value ?? defaultValue;
  }

  /// Get int setting with default
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final value = await getSettingValue(key);
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  /// Get double setting with default
  Future<double> getDouble(String key, {double defaultValue = 0.0}) async {
    final value = await getSettingValue(key);
    if (value == null) return defaultValue;
    return double.tryParse(value) ?? defaultValue;
  }

  /// Get bool setting with default
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value = await getSettingValue(key);
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true';
  }

  /// Set string setting
  Future<void> setString(String key, String value, {String? category}) {
    return setSetting(key, value, category: category);
  }

  /// Set int setting
  Future<void> setInt(String key, int value, {String? category}) {
    return setSetting(key, value.toString(), category: category);
  }

  /// Set double setting
  Future<void> setDouble(String key, double value, {String? category}) {
    return setSetting(key, value.toString(), category: category);
  }

  /// Set bool setting
  Future<void> setBool(String key, bool value, {String? category}) {
    return setSetting(key, value.toString(), category: category);
  }

  // ============================================
  // Convenience Methods for Common Settings
  // ============================================

  /// Get theme mode
  Future<String> getThemeMode() => getString(SettingKeys.themeMode, defaultValue: 'dark');

  /// Set theme mode
  Future<void> setThemeMode(String mode) =>
      setString(SettingKeys.themeMode, mode, category: 'display');

  /// Get default currency
  Future<String> getDefaultCurrency() =>
      getString(SettingKeys.defaultCurrency, defaultValue: 'USD');

  /// Set default currency
  Future<void> setDefaultCurrency(String currency) =>
      setString(SettingKeys.defaultCurrency, currency, category: 'general');

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    final value = await getSettingValue(SettingKeys.lastSyncTimestamp);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  /// Set last sync timestamp
  Future<void> setLastSyncTimestamp(DateTime timestamp) =>
      setString(SettingKeys.lastSyncTimestamp, timestamp.toIso8601String(),
          category: 'sync');

  /// Get currency conversion rate
  Future<double> getCurrencyConversionRate() =>
      getDouble(SettingKeys.currencyConversionRate, defaultValue: 1.0);

  /// Set currency conversion rate
  Future<void> setCurrencyConversionRate(double rate) =>
      setDouble(SettingKeys.currencyConversionRate, rate, category: 'general');
}

