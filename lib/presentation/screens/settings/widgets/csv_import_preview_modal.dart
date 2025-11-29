import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../../../data/services/csv_service.dart';

/// Modal for previewing CSV import before confirming
class CsvImportPreviewModal extends StatelessWidget {
  final List<CsvPreviewRow> previewRows;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const CsvImportPreviewModal({
    super.key,
    required this.previewRows,
    required this.onConfirm,
    required this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required List<CsvPreviewRow> previewRows,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          return CsvImportPreviewModal(
            previewRows: previewRows,
            onConfirm: () => Navigator.of(context).pop(true),
            onCancel: () => Navigator.of(context).pop(false),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isDark = ref.watch(isDarkModeProvider);
        
        final validRows = previewRows.where((r) => r.isValid).length;
        final invalidRows = previewRows.where((r) => !r.isValid).length;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
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
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          LucideIcons.fileText,
                          size: 24,
                          color: AppColors.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Import Preview',
                              style: AppTypography.titleLarge(
                                isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$validRows valid, $invalidRows invalid rows',
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
                        onPressed: onCancel,
                        icon: const Icon(LucideIcons.x),
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ],
                  ),
                ),

                // Preview list
                Expanded(
                  child: previewRows.isEmpty
                      ? Center(
                          child: Text(
                            'No rows to preview',
                            style: AppTypography.bodyMedium(
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: previewRows.length,
                          itemBuilder: (context, index) {
                            final row = previewRows[index];
                            return _buildPreviewRow(isDark, row);
                          },
                        ),
                ),

                // Footer with actions
                Container(
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
                        onPressed: onCancel,
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
                        onPressed: validRows > 0 ? onConfirm : null,
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
                        child: Text(
                          'Import $validRows Row${validRows != 1 ? 's' : ''}',
                          style: AppTypography.labelMedium(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewRow(bool isDark, CsvPreviewRow row) {
    final data = row.data;
    final date = data['date'] ?? '';
    final type = data['type'] ?? '';
    final amount = data['amount'] ?? '';
    final category = data['category'] ?? '';
    final wallet = data['wallet'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: row.isValid
            ? (isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground)
            : AppColors.accentRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: row.isValid
              ? (isDark ? AppColors.darkDivider : AppColors.lightDivider)
              : AppColors.accentRed,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: row.isValid
                      ? AppColors.income.withValues(alpha: 0.15)
                      : AppColors.accentRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Row ${row.rowNumber}',
                  style: AppTypography.labelSmall(
                    row.isValid ? AppColors.income : AppColors.accentRed,
                  ),
                ),
              ),
              const Spacer(),
              if (row.isValid)
                const Icon(
                  LucideIcons.check,
                  size: 16,
                  color: AppColors.income,
                )
              else
                const Icon(
                  LucideIcons.x,
                  size: 16,
                  color: AppColors.accentRed,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPreviewField(isDark, 'Date', date),
          _buildPreviewField(isDark, 'Type', type),
          _buildPreviewField(isDark, 'Amount', amount),
          if (category.isNotEmpty)
            _buildPreviewField(isDark, 'Category', category),
          _buildPreviewField(isDark, 'Wallet', wallet),
          if (row.errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: row.errors.map((error) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          size: 14,
                          color: AppColors.accentRed,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            error,
                            style: AppTypography.bodySmall(AppColors.accentRed),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewField(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTypography.bodySmall(
                isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '(empty)' : value,
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
  }
}

