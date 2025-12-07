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
import '../../../../data/drift/tables/subscriptions_table.dart';
import '../../../../data/providers/database_provider.dart';
import '../../../widgets/apple_dropdown.dart';
import '../../dashboard/providers/dashboard_providers.dart';

/// Modal dialog for adding/editing subscriptions
class AddSubscriptionModal extends ConsumerStatefulWidget {
  final SubscriptionEntity? existingSubscription;

  const AddSubscriptionModal({
    super.key,
    this.existingSubscription,
  });

  @override
  ConsumerState<AddSubscriptionModal> createState() =>
      _AddSubscriptionModalState();

  /// Show the modal as a dialog
  static Future<bool?> show(
    BuildContext context, {
    SubscriptionEntity? existingSubscription,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddSubscriptionModal(
        existingSubscription: existingSubscription,
      ),
    );
  }
}

class _AddSubscriptionModalState extends ConsumerState<AddSubscriptionModal> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _reminderDaysController = TextEditingController(text: '3');
  
  BillingFrequency _selectedFrequency = BillingFrequency.monthly;
  String? _selectedCategoryId;
  DateTime _startDate = DateTime.now();
  DateTime _nextBillingDate = DateTime.now().add(const Duration(days: 30));
  bool _autoCreateTransaction = false;
  bool _isLoading = false;

  bool get _isEditing => widget.existingSubscription != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final sub = widget.existingSubscription!;
      _nameController.text = sub.name;
      _amountController.text = sub.amount.toStringAsFixed(2);
      _noteController.text = sub.note ?? '';
      _reminderDaysController.text = sub.reminderDays.toString();
      _selectedFrequency = sub.frequency;
      _selectedCategoryId = sub.categoryId;
      _startDate = sub.startDate;
      _nextBillingDate = sub.nextBillingDate;
      _autoCreateTransaction = sub.autoCreateTransaction;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _reminderDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final expenseCategories = ref.watch(enabledExpenseCategoriesProvider);

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
                    // Name field
                    _buildNameField(isDark),
                    const SizedBox(height: 20),

                    // Amount field
                    _buildAmountField(isDark),
                    const SizedBox(height: 20),

                    // Frequency selector
                    _buildFrequencySelector(isDark),
                    const SizedBox(height: 20),

                    // Category selector
                    expenseCategories.when(
                      data: (categories) =>
                          _buildCategorySelector(isDark, categories),
                      loading: () => _buildLoadingField(isDark),
                      error: (_, __) => _buildErrorField(
                          isDark, 'Unable to load categories'),
                    ),
                    const SizedBox(height: 20),

                    // Start date
                    _buildStartDatePicker(isDark),
                    const SizedBox(height: 20),

                    // Next billing date
                    _buildNextBillingDatePicker(isDark),
                    const SizedBox(height: 20),

                    // Auto-create transaction toggle
                    _buildAutoCreateToggle(isDark),
                    const SizedBox(height: 20),

                    // Reminder days
                    _buildReminderDaysField(isDark),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              LucideIcons.repeat,
              size: 24,
              color: AppColors.accentPurple,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Subscription' : 'Add Subscription',
                  style: AppTypography.titleLarge(
                    isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track recurring payments',
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

  Widget _buildNameField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscription Name',
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
            controller: _nameController,
            style: AppTypography.bodyMedium(
              isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g., Netflix, Spotify',
              hintStyle: AppTypography.bodyMedium(
                isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
              prefixIcon: Icon(
                LucideIcons.tag,
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
          'Amount',
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

  Widget _buildFrequencySelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Billing Frequency',
          style: AppTypography.labelMedium(
            isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: AppleDropdown<BillingFrequency>(
            value: _selectedFrequency,
            isDark: isDark,
            leadingIcon: LucideIcons.clock,
            items: BillingFrequency.values.map((frequency) {
              return AppleDropdownItem<BillingFrequency>(
                value: frequency,
                label: _getFrequencyLabel(frequency),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedFrequency = value);
            },
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
            isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
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
              ...categories.map((category) => AppleDropdownItem<String?>(
                value: category.id,
                label: category.name,
              )),
            ],
            onChanged: (value) {
              setState(() => _selectedCategoryId = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStartDatePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start Date',
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
              initialDate: _startDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() => _startDate = date);
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
                  DateFormat('MMMM d, yyyy').format(_startDate),
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

  Widget _buildNextBillingDatePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next Billing Date',
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
              initialDate: _nextBillingDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() => _nextBillingDate = date);
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
                  DateFormat('MMMM d, yyyy').format(_nextBillingDate),
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

  Widget _buildAutoCreateToggle(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auto-create Transaction',
                style: AppTypography.labelMedium(
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Automatically create transaction on billing date',
                style: AppTypography.bodySmall(
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _autoCreateTransaction,
          onChanged: (value) {
            setState(() => _autoCreateTransaction = value);
          },
          activeThumbColor: AppColors.accentBlue,
        ),
      ],
    );
  }

  Widget _buildReminderDaysField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder Days Before Billing',
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
            controller: _reminderDaysController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTypography.bodyMedium(
              isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: '3',
              hintStyle: AppTypography.bodyMedium(
                isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
              prefixIcon: Icon(
                LucideIcons.bell,
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

  Widget _buildNoteField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note (Optional)',
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
            controller: _noteController,
            maxLines: 3,
            style: AppTypography.bodyMedium(
              isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Add a note...',
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
            onPressed: _isLoading ? null : _saveSubscription,
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

  Future<void> _saveSubscription() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter a subscription name');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (_selectedCategoryId == null) {
      _showError('Please select a category');
      return;
    }

    final reminderDays = int.tryParse(_reminderDaysController.text) ?? 3;

    setState(() => _isLoading = true);

    try {
      final database = ref.read(databaseProvider);
      final subscriptionsDao = database.subscriptionsDao;

      if (_isEditing) {
        // Update existing subscription
        await subscriptionsDao.updateSubscriptionById(
          widget.existingSubscription!.id,
          SubscriptionsCompanion(
            name: Value(_nameController.text.trim()),
            amount: Value(amount),
            frequency: Value(_selectedFrequency),
            walletId: const Value<String?>(null),
            categoryId: Value(_selectedCategoryId!),
            startDate: Value(_startDate),
            nextBillingDate: Value(_nextBillingDate),
            note: Value(_noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim()),
            autoCreateTransaction: Value(_autoCreateTransaction),
            reminderDays: Value(reminderDays),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        // Create new subscription
        await subscriptionsDao.insertSubscription(
          SubscriptionsCompanion.insert(
            id: const Uuid().v4(),
            name: _nameController.text.trim(),
            amount: amount,
            frequency: _selectedFrequency,
            walletId: Value<String?>(null),
            categoryId: _selectedCategoryId!,
            startDate: _startDate,
            nextBillingDate: _nextBillingDate,
            note: Value(_noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim()),
            autoCreateTransaction: Value(_autoCreateTransaction),
            reminderDays: Value(reminderDays),
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to save subscription: $e');
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

  String _getFrequencyLabel(BillingFrequency frequency) {
    switch (frequency) {
      case BillingFrequency.daily:
        return 'Daily';
      case BillingFrequency.weekly:
        return 'Weekly';
      case BillingFrequency.biweekly:
        return 'Bi-weekly';
      case BillingFrequency.monthly:
        return 'Monthly';
      case BillingFrequency.quarterly:
        return 'Quarterly';
      case BillingFrequency.yearly:
        return 'Yearly';
    }
  }
}

