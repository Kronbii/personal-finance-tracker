import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../data/drift/database.dart';
import '../../../data/drift/tables/transactions_table.dart';
import '../../../data/providers/database_provider.dart';
import '../../widgets/apple_dropdown.dart';
import '../dashboard/providers/dashboard_providers.dart';

/// Bulk Entry screen - Multi-row transaction entry
/// Features: Grid form, add/remove rows, batch save
class BulkEntryScreen extends ConsumerStatefulWidget {
  const BulkEntryScreen({super.key});

  @override
  ConsumerState<BulkEntryScreen> createState() => _BulkEntryScreenState();
}

class _BulkEntryScreenState extends ConsumerState<BulkEntryScreen> {
  final List<BulkEntryRow> _rows = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Start with 3 empty rows
    for (int i = 0; i < 3; i++) {
      _addRow();
    }
  }

  void _addRow() {
    setState(() {
      _rows.add(BulkEntryRow(
        id: const Uuid().v4(),
        dateController: TextEditingController(
          text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        ),
        amountController: TextEditingController(),
        noteController: TextEditingController(),
      ));
    });
  }

  void _removeRow(int index) {
    if (_rows.length > 1) {
      setState(() {
        final row = _rows.removeAt(index);
        row.dispose();
      });
    }
  }

  void _clearAll() {
    setState(() {
      for (final row in _rows) {
        row.amountController.clear();
        row.noteController.clear();
        row.selectedWalletId = null;
        row.selectedCategoryId = null;
        row.selectedType = TransactionType.expense;
        row.dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final wallets = ref.watch(walletsProvider);
    final expenseCategories = ref.watch(expenseCategoriesProvider);
    final incomeCategories = ref.watch(incomeCategoriesProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          // Header
          _buildHeader(isDark),

          // Grid
          Expanded(
            child: wallets.when(
              data: (walletList) => expenseCategories.when(
                data: (expenseCats) => incomeCategories.when(
                  data: (incomeCats) => _buildGrid(
                    isDark,
                    walletList,
                    expenseCats,
                    incomeCats,
                  ),
                  loading: () => _buildLoading(),
                  error: (_, __) => _buildError(isDark, 'Error loading categories'),
                ),
                loading: () => _buildLoading(),
                error: (_, __) => _buildError(isDark, 'Error loading categories'),
              ),
              loading: () => _buildLoading(),
              error: (_, __) => _buildError(isDark, 'Error loading wallets'),
            ),
          ),

          // Actions
          _buildActions(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bulk Entry',
                  style: AppTypography.displaySmall(
                    isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
                const SizedBox(height: 8),
                Text(
                  'Add multiple transactions at once',
                  style: AppTypography.bodyMedium(
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: _clearAll,
                icon: const Icon(LucideIcons.eraser, size: 18),
                label: const Text('Clear All'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _addRow,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Add Row'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    bool isDark,
    List<WalletEntity> wallets,
    List<CategoryEntity> expenseCategories,
    List<CategoryEntity> incomeCategories,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header row
          _buildHeaderRow(isDark),

          const Divider(height: 1),

          // Data rows
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _buildDataRow(
                  isDark,
                  index,
                  wallets,
                  expenseCategories,
                  incomeCategories,
                );
              },
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildHeaderRow(bool isDark) {
    final headerStyle = AppTypography.labelMedium(
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceHighlight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          SizedBox(width: 48, child: Text('#', style: headerStyle)),
          Expanded(flex: 2, child: Text('Date', style: headerStyle)),
          Expanded(flex: 2, child: Text('Type', style: headerStyle)),
          Expanded(flex: 2, child: Text('Amount', style: headerStyle)),
          Expanded(flex: 3, child: Text('Wallet', style: headerStyle)),
          Expanded(flex: 3, child: Text('Category', style: headerStyle)),
          Expanded(flex: 3, child: Text('Note', style: headerStyle)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildDataRow(
    bool isDark,
    int index,
    List<WalletEntity> wallets,
    List<CategoryEntity> expenseCategories,
    List<CategoryEntity> incomeCategories,
  ) {
    final row = _rows[index];
    final categories = row.selectedType == TransactionType.expense
        ? expenseCategories
        : incomeCategories;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Row number
          SizedBox(
            width: 48,
            child: Text(
              '${index + 1}',
              style: AppTypography.bodySmall(
                isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),

          // Date
          Expanded(
            flex: 2,
            child: _buildDateField(isDark, row),
          ),

          // Type selector
          Expanded(
            flex: 2,
            child: _buildTypeSelector(isDark, row),
          ),

          // Amount
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: row.amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                style: AppTypography.moneySmall(
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  hintText: '0.00',
                  hintStyle: AppTypography.moneySmall(
                    isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ),
            ),
          ),

          // Wallet dropdown
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AppleDropdown<String?>(
                value: row.selectedWalletId,
                isDark: isDark,
                hint: 'Wallet',
                items: [
                  const AppleDropdownItem<String?>(value: null, label: 'Select wallet'),
                  ...wallets.map((w) => AppleDropdownItem<String?>(
                    value: w.id,
                    label: w.name,
                  )),
                ],
                onChanged: (value) => setState(() => row.selectedWalletId = value),
              ),
            ),
          ),

          // Category dropdown
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AppleDropdown<String?>(
                value: row.selectedCategoryId,
                isDark: isDark,
                hint: 'Category',
                items: [
                  const AppleDropdownItem<String?>(value: null, label: 'Select category'),
                  ...categories.map((c) => AppleDropdownItem<String?>(
                    value: c.id,
                    label: c.name,
                  )),
                ],
                onChanged: (value) => setState(() => row.selectedCategoryId = value),
              ),
            ),
          ),

          // Note
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: row.noteController,
                style: AppTypography.bodySmall(
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  hintText: 'Note (optional)',
                  hintStyle: AppTypography.bodySmall(
                    isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ),
            ),
          ),

          // Delete button
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: _rows.length > 1 ? () => _removeRow(index) : null,
              icon: Icon(
                LucideIcons.trash2,
                size: 18,
                color: _rows.length > 1
                    ? AppColors.accentRed
                    : (isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(bool isDark, BulkEntryRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => _selectDate(row),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightSurfaceHighlight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.calendar,
                size: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  row.dateController.text,
                  style: AppTypography.bodySmall(
                    isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark, BulkEntryRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceElevated
              : AppColors.lightSurfaceHighlight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  row.selectedType = TransactionType.expense;
                  row.selectedCategoryId = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: row.selectedType == TransactionType.expense
                        ? AppColors.expense
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Exp',
                      style: AppTypography.labelSmall(
                        row.selectedType == TransactionType.expense
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  row.selectedType = TransactionType.income;
                  row.selectedCategoryId = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: row.selectedType == TransactionType.income
                        ? AppColors.income
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Inc',
                      style: AppTypography.labelSmall(
                        row.selectedType == TransactionType.income
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(bool isDark) {
    final validRows = _rows.where((row) {
      final amount = double.tryParse(row.amountController.text);
      return amount != null &&
          amount > 0 &&
          row.selectedWalletId != null &&
          row.selectedCategoryId != null;
    }).length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$validRows of ${_rows.length} rows ready to save',
            style: AppTypography.bodyMedium(
              isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed:
                validRows > 0 && !_isSaving ? () => _saveAll(validRows) : null,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(LucideIcons.save, size: 18),
            label: Text(_isSaving ? 'Saving...' : 'Save All ($validRows)'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: AppColors.accentRed),
          const SizedBox(height: 16),
          Text(message, style: AppTypography.bodyMedium(AppColors.accentRed)),
        ],
      ),
    );
  }

  Future<void> _selectDate(BulkEntryRow row) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(row.dateController.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        row.dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveAll(int count) async {
    setState(() => _isSaving = true);

    try {
      final transactionsDao = ref.read(transactionsDaoProvider);
      final transactions = <TransactionsCompanion>[];

      for (final row in _rows) {
        final amount = double.tryParse(row.amountController.text);
        if (amount != null &&
            amount > 0 &&
            row.selectedWalletId != null &&
            row.selectedCategoryId != null) {
          final date = DateTime.tryParse(row.dateController.text) ?? DateTime.now();

          transactions.add(TransactionsCompanion.insert(
            id: const Uuid().v4(),
            amount: amount,
            type: row.selectedType,
            walletId: row.selectedWalletId!,
            categoryId: Value(row.selectedCategoryId),
            date: date,
            note: Value(row.noteController.text.isEmpty
                ? null
                : row.noteController.text),
          ));
        }
      }

      await transactionsDao.insertTransactions(transactions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.check, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Text(
                  '$count transactions saved successfully',
                  style: AppTypography.bodyMedium(Colors.white),
                ),
              ],
            ),
            backgroundColor: AppColors.income,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        _clearAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transactions: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// Data class for a bulk entry row
class BulkEntryRow {
  final String id;
  final TextEditingController dateController;
  final TextEditingController amountController;
  final TextEditingController noteController;
  String? selectedWalletId;
  String? selectedCategoryId;
  TransactionType selectedType;

  BulkEntryRow({
    required this.id,
    required this.dateController,
    required this.amountController,
    required this.noteController,
    this.selectedWalletId,
    this.selectedCategoryId,
    this.selectedType = TransactionType.expense,
  });

  void dispose() {
    dateController.dispose();
    amountController.dispose();
    noteController.dispose();
  }
}
