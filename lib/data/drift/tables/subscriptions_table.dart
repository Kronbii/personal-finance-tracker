import 'package:drift/drift.dart';

/// Billing frequency for subscriptions
enum BillingFrequency { daily, weekly, biweekly, monthly, quarterly, yearly }

/// Subscriptions table - stores recurring payments
@DataClassName('SubscriptionEntity')
class Subscriptions extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text()();

  /// Subscription name (e.g., "Netflix", "Spotify")
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Recurring amount
  RealColumn get amount => real()();

  /// Currency code
  TextColumn get currency => text().withLength(min: 3, max: 3).withDefault(const Constant('USD'))();

  /// Billing frequency
  TextColumn get frequency => text().map(const BillingFrequencyConverter())();

  /// Associated wallet ID (nullable - wallets are for balance tracking only)
  TextColumn get walletId => text().nullable()();

  /// Associated category ID
  TextColumn get categoryId => text()();

  /// Start date of subscription
  DateTimeColumn get startDate => dateTime()();

  /// Next billing date
  DateTimeColumn get nextBillingDate => dateTime()();

  /// End date (nullable for ongoing subscriptions)
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Optional description/notes
  TextColumn get note => text().nullable()();

  /// Icon name for UI
  TextColumn get iconName => text().withDefault(const Constant('repeat'))();

  /// Color hex for visual distinction
  TextColumn get colorHex => text().withDefault(const Constant('#BF5AF2'))();

  /// Whether subscription is active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Whether to auto-create transactions
  BoolColumn get autoCreateTransaction => boolean().withDefault(const Constant(false))();

  /// Reminder days before billing
  IntColumn get reminderDays => integer().withDefault(const Constant(3))();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Converter for BillingFrequency enum
class BillingFrequencyConverter extends TypeConverter<BillingFrequency, String> {
  const BillingFrequencyConverter();

  @override
  BillingFrequency fromSql(String fromDb) {
    return BillingFrequency.values.firstWhere(
      (e) => e.name == fromDb,
      orElse: () => BillingFrequency.monthly,
    );
  }

  @override
  String toSql(BillingFrequency value) => value.name;
}

