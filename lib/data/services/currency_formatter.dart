/// Currency information model
class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  final int decimalPlaces;

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    this.decimalPlaces = 2,
  });
}

/// Currency formatter utility
class CurrencyFormatter {
  /// Common currencies with their symbols and formatting
  static const Map<String, CurrencyInfo> currencies = {
    'USD': CurrencyInfo(code: 'USD', name: 'US Dollar', symbol: '\$'),
    'EUR': CurrencyInfo(code: 'EUR', name: 'Euro', symbol: '€'),
    'GBP': CurrencyInfo(code: 'GBP', name: 'British Pound', symbol: '£'),
    'JPY': CurrencyInfo(code: 'JPY', name: 'Japanese Yen', symbol: '¥', decimalPlaces: 0),
    'CNY': CurrencyInfo(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
    'KRW': CurrencyInfo(code: 'KRW', name: 'South Korean Won', symbol: '₩', decimalPlaces: 0),
    'INR': CurrencyInfo(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
    'BRL': CurrencyInfo(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$'),
    'CAD': CurrencyInfo(code: 'CAD', name: 'Canadian Dollar', symbol: 'CA\$'),
    'AUD': CurrencyInfo(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$'),
    'CHF': CurrencyInfo(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF'),
    'MXN': CurrencyInfo(code: 'MXN', name: 'Mexican Peso', symbol: '\$'),
    'SGD': CurrencyInfo(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$'),
    'HKD': CurrencyInfo(code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK\$'),
    'NZD': CurrencyInfo(code: 'NZD', name: 'New Zealand Dollar', symbol: 'NZ\$'),
    'SEK': CurrencyInfo(code: 'SEK', name: 'Swedish Krona', symbol: 'kr'),
    'NOK': CurrencyInfo(code: 'NOK', name: 'Norwegian Krone', symbol: 'kr'),
    'DKK': CurrencyInfo(code: 'DKK', name: 'Danish Krone', symbol: 'kr'),
    'PLN': CurrencyInfo(code: 'PLN', name: 'Polish Zloty', symbol: 'zł'),
    'RUB': CurrencyInfo(code: 'RUB', name: 'Russian Ruble', symbol: '₽'),
    'TRY': CurrencyInfo(code: 'TRY', name: 'Turkish Lira', symbol: '₺'),
    'ZAR': CurrencyInfo(code: 'ZAR', name: 'South African Rand', symbol: 'R'),
    'AED': CurrencyInfo(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ'),
    'SAR': CurrencyInfo(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼'),
  };

  /// Get currency info by code
  static CurrencyInfo? getCurrency(String code) {
    return currencies[code.toUpperCase()];
  }

  /// Get currency symbol by code
  static String getSymbol(String code) {
    return getCurrency(code)?.symbol ?? '\$';
  }

  /// Format amount with currency
  /// [amount] - The amount to format
  /// [currencyCode] - Currency code (default: USD)
  /// [showSymbol] - Whether to show currency symbol (default: true)
  /// [useGrouping] - Whether to use thousand separators (default: true)
  /// [conversionRate] - Optional conversion rate to apply
  static String format(
    double amount, {
    String currencyCode = 'USD',
    bool showSymbol = true,
    bool useGrouping = true,
    double? conversionRate,
  }) {
    // Apply conversion rate if provided
    double finalAmount = amount;
    if (conversionRate != null && conversionRate != 1.0) {
      finalAmount = amount * conversionRate;
    }

    final currency = getCurrency(currencyCode) ?? currencies['USD']!;
    final decimalPlaces = currency.decimalPlaces;
    
    // Format number
    String formatted;
    if (decimalPlaces == 0) {
      formatted = finalAmount.abs().round().toString();
    } else {
      formatted = finalAmount.abs().toStringAsFixed(decimalPlaces);
    }

    // Add thousand separators
    if (useGrouping && decimalPlaces > 0) {
      final parts = formatted.split('.');
      final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      formatted = '$intPart.${parts[1]}';
    } else if (useGrouping) {
      formatted = formatted.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }

    // Add symbol
    if (showSymbol) {
      return '${currency.symbol}$formatted';
    }
    return formatted;
  }

  /// Format compact amount (e.g., $1.2K, $3.5M)
  static String formatCompact(
    double amount, {
    String currencyCode = 'USD',
    bool showSymbol = true,
    double? conversionRate,
  }) {
    // Apply conversion rate if provided
    double finalAmount = amount;
    if (conversionRate != null && conversionRate != 1.0) {
      finalAmount = amount * conversionRate;
    }

    final currency = getCurrency(currencyCode) ?? currencies['USD']!;
    final symbol = showSymbol ? currency.symbol : '';

    if (finalAmount.abs() >= 1000000) {
      return '$symbol${(finalAmount / 1000000).toStringAsFixed(1)}M';
    } else if (finalAmount.abs() >= 1000) {
      return '$symbol${(finalAmount / 1000).toStringAsFixed(0)}K';
    }
    return '$symbol${finalAmount.abs().toStringAsFixed(0)}';
  }

  /// Get list of all available currencies
  static List<CurrencyInfo> getAllCurrencies() {
    return currencies.values.toList()
      ..sort((a, b) => a.code.compareTo(b.code));
  }

  /// Get list of common currencies (most used)
  static List<CurrencyInfo> getCommonCurrencies() {
    const commonCodes = [
      'USD', 'EUR', 'GBP', 'JPY', 'CNY', 'INR', 'CAD', 'AUD', 'CHF', 'MXN',
    ];
    return commonCodes
        .map((code) => currencies[code])
        .whereType<CurrencyInfo>()
        .toList();
  }
}

