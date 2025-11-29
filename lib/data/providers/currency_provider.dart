import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../drift/tables/settings_table.dart';
import '../providers/database_provider.dart';

/// Provider for default currency setting
final defaultCurrencyProvider = StreamProvider<String>((ref) async* {
  final database = ref.watch(databaseProvider);
  final settingsDao = database.settingsDao;
  
  yield* settingsDao.watchSetting(SettingKeys.defaultCurrency)
      .map((setting) => setting?.value ?? 'USD');
});

/// Provider for currency conversion rate
final currencyConversionRateProvider = StreamProvider<double>((ref) async* {
  final database = ref.watch(databaseProvider);
  final settingsDao = database.settingsDao;
  
  yield* settingsDao.watchSetting(SettingKeys.currencyConversionRate)
      .map((setting) {
    if (setting?.value == null) return 1.0;
    return double.tryParse(setting!.value) ?? 1.0;
  });
});

/// Provider that combines currency and conversion rate
class CurrencySettings {
  final String currencyCode;
  final double conversionRate;

  CurrencySettings({
    required this.currencyCode,
    required this.conversionRate,
  });
}

final currencySettingsProvider = Provider<AsyncValue<CurrencySettings>>((ref) {
  final currencyAsync = ref.watch(defaultCurrencyProvider);
  final rateAsync = ref.watch(currencyConversionRateProvider);

  return currencyAsync.when(
    data: (currency) => rateAsync.when(
      data: (rate) => AsyncValue.data(CurrencySettings(
        currencyCode: currency,
        conversionRate: rate,
      )),
      loading: () => AsyncValue.loading(),
      error: (err, stack) => AsyncValue.error(err, stack),
    ),
    loading: () => AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

