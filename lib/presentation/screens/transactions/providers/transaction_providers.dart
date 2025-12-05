import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/drift/database.dart';
import '../../../../data/drift/tables/transactions_table.dart';
import '../../../../data/providers/database_provider.dart';

/// Filter state for transactions list
enum TransactionFilter { all, expenses, income, transfers }

/// Provider for current filter
final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
  TransactionFilterNotifier.new,
);

class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => TransactionFilter.all;

  void setFilter(TransactionFilter filter) => state = filter;
}

// Wallet filtering removed - wallets are for balance tracking only

/// Provider for selected category filter (null = all categories)
final selectedCategoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, String?>(
  CategoryFilterNotifier.new,
);

class CategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setCategory(String? categoryId) => state = categoryId;
}

/// Provider for search query
final transactionSearchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

/// Provider for selected month (null = show all transactions)
final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateTime?>(
  SelectedMonthNotifier.new,
);

class SelectedMonthNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => DateTime.now(); // Default to current month

  void setMonth(DateTime? month) => state = month;
  
  void setCurrentMonth() => state = DateTime.now();
  
  void setPreviousMonth() {
    if (state != null) {
      state = DateTime(state!.year, state!.month - 1, 1);
    }
  }
  
  void setNextMonth() {
    if (state != null) {
      state = DateTime(state!.year, state!.month + 1, 1);
    }
  }
}

/// Provider for selected date range (null = no date filter)
final transactionDateRangeProvider =
    NotifierProvider<DateRangeNotifier, TransactionDateRange?>(
  DateRangeNotifier.new,
);

class DateRangeNotifier extends Notifier<TransactionDateRange?> {
  @override
  TransactionDateRange? build() => null;

  void setRange(TransactionDateRange? range) => state = range;
}

/// Date range class for transaction filtering
class TransactionDateRange {
  final DateTime start;
  final DateTime end;

  TransactionDateRange({required this.start, required this.end});
}

/// Provider for all transactions
final allTransactionsProvider = StreamProvider<List<TransactionEntity>>((ref) {
  return ref.watch(transactionsDaoProvider).watchAllTransactions();
});

/// Provider for filtered transactions
final filteredTransactionsProvider =
    Provider<AsyncValue<List<TransactionEntity>>>((ref) {
  final transactionsAsync = ref.watch(allTransactionsProvider);
  final filter = ref.watch(transactionFilterProvider);
  final categoryFilter = ref.watch(selectedCategoryFilterProvider);
  final searchQuery = ref.watch(transactionSearchQueryProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);

  return transactionsAsync.whenData((transactions) {
    var filtered = transactions;

    // Apply month filter
    if (selectedMonth != null) {
      final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
      final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);
      filtered = filtered
          .where((t) =>
              t.date.isAfter(start.subtract(const Duration(days: 1))) &&
              t.date.isBefore(end.add(const Duration(days: 1))))
          .toList();
    }

    // Apply type filter
    if (filter != TransactionFilter.all) {
      filtered = filtered.where((t) {
        switch (filter) {
          case TransactionFilter.expenses:
            return t.type == TransactionType.expense;
          case TransactionFilter.income:
            return t.type == TransactionType.income;
          case TransactionFilter.transfers:
            return t.type == TransactionType.transfer;
          default:
            return true;
        }
      }).toList();
    }

    // Apply category filter
    if (categoryFilter != null) {
      filtered =
          filtered.where((t) => t.categoryId == categoryFilter).toList();
    }


    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered
          .where((t) => t.note?.toLowerCase().contains(query) ?? false)
          .toList();
    }

    return filtered;
  });
});

/// Provider for transactions grouped by date
final groupedTransactionsProvider =
    Provider<AsyncValue<Map<DateTime, List<TransactionEntity>>>>((ref) {
  final transactionsAsync = ref.watch(filteredTransactionsProvider);

  return transactionsAsync.whenData((transactions) {
    final grouped = <DateTime, List<TransactionEntity>>{};

    for (final transaction in transactions) {
      final dateKey = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      grouped.putIfAbsent(dateKey, () => []).add(transaction);
    }

    // Sort by date descending
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return {for (final key in sortedKeys) key: grouped[key]!};
  });
});

/// Provider for transaction count by type
final transactionCountsProvider =
    Provider<AsyncValue<Map<TransactionFilter, int>>>((ref) {
  final transactionsAsync = ref.watch(allTransactionsProvider);

  return transactionsAsync.whenData((transactions) {
    return {
      TransactionFilter.all: transactions.length,
      TransactionFilter.expenses:
          transactions.where((t) => t.type == TransactionType.expense).length,
      TransactionFilter.income:
          transactions.where((t) => t.type == TransactionType.income).length,
      TransactionFilter.transfers:
          transactions.where((t) => t.type == TransactionType.transfer).length,
    };
  });
});

/// Provider for getting a category by ID
final categoryByIdProvider =
    FutureProvider.family<CategoryEntity?, String>((ref, id) async {
  return ref.watch(categoriesDaoProvider).getCategoryById(id);
});

/// Provider for getting a wallet by ID
final walletByIdProvider =
    FutureProvider.family<WalletEntity?, String>((ref, id) async {
  return ref.watch(walletsDaoProvider).getWalletById(id);
});
