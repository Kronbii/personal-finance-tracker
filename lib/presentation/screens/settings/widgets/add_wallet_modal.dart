import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../../../data/drift/database.dart';
import '../../../../data/providers/database_provider.dart';

/// Modal dialog for adding/editing wallets
class AddWalletModal extends ConsumerStatefulWidget {
  final WalletEntity? existingWallet;

  const AddWalletModal({
    super.key,
    this.existingWallet,
  });

  @override
  ConsumerState<AddWalletModal> createState() => _AddWalletModalState();

  /// Show the modal as a dialog
  static Future<bool?> show(
    BuildContext context, {
    WalletEntity? existingWallet,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddWalletModal(
        existingWallet: existingWallet,
      ),
    );
  }
}

class _AddWalletModalState extends ConsumerState<AddWalletModal> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedCurrency = 'USD';
  int _selectedGradientIndex = 0;
  bool _isLoading = false;

  bool get _isEditing => widget.existingWallet != null;

  // Available currencies
  static const List<Map<String, String>> currencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
    {'code': 'KRW', 'name': 'South Korean Won', 'symbol': '₩'},
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
    {'code': 'BRL', 'name': 'Brazilian Real', 'symbol': 'R\$'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'CA\$'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'CHF'},
    {'code': 'MXN', 'name': 'Mexican Peso', 'symbol': '\$'},
  ];

  // Available gradient options (0-4)
  static const int gradientCount = 5;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final wallet = widget.existingWallet!;
      _nameController.text = wallet.name;
      _balanceController.text = wallet.initialBalance.toStringAsFixed(2);
      _selectedCurrency = wallet.currency;
      _selectedGradientIndex = wallet.gradientIndex;
    } else {
      _balanceController.text = '0.00';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

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
                    // Wallet name field
                    _buildNameField(isDark),
                    const SizedBox(height: 20),

                    // Initial balance field
                    _buildBalanceField(isDark),
                    const SizedBox(height: 20),

                    // Currency selector
                    _buildCurrencySelector(isDark),
                    const SizedBox(height: 20),

                    // Gradient selector
                    _buildGradientSelector(isDark),
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
            _isEditing ? 'Edit Wallet' : 'Add Wallet',
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

  Widget _buildNameField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wallet Name',
          style: AppTypography.labelMedium(
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: AppTypography.bodyMedium(
            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'e.g., Main Bank Account, Cash',
            hintStyle: AppTypography.bodyMedium(
              isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
            prefixIcon: Icon(
              LucideIcons.wallet,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildBalanceField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Initial Balance',
          style: AppTypography.labelMedium(
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _balanceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
          ],
          style: AppTypography.moneyMedium(
            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            prefixText: _getCurrencySymbol(_selectedCurrency) + ' ',
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

  Widget _buildCurrencySelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currency',
          style: AppTypography.labelMedium(
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightSurfaceHighlight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCurrency,
              isExpanded: true,
              icon: Icon(
                LucideIcons.chevronDown,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              dropdownColor:
                  isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
              style: AppTypography.bodyMedium(
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              items: currencies.map((currency) {
                return DropdownMenuItem<String>(
                  value: currency['code'],
                  child: Row(
                    children: [
                      Text(
                        currency['symbol']!,
                        style: AppTypography.bodyMedium(
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${currency['name']} (${currency['code']})',
                          style: AppTypography.bodyMedium(
                            isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCurrency = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color Theme',
          style: AppTypography.labelMedium(
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(gradientCount, (index) {
            final isSelected = _selectedGradientIndex == index;
            final gradient = AppColors.getWalletGradient(index);

            return GestureDetector(
              onTap: () => setState(() => _selectedGradientIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentBlue
                        : Colors.transparent,
                    width: isSelected ? 3 : 0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.accentBlue.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Center(
                        child: Icon(
                          LucideIcons.check,
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Preview: This color will be used for the wallet card',
          style: AppTypography.caption(
            isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
        ),
      ],
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
              onPressed: _isLoading ? null : _saveWallet,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(_isEditing ? 'Update Wallet' : 'Add Wallet'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWallet() async {
    // Validate
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter a wallet name');
      return;
    }

    final balance = double.tryParse(_balanceController.text);
    if (balance == null) {
      _showError('Please enter a valid balance');
      return;
    }

    // Check for duplicate name (excluding current wallet if editing)
    final walletsDao = ref.read(walletsDaoProvider);
    final nameExists = await walletsDao.walletNameExists(
      _nameController.text.trim(),
      excludeId: _isEditing ? widget.existingWallet!.id : null,
    );

    if (nameExists) {
      _showError('A wallet with this name already exists');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        // Update existing wallet
        await walletsDao.updateWalletById(
          widget.existingWallet!.id,
          WalletsCompanion(
            name: Value(_nameController.text.trim()),
            initialBalance: Value(balance),
            currency: Value(_selectedCurrency),
            gradientIndex: Value(_selectedGradientIndex),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        // Get next sort order
        final allWallets = await walletsDao.getAllWallets();
        final nextSortOrder = allWallets.length;

        // Insert new wallet
        await walletsDao.insertWallet(
          WalletsCompanion.insert(
            id: const Uuid().v4(),
            name: _nameController.text.trim(),
            initialBalance: Value(balance),
            currency: Value(_selectedCurrency),
            gradientIndex: Value(_selectedGradientIndex),
            sortOrder: Value(nextSortOrder),
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showError('Failed to save wallet: $e');
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
            Icon(
              LucideIcons.alertCircle,
              color: Colors.white,
              size: 18,
            ),
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

  String _getCurrencySymbol(String code) {
    final currency = currencies.firstWhere(
      (c) => c['code'] == code,
      orElse: () => currencies.first,
    );
    return currency['symbol'] ?? '\$';
  }
}

