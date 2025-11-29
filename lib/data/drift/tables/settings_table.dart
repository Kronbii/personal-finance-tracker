import 'package:drift/drift.dart';

/// Settings table - stores app configuration as key-value pairs
@DataClassName('SettingEntity')
class Settings extends Table {
  /// Setting key (unique identifier)
  TextColumn get key => text()();

  /// Setting value (stored as JSON string for complex values)
  TextColumn get value => text()();

  /// Setting category for grouping
  TextColumn get category => text().withDefault(const Constant('general'))();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

/// Predefined setting keys
class SettingKeys {
  SettingKeys._();

  // General
  static const String themeMode = 'theme_mode';
  static const String defaultCurrency = 'default_currency';
  static const String currencyConversionRate = 'currency_conversion_rate';
  static const String dateFormat = 'date_format';
  static const String timeFormat = 'time_format';
  static const String startDayOfWeek = 'start_day_of_week';

  // Sync
  static const String lastSyncTimestamp = 'last_sync_timestamp';
  static const String supabaseUrl = 'supabase_url';
  static const String supabaseAnonKey = 'supabase_anon_key';
  static const String syncEnabled = 'sync_enabled';

  // Display
  static const String showCents = 'show_cents';
  static const String compactNumbers = 'compact_numbers';
  static const String defaultWalletId = 'default_wallet_id';
  static const String defaultCategoryId = 'default_category_id';

  // Privacy
  static const String hideAmounts = 'hide_amounts';
  static const String requireAuth = 'require_auth';
}

