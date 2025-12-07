import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../../../data/drift/database.dart';
import '../../../../data/drift/tables/transactions_table.dart';
import '../../../../data/providers/database_provider.dart';
import '../../../widgets/apple_dropdown.dart';
import '../../dashboard/providers/dashboard_providers.dart';

/// Modal dialog for adding/editing transactions
class AddTransactionModal extends ConsumerStatefulWidget {
  final TransactionEntity? existingTransaction;

  const AddTransactionModal({
    super.key,
    this.existingTransaction,
  });

  @override
  ConsumerState<AddTransactionModal> createState() =>
      _AddTransactionModalState();

  /// Show the modal as a dialog
  static Future<bool?> show(
    BuildContext context, {
    TransactionEntity? existingTransaction,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddTransactionModal(
        existingTransaction: existingTransaction,
      ),
    );
  }
}

class _AddTransactionModalState extends ConsumerState<AddTransactionModal> {
  late TransactionType _selectedType;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  bool _isLoading = false;

  bool get _isEditing => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final txn = widget.existingTransaction!;
      _selectedType = txn.type;
      _amountController.text = txn.amount.toStringAsFixed(2);
      _noteController.text = txn.note ?? '';
      _selectedDate = txn.date;
      _selectedCategoryId = txn.categoryId;
    } else {
      _selectedType = TransactionType.expense;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final expenseCategories = ref.watch(enabledExpenseCategoriesProvider);
    final incomeCategories = ref.watch(enabledIncomeCategoriesProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(isDark),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction type selector
                    _buildTypeSelector(isDark),
                    const SizedBox(height: 24),

                    // Amount field
                    _buildAmountField(isDark),
                    const SizedBox(height: 20),

                    // Date picker
                    _buildDatePicker(isDark),
                    const SizedBox(height: 20),


                    // Category selector (not for transfers)
                    if (_selectedType != TransactionType.transfer)
                      _selectedType == TransactionType.expense
                          ? expenseCategories.when(
                              data: (categories) =>
                                  _buildCategorySelector(isDark, categories),
                              loading: () => _buildLoadingField(isDark),
                              error: (_, __) => _buildErrorField(
                                  isDark, 'Unable to load categories'),
                            )
                          : incomeCategories.when(
                              data: (categories) =>
                                  _buildCategorySelector(isDark, categories),
                              loading: () => _buildLoadingField(isDark),
                              error: (_, __) => _buildErrorField(
                                  isDark, 'Unable to load categories'),
                            ),

                    if (_selectedType != TransactionType.transfer)
                      const SizedBox(height: 20),

                    // Note field
                    _buildNoteField(isDark),
                  ],
                ),
              ),
            ),

            // Actions
            _buildActions(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            _isEditing ? 'Edit Transaction' : 'Add Transaction',
            style: AppTypography.headlineMedium(
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: Icon(
              LucideIcons.x,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Type',
          style: AppTypography.labelMedium(
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightSurfaceHighlight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: TransactionType.values.map((type) {
              final isSelected = _selectedType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                      if (type == TransactionType.transfer) {
                        _selectedCategoryId = null;
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getTypeColor(type)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _getTypeLabel(type),
                        style: AppTypography.labelMedium(
                          isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: AppTypography.labelMedium(
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          style: AppTypography.moneyMedium(
            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            prefixText: '\$ ',
            prefixStyle: AppTypography.moneyMedium(
              isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            hintText: '0.00',
            hintStyle: AppTypography.moneyMedium(
              isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: AppTypography.labelMedium(
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                  style: AppTypography.bodyMedium(
                    isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(
      bool isDark, List<CategoryEntity> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppTypography.labelMedium(
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: AppleDropdown<String?>(
            value: _selectedCategoryId,
            isDark: isDark,
            leadingIcon: LucideIcons.tag,
            hint: 'Select category',
            items: [
              const AppleDropdownItem<String?>(value: null, label: 'Select category'),
              ...categories.map((c) => AppleDropdownItem<String?>(
                value: c.id,
                label: c.name,
              )),
            ],
            onChanged: (value) => setState(() => _selectedCategoryId = value),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note (optional)',
          style: AppTypography.labelMedium(
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLines: 2,
          style: AppTypography.bodyMedium(
            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          decoration: const InputDecoration(
            hintText: 'Add a note...',
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingField(bool isDark) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceHighlight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorField(bool isDark, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: AppTypography.bodyMedium(AppColors.accentRed),
      ),
    );
  }

  Widget _buildActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveTransaction,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(_isEditing ? 'Update' : 'Add Transaction'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    // Validate
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }


    if (_selectedType != TransactionType.transfer &&
        _selectedCategoryId == null) {
      _showError('Please select a category');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final transactionsDao = ref.read(transactionsDaoProvider);

      if (_isEditing) {
        await transactionsDao.updateTransactionById(
          widget.existingTransaction!.id,
          TransactionsCompanion(
            amount: Value(amount),
            type: Value(_selectedType),
            walletId: const Value(null),
            categoryId: Value(_selectedCategoryId),
            toWalletId: const Value(null),
            date: Value(_selectedDate),
            note: Value(_noteController.text.isEmpty
                ? null
                : _noteController.text),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await transactionsDao.insertTransaction(
          TransactionsCompanion.insert(
            id: const Uuid().v4(),
            amount: amount,
            type: _selectedType,
            walletId: const Value(null),
            categoryId: Value(_selectedCategoryId),
            toWalletId: const Value(null),
            date: _selectedDate,
            note: Value(_noteController.text.isEmpty
                ? null
                : _noteController.text),
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showError('Failed to save transaction: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium(Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.accentRed,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 80, left: 16, right: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.transfer:
        return AppColors.transfer;
    }
  }

  String _getTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }
}

