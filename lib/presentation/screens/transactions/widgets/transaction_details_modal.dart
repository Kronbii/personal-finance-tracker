import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
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
import '../../../../data/services/currency_formatter.dart';
import '../../../../data/providers/currency_provider.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import 'add_transaction_modal.dart';

/// Modal for displaying transaction details with edit/delete/duplicate options
class TransactionDetailsModal extends ConsumerStatefulWidget {
  final TransactionEntity transaction;

  const TransactionDetailsModal({
    super.key,
    required this.transaction,
  });

  static Future<void> show(
    BuildContext context,
    TransactionEntity transaction,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TransactionDetailsModal(
        transaction: transaction,
      ),
    );
  }

  @override
  ConsumerState<TransactionDetailsModal> createState() =>
      _TransactionDetailsModalState();
}

class _TransactionDetailsModalState
    extends ConsumerState<TransactionDetailsModal> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final wallets = ref.watch(walletsProvider);
    final categoryMap = ref.watch(categoryMapProvider);
    final currencySettings = ref.watch(currencySettingsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 1,
          ),
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
                    // Amount and Type
                    _buildAmountSection(isDark, currencySettings),
                    const SizedBox(height: 24),

                    // Transaction Details
                    wallets.when(
                      data: (walletList) => categoryMap.when(
                        data: (categories) => _buildDetailsSection(
                          isDark,
                          walletList,
                          categories,
                        ),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Note
                    if (widget.transaction.note != null &&
                        widget.transaction.note!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildNoteSection(isDark),
                    ],

                    // Tags
                    if (widget.transaction.tags != null &&
                        widget.transaction.tags!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildTagsSection(isDark),
                    ],

                    // Attachment
                    if (widget.transaction.attachmentPath != null &&
                        widget.transaction.attachmentPath!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildAttachmentSection(isDark),
                    ],

                    // Metadata
                    const SizedBox(height: 24),
                    _buildMetadataSection(isDark),
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
              color: _getTypeColor().withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getTypeIcon(),
              size: 24,
              color: _getTypeColor(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTypeLabel(),
                  style: AppTypography.titleLarge(
                    isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMMM d, yyyy • h:mm a')
                      .format(widget.transaction.date),
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
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.x),
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection(bool isDark, AsyncValue<CurrencySettings> currencySettings) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _getTypeColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getTypeColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount',
                  style: AppTypography.bodySmall(
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                currencySettings.when(
                  data: (settings) {
                    final formatted = CurrencyFormatter.format(
                      widget.transaction.amount,
                      currencyCode: settings.currencyCode,
                      conversionRate: settings.conversionRate != 1.0
                          ? settings.conversionRate
                          : null,
                    );
                    return Text(
                      formatted,
                      style: AppTypography.moneyLarge(_getTypeColor()),
                    );
                  },
                  loading: () => Text(
                    CurrencyFormatter.format(widget.transaction.amount),
                    style: AppTypography.moneyLarge(_getTypeColor()),
                  ),
                  error: (_, __) => Text(
                    CurrencyFormatter.format(widget.transaction.amount),
                    style: AppTypography.moneyLarge(_getTypeColor()),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getTypeColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.transaction.isConfirmed ? 'Confirmed' : 'Pending',
              style: AppTypography.labelSmall(_getTypeColor()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(
    bool isDark,
    List<WalletEntity> wallets,
    Map<String, CategoryEntity> categories,
  ) {
    final wallet = wallets.firstWhere(
      (w) => w.id == widget.transaction.walletId,
      orElse: () => wallets.isNotEmpty ? wallets.first : throw StateError('No wallets'),
    );
    final toWallet = widget.transaction.toWalletId != null
        ? wallets.firstWhere(
            (w) => w.id == widget.transaction.toWalletId,
            orElse: () => wallet,
          )
        : null;
    final category = widget.transaction.categoryId != null
        ? categories[widget.transaction.categoryId]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: AppTypography.titleMedium(
            isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          isDark,
          'Wallet',
          wallet.name,
          LucideIcons.wallet,
        ),
        if (widget.transaction.type == TransactionType.transfer &&
            toWallet != null) ...[
          const SizedBox(height: 12),
          _buildDetailRow(
            isDark,
            'To Wallet',
            toWallet.name,
            LucideIcons.arrowRight,
          ),
        ],
        if (category != null) ...[
          const SizedBox(height: 12),
          _buildDetailRow(
            isDark,
            'Category',
            category.name,
            _getIconData(category.iconName),
            iconColor: _parseHexColor(category.colorHex),
          ),
        ],
        const SizedBox(height: 12),
        _buildDetailRow(
          isDark,
          'Date',
          DateFormat('MMMM d, yyyy').format(widget.transaction.date),
          LucideIcons.calendar,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          isDark,
          'Time',
          DateFormat('h:mm a').format(widget.transaction.date),
          LucideIcons.clock,
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    bool isDark,
    String label,
    String value,
    IconData icon, {
    Color? iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.accentBlue)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? AppColors.accentBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall(
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium(
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note',
          style: AppTypography.titleMedium(
            isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? AppColors.darkDivider
                  : AppColors.lightDivider,
              width: 1,
            ),
          ),
          child: Text(
            widget.transaction.note!,
            style: AppTypography.bodyMedium(
              isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(bool isDark) {
    final tags = widget.transaction.tags!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: AppTypography.titleMedium(
            isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tag,
                style: AppTypography.labelSmall(AppColors.accentBlue),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAttachmentSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachment',
          style: AppTypography.titleMedium(
            isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? AppColors.darkDivider
                  : AppColors.lightDivider,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.paperclip,
                  size: 20,
                  color: AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.transaction.attachmentPath!.split('/').last,
                      style: AppTypography.bodyMedium(
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Tap to open',
                      style: AppTypography.bodySmall(
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.externalLink,
                size: 18,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metadata',
          style: AppTypography.titleMedium(
            isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildMetadataRow(
          isDark,
          'Transaction ID',
          widget.transaction.id,
        ),
        const SizedBox(height: 8),
        _buildMetadataRow(
          isDark,
          'Created',
          DateFormat('MMM d, yyyy • h:mm a')
              .format(widget.transaction.createdAt),
        ),
        if (widget.transaction.updatedAt != widget.transaction.createdAt) ...[
          const SizedBox(height: 8),
          _buildMetadataRow(
            isDark,
            'Last Updated',
            DateFormat('MMM d, yyyy • h:mm a')
                .format(widget.transaction.updatedAt),
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataRow(bool isDark, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTypography.bodySmall(
              isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall(
              isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
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
            color: isDark
                ? AppColors.darkDivider
                : AppColors.lightDivider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Duplicate button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _duplicateTransaction,
              icon: const Icon(LucideIcons.copy, size: 18),
              label: const Text('Duplicate'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: isDark
                      ? AppColors.darkDivider
                      : AppColors.lightDivider,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Delete button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isDeleting ? null : _confirmDelete,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.trash2, size: 18),
              label: Text(_isDeleting ? 'Deleting...' : 'Delete'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: AppColors.accentRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: AppColors.accentRed),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Edit button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _editTransaction,
              icon: const Icon(LucideIcons.edit, size: 18),
              label: const Text('Edit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editTransaction() async {
    Navigator.of(context).pop();
    final result = await AddTransactionModal.show(
      context,
      existingTransaction: widget.transaction,
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.check, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Text(
                'Transaction updated',
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

  Future<void> _duplicateTransaction() async {
    Navigator.of(context).pop();
    
    final database = ref.read(databaseProvider);
    final transactionsDao = database.transactionsDao;

    try {
      final newTransaction = TransactionsCompanion.insert(
        id: const Uuid().v4(),
        amount: widget.transaction.amount,
        type: widget.transaction.type,
        walletId: widget.transaction.walletId,
        categoryId: Value(widget.transaction.categoryId),
        toWalletId: Value(widget.transaction.toWalletId),
        date: DateTime.now(),
        note: Value(widget.transaction.note),
        tags: Value(widget.transaction.tags),
        isConfirmed: const Value(true),
      );

      await transactionsDao.insertTransaction(newTransaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.check, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Text(
                  'Transaction duplicated',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Text(
          'Are you sure you want to delete this ${_getTypeLabel().toLowerCase()}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteTransaction();
    }
  }

  Future<void> _deleteTransaction() async {
    setState(() => _isDeleting = true);

    try {
      final database = ref.read(databaseProvider);
      final transactionsDao = database.transactionsDao;

      await transactionsDao.deleteTransaction(widget.transaction.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.check, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Text(
                  'Transaction deleted',
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
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  Color _getTypeColor() {
    switch (widget.transaction.type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.transfer:
        return AppColors.transfer;
    }
  }

  IconData _getTypeIcon() {
    switch (widget.transaction.type) {
      case TransactionType.income:
        return LucideIcons.arrowDownLeft;
      case TransactionType.expense:
        return LucideIcons.arrowUpRight;
      case TransactionType.transfer:
        return LucideIcons.arrowRightLeft;
    }
  }

  String _getTypeLabel() {
    switch (widget.transaction.type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  IconData _getIconData(String iconName) {
    const iconMap = {
      'utensils': LucideIcons.utensils,
      'car': LucideIcons.car,
      'shopping-bag': LucideIcons.shoppingBag,
      'file-text': LucideIcons.fileText,
      'gamepad-2': LucideIcons.gamepad2,
      'heart-pulse': LucideIcons.heartPulse,
      'graduation-cap': LucideIcons.graduationCap,
      'plane': LucideIcons.plane,
      'more-horizontal': LucideIcons.moreHorizontal,
      'briefcase': LucideIcons.briefcase,
      'laptop': LucideIcons.laptop,
      'trending-up': LucideIcons.trendingUp,
      'gift': LucideIcons.gift,
      'rotate-ccw': LucideIcons.rotateCcw,
      'plus-circle': LucideIcons.plusCircle,
      'wallet': LucideIcons.wallet,
      'circle': LucideIcons.circle,
      'repeat': LucideIcons.repeat,
      'arrow-right-left': LucideIcons.arrowRightLeft,
    };
    return iconMap[iconName] ?? LucideIcons.circle;
  }

  Color _parseHexColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return AppColors.accentBlue;
  }
}

