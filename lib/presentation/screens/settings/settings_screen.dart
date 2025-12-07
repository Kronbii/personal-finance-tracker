import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../app/utils/responsive.dart';
import '../../../data/drift/database.dart';
import '../../../data/drift/tables/categories_table.dart';
import '../../../data/providers/database_provider.dart';
import '../../../data/services/csv_service.dart';
import '../../../data/services/currency_formatter.dart';
import '../../../data/providers/currency_provider.dart';
import '../dashboard/providers/dashboard_providers.dart';
import 'widgets/add_wallet_modal.dart';
import 'widgets/csv_import_preview_modal.dart';
import 'widgets/currency_picker.dart';
import 'widgets/manage_categories_modal.dart';
import 'widgets/manage_wallet_balances_modal.dart';

/// Settings screen - App configuration and data management
/// Features: Theme toggle, currency, wallets/categories management, import/export, sync
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final wallets = ref.watch(walletsProvider);
    final expenseCategories = ref.watch(expenseCategoriesProvider);
    final incomeCategories = ref.watch(incomeCategoriesProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(isDark),
          ),

          // Settings sections
          SliverPadding(
            padding: Responsive.horizontalPaddingInsets(context),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appearance section
                  _buildSectionHeader(isDark, 'Appearance'),
                  const SizedBox(height: 12),
                  _buildAppearanceSection(isDark),
                  const SizedBox(height: 32),

                  // Data Management section
                  _buildSectionHeader(isDark, 'Data Management'),
                  const SizedBox(height: 12),
                  _buildDataManagementSection(isDark),
                  const SizedBox(height: 32),

                  // Wallets section
                  _buildSectionHeader(isDark, 'Wallets'),
                  const SizedBox(height: 12),
                  _buildWalletsSection(isDark, wallets),
                  const SizedBox(height: 32),

                  // Wallet Balances section
                  _buildSectionHeader(isDark, 'Wallet Balances'),
                  const SizedBox(height: 12),
                  _buildWalletBalancesSection(isDark),
                  const SizedBox(height: 32),

                  // Categories section
                  _buildSectionHeader(isDark, 'Categories'),
                  const SizedBox(height: 12),
                  _buildCategoriesSection(
                      isDark, expenseCategories, incomeCategories),
                  const SizedBox(height: 32),

                  // Sync section
                  _buildSectionHeader(isDark, 'Sync'),
                  const SizedBox(height: 12),
                  _buildSyncSection(isDark),
                  const SizedBox(height: 32),

                  // About section
                  _buildSectionHeader(isDark, 'About'),
                  const SizedBox(height: 12),
                  _buildAboutSection(isDark),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: Responsive.allPaddingInsets(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: AppTypography.displaySmall(
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 8),
          Text(
            'Customize your experience',
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

  Widget _buildSectionHeader(bool isDark, String title) {
    return Text(
      title,
      style: AppTypography.titleLarge(
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }

  Widget _buildAppearanceSection(bool isDark) {
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final currencySettings = ref.watch(currencySettingsProvider);

    return _buildSettingsCard(
      isDark: isDark,
      children: [
        _buildSettingsTile(
          isDark: isDark,
          icon: LucideIcons.moon,
          title: 'Dark Mode',
          subtitle: isDark ? 'Currently enabled' : 'Currently disabled',
          trailing: Switch(
            value: isDark,
            onChanged: (_) => themeNotifier.toggle(),
            activeThumbColor: AppColors.accentBlue,
          ),
        ),
        _buildDivider(isDark),
        _buildSettingsTile(
          isDark: isDark,
          icon: LucideIcons.dollarSign,
          title: 'Default Currency',
          subtitle: currencySettings.when(
            data: (settings) {
              final currency = CurrencyFormatter.getCurrency(settings.currencyCode);
              final rate = settings.conversionRate != 1.0
                  ? ' (Rate: ${settings.conversionRate.toStringAsFixed(4)})'
                  : '';
              return '${currency?.name ?? settings.currencyCode}$rate';
            },
            loading: () => 'Loading...',
            error: (_, __) => 'USD - US Dollar',
          ),
          trailing: const Icon(LucideIcons.chevronRight, size: 20),
          onTap: () => _showCurrencyPicker(),
        ),
      ],
    );
  }

  Widget _buildDataManagementSection(bool isDark) {
    return _buildSettingsCard(
      isDark: isDark,
      children: [
        _buildSettingsTile(
          isDark: isDark,
          icon: LucideIcons.download,
          title: 'Export Data',
          subtitle: 'Export transactions to CSV',
          trailing: const Icon(LucideIcons.chevronRight, size: 20),
          onTap: () => _exportData(),
        ),
        _buildDivider(isDark),
        _buildSettingsTile(
          isDark: isDark,
          icon: LucideIcons.upload,
          title: 'Import Data',
          subtitle: 'Import transactions from CSV',
          trailing: const Icon(LucideIcons.chevronRight, size: 20),
          onTap: () => _importData(),
        ),
        _buildDivider(isDark),
        _buildSettingsTile(
          isDark: isDark,
          icon: LucideIcons.trash2,
          iconColor: AppColors.accentRed,
          title: 'Clear All Data',
          subtitle: 'Delete all transactions and reset',
          trailing: const Icon(LucideIcons.chevronRight, size: 20),
          onTap: () => _confirmClearData(),
        ),
      ],
    );
  }

  Widget _buildWalletsSection(
      bool isDark, AsyncValue<List<WalletEntity>> wallets) {
    return _buildSettingsCard(
      isDark: isDark,
      children: [
        wallets.when(
          data: (walletList) => Column(
            children: [
              ...walletList.map((wallet) => Column(
                    children: [
                      _buildSettingsTile(
                        isDark: isDark,
                        icon: LucideIcons.wallet,
                        iconColor: AppColors.getWalletGradient(
                            wallet.gradientIndex)[0],
                        title: wallet.name,
                        subtitle: wallet.currency,
                        trailing: const Icon(LucideIcons.chevronRight, size: 20),
                        onTap: () => _editWallet(wallet),
                      ),
                      if (wallet != walletList.last) _buildDivider(isDark),
                    ],
                  )),
              _buildDivider(isDark),
              _buildSettingsTile(
                isDark: isDark,
                icon: LucideIcons.plus,
                iconColor: AppColors.accentBlue,
                title: 'Add Wallet',
                subtitle: 'Create a new wallet',
                trailing: const Icon(LucideIcons.chevronRight, size: 20),
                onTap: () => _addWallet(),
              ),
            ],
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error loading wallets',
              style: AppTypography.bodyMedium(AppColors.accentRed),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletBalancesSection(bool isDark) {
    return _buildSettingsCard(
      isDark: isDark,
      children: [
        _buildSettingsTile(
          isDark: isDark,
          icon: LucideIcons.wallet,
          iconColor: AppColors.accentBlue,
          title: 'Manage Wallet Balances',
          subtitle: 'Track monthly balances for each wallet',
          trailing: const Icon(LucideIcons.chevronRight, size: 20),
          onTap: () => _manageWalletBalances(),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(
    bool isDark,
    AsyncValue<List<CategoryEntity>> expenseCategories,
    AsyncValue<List<CategoryEntity>> incomeCategories,
  ) {
    return _buildSettingsCard(
      isDark: isDark,
      children: [
        _buildSettingsTile(
          isDark: isDark,
          icon: LucideIcons.trendingDown,
          iconColor: AppColors.expense,
          title: 'Expense Categories',
          subtitle: expenseCategories.when(
            data: (cats) => '${cats.length} categories',
            loading: () => 'Loading...',
            error: (_, __) => 'Error',
          ),
          trailing: const Icon(LucideIcons.chevronRight, size: 20),
          onTap: () => _manageCategories('expense'),
        ),
        _buildDivider(isDark),
        _buildSettingsTile(
          isDark: isDark,
          icon: LucideIcons.trendingUp,
          iconColor: AppColors.income,
          title: 'Income Categories',
          subtitle: incomeCategories.when(
            data: (cats) => '${cats.length} categories',
            loading: () => 'Loading...',
            error: (_, __) => 'Error',
          ),
          trailing: const Icon(LucideIcons.chevronRight, size: 20),
          onTap: () => _manageCategories('income'),
        ),
      ],
    );
  }

  Widget _buildSyncSection(bool isDark) {
    return _buildSettingsCard(
      isDark: isDark,
      children: [
        _buildSettingsTile(
          isDark: isDark,
          icon: LucideIcons.cloud,
          title: 'Supabase Sync',
          subtitle: 'Not configured',
          trailing: const Icon(LucideIcons.chevronRight, size: 20),
          onTap: () => _configureSupabase(),
        ),
        _buildDivider(isDark),
        _buildSettingsTile(
          isDark: isDark,
          icon: LucideIcons.refreshCw,
          iconColor: AppColors.accentBlue,
          title: 'Sync Now',
          subtitle: 'Push and pull changes',
          trailing: _isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.chevronRight, size: 20),
          onTap: _isSyncing ? null : () => _syncNow(),
        ),
      ],
    );
  }

  Widget _buildAboutSection(bool isDark) {
    return _buildSettingsCard(
      isDark: isDark,
      children: [
        _buildSettingsTile(
          isDark: isDark,
          icon: LucideIcons.info,
          title: 'Version',
          subtitle: '1.0.0',
          trailing: null,
        ),
        _buildDivider(isDark),
        _buildSettingsTile(
          isDark: isDark,
          icon: LucideIcons.github,
          title: 'Source Code',
          subtitle: 'View on GitHub',
          trailing: const Icon(LucideIcons.externalLink, size: 20),
          onTap: () {},
        ),
        _buildDivider(isDark),
        _buildSettingsTile(
          isDark: isDark,
          icon: LucideIcons.fileText,
          title: 'Licenses',
          subtitle: 'Open source licenses',
          trailing: const Icon(LucideIcons.chevronRight, size: 20),
          onTap: () => showLicensePage(context: context),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 1,
        ),
      ),
      child: Column(children: children),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildSettingsTile({
    required bool isDark,
    required IconData icon,
    Color? iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.accentBlue)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium(
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall(
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                IconTheme(
                  data: IconThemeData(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  child: trailing,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
      ),
    );
  }

  Future<void> _showCurrencyPicker() async {
    final result = await CurrencyPickerModal.show(context);
    if (result == true && mounted) {
      // Currency settings were updated, the stream will automatically update
    }
  }

  Future<void> _exportData() async {
    try {
      final database = ref.read(databaseProvider);
      final csvService = CsvService(database);

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final filePath = await csvService.exportTransactions();

      // Close loading dialog safely
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.check, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Transactions exported successfully',
                    style: AppTypography.bodyMedium(Colors.white),
                  ),
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
      // Close loading dialog safely if still open
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Export failed: ${e.toString()}',
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
  }

  Future<void> _importData() async {
    try {
      // Pick CSV file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        dialogTitle: 'Import Transactions',
      );

      if (result == null || result.files.single.path == null) {
        return; // User cancelled
      }

      final filePath = result.files.single.path!;
      final database = ref.read(databaseProvider);
      final csvService = CsvService(database);

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Preview CSV
      final previewRows = await csvService.previewImport(filePath);

      // Close loading dialog safely
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show preview modal
      if (!mounted) return;
      final shouldImport = await CsvImportPreviewModal.show(
        context,
        previewRows: previewRows,
      );

      if (shouldImport != true) {
        return; // User cancelled
      }

      // Show loading indicator during import
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Import transactions
      final importResult = await csvService.importTransactions(filePath);

      // Close loading dialog safely
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show results
      if (!mounted) return;
      
      final message = importResult.successful > 0
          ? 'Successfully imported ${importResult.successful} transaction${importResult.successful != 1 ? 's' : ''}'
          : 'No transactions were imported';
      
      final hasErrors = importResult.failed > 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasErrors ? LucideIcons.alertTriangle : LucideIcons.check,
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
              if (hasErrors) ...[
                const SizedBox(height: 8),
                Text(
                  '${importResult.failed} row${importResult.failed != 1 ? 's' : ''} failed',
                  style: AppTypography.bodySmall(
                    Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
          backgroundColor: hasErrors ? AppColors.accentRed : AppColors.income,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: Duration(seconds: hasErrors ? 5 : 3),
        ),
      );
    } catch (e) {
      // Close loading dialog safely if still open
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Import failed: ${e.toString()}',
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
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your transactions, wallets, and categories. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllData();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final database = ref.read(databaseProvider);
      await database.clearAllData();

      // Close loading dialog safely
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.check, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All data cleared successfully',
                    style: AppTypography.bodyMedium(Colors.white),
                  ),
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
      // Close loading dialog safely if still open
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to clear data: ${e.toString()}',
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
  }

  Future<void> _editWallet(WalletEntity wallet) async {
    final result = await AddWalletModal.show(
      context,
      existingWallet: wallet,
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.check, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Text(
                'Wallet updated successfully',
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

  Future<void> _addWallet() async {
    final result = await AddWalletModal.show(context);
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.check, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Text(
                'Wallet added successfully',
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

  Future<void> _manageWalletBalances() async {
    final result = await ManageWalletBalancesModal.show(context);
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.check, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Text(
                'Wallet balances updated',
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

  Future<void> _manageCategories(String type) async {
    final categoryType = type == 'expense'
        ? CategoryType.expense
        : CategoryType.income;
    
    final result = await ManageCategoriesModal.show(
      context,
      initialTab: categoryType,
    );
    
    if (result == true && mounted) {
      // Categories were modified, the stream will automatically update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.check, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Text(
                'Categories updated',
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

  void _configureSupabase() {
    // TODO: Implement Supabase configuration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Supabase configuration coming soon')),
    );
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);

    // Simulate sync
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.check, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Text(
                'Sync completed',
                style: AppTypography.bodyMedium(Colors.white),
              ),
            ],
          ),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
