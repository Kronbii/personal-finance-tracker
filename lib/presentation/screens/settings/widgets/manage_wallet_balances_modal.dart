import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../../../data/drift/database.dart';
import '../../../../data/providers/database_provider.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../monthly_insights/providers/monthly_insights_providers.dart';
import 'add_wallet_balance_modal.dart';

/// Modal for managing wallet balances by month
class ManageWalletBalancesModal extends ConsumerStatefulWidget {
  const ManageWalletBalancesModal({super.key});

  /// Show the modal as a dialog
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ManageWalletBalancesModal(),
    );
  }

  @override
  ConsumerState<ManageWalletBalancesModal> createState() =>
      _ManageWalletBalancesModalState();
}

class _ManageWalletBalancesModalState
    extends ConsumerState<ManageWalletBalancesModal> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final wallets = ref.watch(walletsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 800,
        height: 600,
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
          children: [
            // Header
            _buildHeader(isDark),
            const Divider(height: 1),

            // Month selector
            _buildMonthSelector(isDark),
            const Divider(height: 1),

            // Content
            Expanded(
              child: wallets.when(
                data: (walletList) => _buildBalancesList(isDark, walletList),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.alertCircle,
                        size: 48,
                        color: AppColors.accentRed,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading wallets',
                        style: AppTypography.bodyMedium(AppColors.accentRed),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Text(
            'Wallet Balances',
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

  Widget _buildMonthSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Month:',
            style: AppTypography.labelMedium(
              isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightSurfaceHighlight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.calendar,
                    size: 18,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                    style: AppTypography.bodyMedium(
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      LucideIcons.chevronLeft,
                      size: 18,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month - 1,
                          1,
                        );
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month + 1,
                          1,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalancesList(bool isDark, List<WalletEntity> wallets) {
    final walletBalancesDao = ref.read(walletBalancesDaoProvider);

    return FutureBuilder<List<WalletBalanceEntity>>(
      future: Future.wait(
        wallets.map((w) => walletBalancesDao.getBalanceForMonth(
          w.id,
          _selectedDate.year,
          _selectedDate.month,
        )),
      ).then((results) => results.whereType<WalletBalanceEntity>().toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final balances = snapshot.data ?? <WalletBalanceEntity>[];
        final balanceMap = {for (var b in balances) b.walletId: b};

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: wallets.length,
          itemBuilder: (context, index) {
            final wallet = wallets[index];
            final balance = balanceMap[wallet.id];

            return _buildBalanceItem(isDark, wallet, balance);
          },
        );
      },
    );
  }

  Widget _buildBalanceItem(
    bool isDark,
    WalletEntity wallet,
    WalletBalanceEntity? balance,
  ) {
    final color = AppColors.getWalletGradient(wallet.gradientIndex)[0];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            LucideIcons.wallet,
            size: 22,
            color: color,
          ),
        ),
        title: Text(
          wallet.name,
          style: AppTypography.titleMedium(
            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        subtitle: Text(
          balance != null
              ? 'Balance: ${balance.balance.toStringAsFixed(2)} ${wallet.currency}'
              : 'No balance entered',
          style: AppTypography.bodySmall(
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        trailing: IconButton(
          onPressed: () => _addOrEditBalance(wallet, balance),
          icon: Icon(
            balance != null ? LucideIcons.pencil : LucideIcons.plus,
            size: 18,
            color: AppColors.accentBlue,
          ),
          tooltip: balance != null ? 'Edit balance' : 'Add balance',
        ),
      ),
    );
  }

  Future<void> _addOrEditBalance(
    WalletEntity wallet,
    WalletBalanceEntity? existingBalance,
  ) async {
    final result = await AddWalletBalanceModal.show(
      context,
      wallet: wallet,
      year: _selectedDate.year,
      month: _selectedDate.month,
      existingBalance: existingBalance,
    );

    if (result == true && mounted) {
      setState(() {}); // Refresh the list
      // Invalidate the provider for the month that was updated
      final month = DateTime(_selectedDate.year, _selectedDate.month, 1);
      ref.invalidate(monthWalletBalancesProvider(month));
    }
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

