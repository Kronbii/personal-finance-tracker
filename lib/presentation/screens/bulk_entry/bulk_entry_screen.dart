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
import '../../../app/utils/responsive.dart';
import '../../../data/drift/database.dart';
import '../../../data/drift/tables/transactions_table.dart';
import '../../../data/providers/database_provider.dart';
import '../../widgets/apple_dropdown.dart';
import '../dashboard/providers/dashboard_providers.dart';

/// Intent for save action
class _SaveIntent extends Intent {
  const _SaveIntent();
}

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
  DateTime? _firstRowMonth; // Track the month from the first row

  @override
  void initState() {
    super.initState();
    // Start with 1 empty row
    _addRow();
  }

  void _addRow() {
    setState(() {
      // Use first row's month if available, otherwise use current month
      final defaultDate = _firstRowMonth ?? DateTime.now();
      final dateText = _firstRowMonth != null 
          ? DateFormat('yyyy-MM').format(defaultDate)
          : DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final amountFocus = FocusNode();
      final categoryFocus = FocusNode();
      final noteFocus = FocusNode();
      
      final newRow = BulkEntryRow(
        id: const Uuid().v4(),
        dateController: TextEditingController(text: dateText),
        amountController: TextEditingController(),
        noteController: TextEditingController(),
        amountFocusNode: amountFocus,
        categoryFocusNode: categoryFocus,
        noteFocusNode: noteFocus,
      );
      
      _rows.add(newRow);
      
      // Set up focus navigation: note -> next row's amount (if exists)
      final rowIndex = _rows.length - 1;
      noteFocus.addListener(() {
        if (!noteFocus.hasFocus) {
          // Focus moved away from note, try to move to next row's amount
          if (rowIndex < _rows.length - 1) {
            _rows[rowIndex + 1].amountFocusNode.requestFocus();
          }
        }
      });
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
      _firstRowMonth = null; // Reset first row month
      for (final row in _rows) {
        row.amountController.clear();
        row.noteController.clear();
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
    final expenseCategories = ref.watch(enabledExpenseCategoriesProvider);
    final incomeCategories = ref.watch(enabledIncomeCategoriesProvider);

    return Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
              // Check if any text field has focus - if so, let it handle the space
              final hasTextFieldFocus = _rows.any((row) =>
                  row.amountFocusNode.hasFocus ||
                  row.noteFocusNode.hasFocus);
              
              if (hasTextFieldFocus) {
                return KeyEventResult.ignored; // Let text field handle space
              }
              
              // Only handle space for save if not in a text field
              final validRows = _rows.where((row) {
                final amount = double.tryParse(row.amountController.text);
                return amount != null &&
                    amount > 0 &&
                    row.selectedCategoryId != null;
              }).length;
              if (validRows > 0 && !_isSaving) {
                _saveAll(validRows);
              }
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Scaffold(
            backgroundColor:
                isDark ? AppColors.darkBackground : AppColors.lightBackground,
            body: Column(
              children: [
                // Header
                _buildHeader(isDark),

                // Grid
                Expanded(
                  child: expenseCategories.when(
                    data: (expenseCats) => incomeCategories.when(
                      data: (incomeCats) => _buildGrid(
                        isDark,
                        expenseCats,
                        incomeCats,
                      ),
                      loading: () => _buildLoading(),
                      error: (_, __) => _buildError(isDark, 'Error loading categories'),
                    ),
                    loading: () => _buildLoading(),
                    error: (_, __) => _buildError(isDark, 'Error loading categories'),
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
    return Padding(
      padding: Responsive.allPaddingInsets(context),
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
                focusNode: row.amountFocusNode,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => row.noteFocusNode.requestFocus(), // Skip category dropdown
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

          // Category dropdown
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AppleDropdown<String?>(
                value: row.selectedCategoryId,
                isDark: isDark,
                hint: 'Category',
                focusNode: row.categoryFocusNode,
                onSubmitted: () => row.noteFocusNode.requestFocus(),
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
                focusNode: row.noteFocusNode,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  // Move to next row's amount if exists, otherwise stay here
                  if (index < _rows.length - 1) {
                    _rows[index + 1].amountFocusNode.requestFocus();
                  }
                },
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
                  _formatDateDisplay(row.dateController.text),
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
    final isDark = ref.watch(isDarkModeProvider);
    final currentDate = _parseDate(row.dateController.text);
    final isFirstRow = _rows.indexOf(row) == 0;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MonthPickerDialog(
        initialDate: currentDate,
        isDark: isDark,
        isFirstRow: isFirstRow,
      ),
    );
    
    if (result != null) {
      setState(() {
        final year = result['year'] as int;
        final month = result['month'] as int;
        final day = result['day'] as int?;
        
        // If first row, store the month
        if (isFirstRow) {
          _firstRowMonth = DateTime(year, month, 1);
        }
        
        // Format date: yyyy-MM-dd if day is provided, yyyy-MM if not
        if (day != null) {
          row.dateController.text = DateFormat('yyyy-MM-dd').format(DateTime(year, month, day));
        } else {
          row.dateController.text = DateFormat('yyyy-MM').format(DateTime(year, month, 1));
        }
      });
    }
  }
  
  DateTime _parseDate(String dateText) {
    // Try parsing as full date (yyyy-MM-dd)
    final fullDate = DateTime.tryParse(dateText);
    if (fullDate != null) return fullDate;
    
    // Try parsing as month only (yyyy-MM)
    final parts = dateText.trim().split('-');
    if (parts.length == 2) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      if (year != null && 
          month != null && 
          month >= 1 && 
          month <= 12 &&
          year >= 2000 && 
          year <= 2100) {
        return DateTime(year, month, 1);
      }
    }
    
    // Fallback to current date
    return DateTime.now();
  }
  
  bool _isMonthOnlyFormat(String dateText) {
    // Check if DateTime.tryParse succeeds (full date format)
    final fullDate = DateTime.tryParse(dateText.trim());
    if (fullDate != null) return false;
    
    // Check if it matches yyyy-MM format
    final parts = dateText.trim().split('-');
    if (parts.length == 2) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      return year != null && 
             month != null && 
             month >= 1 && 
             month <= 12 &&
             year >= 2000 && 
             year <= 2100;
    }
    
    return false;
  }
  
  String _formatDateDisplay(String dateText) {
    final date = _parseDate(dateText);
    // Check if it's month-only format
    if (_isMonthOnlyFormat(dateText)) {
      return DateFormat('MMM yyyy').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
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
            row.selectedCategoryId != null) {
          // Parse date - handle both yyyy-MM-dd and yyyy-MM formats
          final dateText = row.dateController.text;
          // _parseDate already handles month-only by returning day 1
          final transactionDate = _parseDate(dateText);

          transactions.add(TransactionsCompanion.insert(
            id: const Uuid().v4(),
            amount: amount,
            type: row.selectedType,
            walletId: const Value(null),
            categoryId: Value(row.selectedCategoryId),
            date: transactionDate,
            note: Value(row.noteController.text.isEmpty
                ? null
                : row.noteController.text),
          ));
        }
      }

      await transactionsDao.insertTransactions(transactions);

      if (mounted) {
        _clearAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error saving transactions: $e',
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
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// Month picker dialog with optional day selection
class _MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final bool isDark;
  final bool isFirstRow;

  const _MonthPickerDialog({
    required this.initialDate,
    required this.isDark,
    required this.isFirstRow,
  });

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  int? _selectedDay;
  bool _includeDay = false;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;
    // Default to including day if it's not the 1st, otherwise default to month-only
    _includeDay = widget.initialDate.day != 1;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (i) => currentYear - i);
    final months = List.generate(12, (i) => i + 1);
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final days = List.generate(daysInMonth, (i) => i + 1);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Text(
                  'Select Date',
                  style: AppTypography.titleLarge(
                    widget.isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    LucideIcons.x,
                    color: widget.isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Year selector
            Text(
              'Year',
              style: AppTypography.labelMedium(
                widget.isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            AppleDropdown<int>(
              value: _selectedYear,
              isDark: widget.isDark,
              items: years
                  .map((y) => AppleDropdownItem(value: y, label: y.toString()))
                  .toList(),
              onChanged: (value) => setState(() {
                _selectedYear = value;
                if (_includeDay && _selectedDay != null) {
                  final daysInNewMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
                  if (_selectedDay! > daysInNewMonth) {
                    _selectedDay = daysInNewMonth;
                  }
                }
              }),
            ),
            const SizedBox(height: 16),
            // Month selector
            Text(
              'Month',
              style: AppTypography.labelMedium(
                widget.isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            AppleDropdown<int>(
              value: _selectedMonth,
              isDark: widget.isDark,
              items: months
                  .map((m) => AppleDropdownItem(
                        value: m,
                        label: _getMonthName(m),
                      ))
                  .toList(),
              onChanged: (value) => setState(() {
                _selectedMonth = value;
                if (_includeDay && _selectedDay != null) {
                  final daysInNewMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
                  if (_selectedDay! > daysInNewMonth) {
                    _selectedDay = daysInNewMonth;
                  }
                }
              }),
            ),
            const SizedBox(height: 16),
            // Include day checkbox
            Row(
              children: [
                Checkbox(
                  value: _includeDay,
                  onChanged: (value) => setState(() {
                    _includeDay = value ?? false;
                    if (!_includeDay) {
                      _selectedDay = null;
                    } else {
                      _selectedDay = widget.initialDate.day;
                    }
                  }),
                ),
                Expanded(
                  child: Text(
                    'Include specific day',
                    style: AppTypography.bodyMedium(
                      widget.isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
            // Day selector (if enabled)
            if (_includeDay) ...[
              const SizedBox(height: 16),
              Text(
                'Day',
                style: AppTypography.labelMedium(
                  widget.isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              AppleDropdown<int?>(
                value: _selectedDay,
                isDark: widget.isDark,
                items: days
                    .map((d) => AppleDropdownItem<int?>(value: d, label: d.toString()))
                    .toList(),
                onChanged: (value) => setState(() => _selectedDay = value),
              ),
            ],
            const SizedBox(height: 24),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: AppTypography.labelMedium(
                      widget.isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'year': _selectedYear,
                      'month': _selectedMonth,
                      'day': _includeDay ? _selectedDay : null,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Select',
                    style: AppTypography.labelMedium(Colors.white),
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }
}

/// Data class for a bulk entry row
class BulkEntryRow {
  final String id;
  final TextEditingController dateController;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final FocusNode amountFocusNode;
  final FocusNode categoryFocusNode;
  final FocusNode noteFocusNode;
  String? selectedCategoryId;
  TransactionType selectedType;

  BulkEntryRow({
    required this.id,
    required this.dateController,
    required this.amountController,
    required this.noteController,
    required this.amountFocusNode,
    required this.categoryFocusNode,
    required this.noteFocusNode,
    this.selectedCategoryId,
    this.selectedType = TransactionType.expense,
  });

  void dispose() {
    dateController.dispose();
    amountController.dispose();
    noteController.dispose();
    amountFocusNode.dispose();
    categoryFocusNode.dispose();
    noteFocusNode.dispose();
  }
}
