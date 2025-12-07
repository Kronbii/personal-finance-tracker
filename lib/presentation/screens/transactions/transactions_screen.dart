import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../app/utils/responsive.dart';
import '../../../data/drift/database.dart';
import '../../../data/drift/tables/transactions_table.dart';
import '../../widgets/transaction_item.dart';
import '../dashboard/providers/dashboard_providers.dart';
import 'providers/transaction_providers.dart';
import 'widgets/add_transaction_modal.dart';
import 'widgets/transaction_details_modal.dart';

/// Transactions screen - List and manage all transactions
/// Features: Day-grouped list, filters, search, transaction modals
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final selectedFilter = ref.watch(transactionFilterProvider);
    final transactionCounts = ref.watch(transactionCountsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionModal(),
        backgroundColor: AppColors.accentBlue,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(
          'Add Transaction',
          style: AppTypography.labelMedium(Colors.white),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(isDark),
          ),

          // Month selector
          SliverToBoxAdapter(
            child: Padding(
              padding: Responsive.horizontalPaddingInsets(context),
              child: _buildMonthSelector(isDark),
            ),
          ),

          // Filters and search
          SliverToBoxAdapter(
            child: Padding(
              padding: Responsive.horizontalPaddingInsets(context),
              child: Column(
                children: [
                  _buildSearchBar(isDark),
                  const SizedBox(height: 16),
                  _buildFilterChips(isDark, selectedFilter, transactionCounts),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Transaction list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            sliver: _buildTransactionList(isDark),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transactions',
            style: AppTypography.displaySmall(
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 8),
          Text(
            'View and manage your financial transactions',
            style: AppTypography.bodyMedium(
              isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(bool isDark) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final monthNotifier = ref.read(selectedMonthProvider.notifier);

    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.calendar,
            size: 20,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              selectedMonth != null
                  ? '${monthNames[selectedMonth.month - 1]} ${selectedMonth.year}'
                  : 'All Months',
              style: AppTypography.titleMedium(
                isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              LucideIcons.chevronLeft,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            onPressed: selectedMonth != null
                ? () => monthNotifier.setPreviousMonth()
                : null,
            tooltip: 'Previous month',
          ),
          IconButton(
            icon: Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            onPressed: selectedMonth != null
                ? () => monthNotifier.setNextMonth()
                : null,
            tooltip: 'Next month',
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => monthNotifier.setCurrentMonth(),
            child: Text(
              'Today',
              style: AppTypography.labelMedium(AppColors.accentBlue),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              LucideIcons.x,
              size: 18,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            onPressed: () => monthNotifier.setMonth(null),
            tooltip: 'Show all months',
          ),
        ],
      ),
    ).animate(delay: 150.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(transactionSearchQueryProvider.notifier).setQuery(value);
              },
              style: AppTypography.bodyMedium(
                isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: AppTypography.bodyMedium(
                  isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                ref.read(transactionSearchQueryProvider.notifier).setQuery('');
              },
              icon: Icon(
                LucideIcons.x,
                size: 18,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          Container(
            height: 24,
            width: 1,
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
          IconButton(
            onPressed: _showFilterOptions,
            tooltip: 'More filters',
            icon: Icon(
              LucideIcons.slidersHorizontal,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildFilterChips(
    bool isDark,
    TransactionFilter selectedFilter,
    AsyncValue<Map<TransactionFilter, int>> counts,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TransactionFilter.values.map((filter) {
          final isSelected = selectedFilter == filter;
          final count = counts.when(
            data: (c) => c[filter] ?? 0,
            loading: () => 0,
            error: (_, __) => 0,
          );

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getFilterLabel(filter)),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : (isDark
                                ? AppColors.darkSurfaceHighlight
                                : AppColors.lightDivider),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        count.toString(),
                        style: AppTypography.labelSmall(
                          isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              onSelected: (selected) {
                ref.read(transactionFilterProvider.notifier).setFilter(filter);
              },
              selectedColor: _getFilterColor(filter),
              showCheckmark: false,
              labelStyle: AppTypography.labelMedium(
                isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildTransactionList(bool isDark) {
    final groupedTransactions = ref.watch(groupedTransactionsProvider);
    final categoryMap = ref.watch(categoryMapProvider);

    return groupedTransactions.when(
      data: (grouped) {
        if (grouped.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(isDark),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entries = grouped.entries.toList();
              final entry = entries[index];
              final date = entry.key;
              final transactions = entry.value;

              // Calculate day total
              double dayTotal = 0;
              for (final txn in transactions) {
                if (txn.type == TransactionType.income) {
                  dayTotal += txn.amount;
                } else if (txn.type == TransactionType.expense) {
                  dayTotal -= txn.amount;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TransactionDayHeader(
                    date: date,
                    totalAmount: dayTotal,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  ...transactions.asMap().entries.map((txnEntry) {
                    final txnIndex = txnEntry.key;
                    final transaction = txnEntry.value;

                    return categoryMap.when(
                      data: (categories) {
                        final category = categories[transaction.categoryId];

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: txnIndex < transactions.length - 1
                                ? 8
                                : 24,
                          ),
                          child: TransactionItem(
                            categoryName: category?.name ?? 'Unknown',
                            categoryIcon: category?.iconName ?? 'circle',
                            categoryColor:
                                category?.colorHex ?? '#0A84FF',
                            walletName: null,
                            toWalletName: null,
                            amount: transaction.amount,
                            type: transaction.type,
                            date: transaction.date,
                            note: transaction.note,
                            isDark: isDark,
                            animationDelay: (index * 50) + (txnIndex * 30),
                            onTap: () =>
                                _showTransactionDetails(transaction),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  }),
                ],
              );
            },
            childCount: grouped.length,
          ),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.accentBlue),
            ),
          ),
        ),
      ),
      error: (error, _) => SliverToBoxAdapter(
        child: _buildErrorState(isDark, error.toString()),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final filter = ref.watch(transactionFilterProvider);
    final searchQuery = ref.watch(transactionSearchQueryProvider);

    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isNotEmpty
                ? LucideIcons.searchX
                : LucideIcons.receipt,
            size: 64,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty
                ? 'No transactions found'
                : filter == TransactionFilter.all
                    ? 'No transactions yet'
                    : 'No ${_getFilterLabel(filter).toLowerCase()}',
            style: AppTypography.titleMedium(
              isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Add your first transaction to get started',
            style: AppTypography.bodySmall(
              isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          if (searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddTransactionModal,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add Transaction'),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildErrorState(bool isDark, String error) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertTriangle,
            size: 64,
            color: AppColors.accentRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: AppTypography.titleMedium(AppColors.accentRed),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTypography.bodySmall(
              isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    // TODO: Implement advanced filter options modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Advanced filters coming soon'),
      ),
    );
  }

  Future<void> _showAddTransactionModal() async {
    final result = await AddTransactionModal.show(context);
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.check, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Text(
                'Transaction added successfully',
                style: AppTypography.bodyMedium(Colors.white),
              ),
            ],
          ),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showTransactionDetails(TransactionEntity transaction) {
    TransactionDetailsModal.show(context, transaction);
  }

  String _getFilterLabel(TransactionFilter filter) {
    switch (filter) {
      case TransactionFilter.all:
        return 'All';
      case TransactionFilter.expenses:
        return 'Expenses';
      case TransactionFilter.income:
        return 'Income';
      case TransactionFilter.transfers:
        return 'Transfers';
    }
  }

  Color _getFilterColor(TransactionFilter filter) {
    switch (filter) {
      case TransactionFilter.all:
        return AppColors.accentBlue;
      case TransactionFilter.expenses:
        return AppColors.expense;
      case TransactionFilter.income:
        return AppColors.income;
      case TransactionFilter.transfers:
        return AppColors.transfer;
    }
  }
}
