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
import '../../../../data/drift/tables/debts_table.dart';
import '../../../../data/providers/database_provider.dart';
import '../../../widgets/apple_dropdown.dart';
import '../../dashboard/providers/dashboard_providers.dart';

/// Modal dialog for adding/editing debts
class AddDebtModal extends ConsumerStatefulWidget {
  final DebtEntity? existingDebt;

  const AddDebtModal({
    super.key,
    this.existingDebt,
  });

  @override
  ConsumerState<AddDebtModal> createState() => _AddDebtModalState();

  /// Show the modal as a dialog
  static Future<bool?> show(
    BuildContext context, {
    DebtEntity? existingDebt,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddDebtModal(
        existingDebt: existingDebt,
      ),
    );
  }
}

class _AddDebtModalState extends ConsumerState<AddDebtModal> {
  final _personNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactInfoController = TextEditingController();

  DebtType _selectedType = DebtType.owed;
  String? _selectedWalletId;
  DateTime? _dueDate;
  bool _isLoading = false;

  bool get _isEditing => widget.existingDebt != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final debt = widget.existingDebt!;
      _personNameController.text = debt.personName;
      _amountController.text = debt.originalAmount.toStringAsFixed(2);
      _interestRateController.text =
          debt.interestRate?.toStringAsFixed(2) ?? '';
      _descriptionController.text = debt.description ?? '';
      _contactInfoController.text = debt.contactInfo ?? '';
      _selectedType = debt.type;
      _selectedWalletId = debt.walletId;
      _dueDate = debt.dueDate;
    }
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _amountController.dispose();
    _interestRateController.dispose();
    _descriptionController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final wallets = ref.watch(walletsProvider);

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
                    // Type selector
                    _buildTypeSelector(isDark),
                    const SizedBox(height: 20),

                    // Person name field
                    _buildPersonNameField(isDark),
                    const SizedBox(height: 20),

                    // Amount field
                    _buildAmountField(isDark),
                    const SizedBox(height: 20),

                    // Interest rate field (optional)
                    _buildInterestRateField(isDark),
                    const SizedBox(height: 20),

                    // Due date picker (optional)
                    _buildDueDatePicker(isDark),
                    const SizedBox(height: 20),

                    // Wallet selector (optional)
                    wallets.when(
                      data: (walletList) =>
                          _buildWalletSelector(isDark, walletList),
                      loading: () => _buildLoadingField(isDark),
                      error: (_, __) =>
                          _buildErrorField(isDark, 'Unable to load wallets'),
                    ),
                    const SizedBox(height: 20),

                    // Description field
                    _buildDescriptionField(isDark),
                    const SizedBox(height: 20),

                    // Contact info field
                    _buildContactInfoField(isDark),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (_selectedType == DebtType.owed
                      ? AppColors.expense
                      : AppColors.income)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _selectedType == DebtType.owed
                  ? LucideIcons.arrowUpRight
                  : LucideIcons.arrowDownLeft,
              size: 24,
              color: _selectedType == DebtType.owed
                  ? AppColors.expense
                  : AppColors.income,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Debt' : 'Add Debt',
                  style: AppTypography.titleLarge(
                    isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track money owed or lent',
                  style: AppTypography.bodySmall(
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(LucideIcons.x),
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
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
          'Type',
          style: AppTypography.labelMedium(
            isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTypeChip(
                isDark,
                DebtType.owed,
                'You Owe',
                LucideIcons.arrowUpRight,
                AppColors.expense,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeChip(
                isDark,
                DebtType.lent,
                'Owed to You',
                LucideIcons.arrowDownLeft,
                AppColors.income,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(
    bool isDark,
    DebtType type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () {
        setState(() => _selectedType = type);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : (isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark
                    ? AppColors.darkDivider
                    : AppColors.lightDivider),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isSelected ? color : null),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelMedium(
                isSelected
                    ? color
                    : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonNameField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Person/Entity Name',
          style: AppTypography.labelMedium(
            isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkDivider
                  : AppColors.lightDivider,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _personNameController,
            style: AppTypography.bodyMedium(
              isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g., John Doe, Company Name',
              hintStyle: AppTypography.bodyMedium(
                isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
              prefixIcon: Icon(
                LucideIcons.user,
                size: 20,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
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
          'Original Amount',
          style: AppTypography.labelMedium(
            isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkDivider
                  : AppColors.lightDivider,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: AppTypography.bodyMedium(
              isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: AppTypography.bodyMedium(
                isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
              prefixText: '\$ ',
              prefixIcon: Icon(
                LucideIcons.dollarSign,
                size: 20,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestRateField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interest Rate % (Optional)',
          style: AppTypography.labelMedium(
            isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkDivider
                  : AppColors.lightDivider,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _interestRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: AppTypography.bodyMedium(
              isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: AppTypography.bodyMedium(
                isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
              prefixIcon: Icon(
                LucideIcons.percent,
                size: 20,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDueDatePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Date (Optional)',
          style: AppTypography.labelMedium(
            isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _dueDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() => _dueDate = date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.darkDivider
                    : AppColors.lightDivider,
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
                Text(
                  _dueDate != null
                      ? DateFormat('MMMM d, yyyy').format(_dueDate!)
                      : 'Select due date',
                  style: AppTypography.bodyMedium(
                    _dueDate != null
                        ? (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary)
                        : (isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary),
                  ),
                ),
                const Spacer(),
                if (_dueDate != null)
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 16),
                    onPressed: () {
                      setState(() => _dueDate = null);
                    },
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletSelector(bool isDark, List<WalletEntity> wallets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wallet (Optional)',
          style: AppTypography.labelMedium(
            isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: AppleDropdown<String?>(
            value: _selectedWalletId,
            isDark: isDark,
            leadingIcon: LucideIcons.wallet,
            hint: 'Select wallet',
            items: [
              const AppleDropdownItem<String?>(value: null, label: 'None'),
              ...wallets.map((wallet) => AppleDropdownItem<String?>(
                value: wallet.id,
                label: wallet.name,
              )),
            ],
            onChanged: (value) {
              setState(() => _selectedWalletId = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (Optional)',
          style: AppTypography.labelMedium(
            isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkDivider
                  : AppColors.lightDivider,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _descriptionController,
            maxLines: 3,
            style: AppTypography.bodyMedium(
              isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Add description...',
              hintStyle: AppTypography.bodyMedium(
                isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Icon(
                  LucideIcons.fileText,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfoField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Info (Optional)',
          style: AppTypography.labelMedium(
            isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkDivider
                  : AppColors.lightDivider,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _contactInfoController,
            keyboardType: TextInputType.emailAddress,
            style: AppTypography.bodyMedium(
              isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Phone or email',
              hintStyle: AppTypography.bodyMedium(
                isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
              prefixIcon: Icon(
                LucideIcons.phone,
                size: 20,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingField(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkDivider
              : AppColors.lightDivider,
          width: 1,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorField(bool isDark, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentRed,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, color: AppColors.accentRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium(AppColors.accentRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.darkDivider
                : AppColors.lightDivider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.labelMedium(
                isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveDebt,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isEditing ? 'Update' : 'Add',
                    style: AppTypography.labelMedium(Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDebt() async {
    // Validation
    if (_personNameController.text.trim().isEmpty) {
      _showError('Please enter a person/entity name');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    final interestRate = _interestRateController.text.trim().isEmpty
        ? null
        : double.tryParse(_interestRateController.text);

    if (_interestRateController.text.trim().isNotEmpty &&
        (interestRate == null || interestRate < 0)) {
      _showError('Please enter a valid interest rate');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final database = ref.read(databaseProvider);
      final debtsDao = database.debtsDao;

      if (_isEditing) {
        // Update existing debt
        await debtsDao.updateDebtById(
          widget.existingDebt!.id,
          DebtsCompanion(
            personName: Value(_personNameController.text.trim()),
            originalAmount: Value(amount),
            remainingAmount: Value(amount), // Reset to original for now
            type: Value(_selectedType),
            dueDate: Value(_dueDate),
            walletId: Value(_selectedWalletId),
            interestRate: Value(interestRate),
            description: Value(_descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim()),
            contactInfo: Value(_contactInfoController.text.trim().isEmpty
                ? null
                : _contactInfoController.text.trim()),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        // Create new debt
        await debtsDao.insertDebt(
          DebtsCompanion.insert(
            id: const Uuid().v4(),
            personName: _personNameController.text.trim(),
            originalAmount: amount,
            remainingAmount: amount,
            type: _selectedType,
            dueDate: Value(_dueDate),
            walletId: Value(_selectedWalletId),
            interestRate: Value(interestRate),
            description: Value(_descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim()),
            contactInfo: Value(_contactInfoController.text.trim().isEmpty
                ? null
                : _contactInfoController.text.trim()),
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.check, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Text(
                  _isEditing ? 'Debt updated' : 'Debt added',
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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to save debt: $e');
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}





