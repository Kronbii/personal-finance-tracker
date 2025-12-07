import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../../../data/drift/database.dart';
import '../../../../data/drift/tables/categories_table.dart';
import '../../../../data/providers/database_provider.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import 'add_category_modal.dart';

/// Modal for managing categories with tabs, reordering, and deletion
class ManageCategoriesModal extends ConsumerStatefulWidget {
  final CategoryType? initialTab;

  const ManageCategoriesModal({
    super.key,
    this.initialTab,
  });

  @override
  ConsumerState<ManageCategoriesModal> createState() =>
      _ManageCategoriesModalState();

  /// Show the modal as a dialog
  static Future<bool?> show(
    BuildContext context, {
    CategoryType? initialTab,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ManageCategoriesModal(
        initialTab: initialTab,
      ),
    );
  }
}

class _ManageCategoriesModalState
    extends ConsumerState<ManageCategoriesModal> {
  late CategoryType _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab ?? CategoryType.expense;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final expenseCategories = ref.watch(expenseCategoriesProvider);
    final incomeCategories = ref.watch(incomeCategoriesProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 700,
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

            // Tab bar
            _buildTabBar(isDark),
            const Divider(height: 1),

            // Content
            Expanded(
              child: _selectedTab == CategoryType.expense
                  ? _buildCategoryList(isDark, expenseCategories)
                  : _buildCategoryList(isDark, incomeCategories),
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
            'Manage Categories',
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

  Widget _buildTabBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceHighlight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: CategoryType.values.map((type) {
          final isSelected = _selectedTab == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (type == CategoryType.expense
                          ? AppColors.expense
                          : AppColors.income)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type == CategoryType.expense
                          ? LucideIcons.trendingDown
                          : LucideIcons.trendingUp,
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type == CategoryType.expense ? 'Expenses' : 'Income',
                      style: AppTypography.labelMedium(
                        isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryList(
    bool isDark,
    AsyncValue<List<CategoryEntity>> categoriesAsync,
  ) {
    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return ReorderableListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length + 1, // +1 for add button
          onReorder: (oldIndex, newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            if (oldIndex < categories.length && newIndex < categories.length) {
              _reorderCategories(categories, oldIndex, newIndex);
            }
          },
          itemBuilder: (context, index) {
            if (index == categories.length) {
              // Add button at the end
              return _buildAddButton(isDark, _selectedTab);
            }
            final category = categories[index];
            return _buildCategoryItem(
              isDark,
              category,
              index,
              categories.length,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
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
              'Error loading categories',
              style: AppTypography.bodyMedium(AppColors.accentRed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    bool isDark,
    CategoryEntity category,
    int index,
    int total,
  ) {
    final color = _parseHexColor(category.colorHex);
    final icon = _getIconData(category.iconName);

    return Opacity(
      key: ValueKey(category.id),
      opacity: category.isEnabled ? 1.0 : 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
          child: Icon(icon, size: 22, color: color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: AppTypography.titleMedium(
                  isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ),
            if (!category.isEnabled)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Disabled',
                  style: AppTypography.caption(
                    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
          ],
        ),
        subtitle: category.isDefault
            ? Text(
                'Default category',
                style: AppTypography.caption(
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enable/Disable toggle
            Tooltip(
              message: category.isEnabled ? 'Disable category' : 'Enable category',
              child: Switch(
                value: category.isEnabled,
                onChanged: (value) => _toggleCategoryEnabled(category, value),
                activeThumbColor: AppColors.income,
              ),
            ),
            const SizedBox(width: 8),
            // Reorder handle
            Icon(
              LucideIcons.gripVertical,
              size: 20,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
            const SizedBox(width: 8),
            // Edit button
            IconButton(
              onPressed: () => _editCategory(category),
              icon: Icon(
                LucideIcons.pencil,
                size: 18,
                color: AppColors.accentBlue,
              ),
              tooltip: 'Edit',
            ),
            // Delete button (now allowed for all categories)
            IconButton(
              onPressed: () => _deleteCategory(category),
              icon: Icon(
                LucideIcons.trash2,
                size: 18,
                color: AppColors.accentRed,
              ),
              tooltip: category.isDefault ? 'Delete default category' : 'Delete',
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAddButton(bool isDark, CategoryType type) {
    return Container(
      key: const ValueKey('add-button'),
      margin: const EdgeInsets.only(top: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _addCategory(type),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceHighlight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.3),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.plus,
                  size: 20,
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 12),
                Text(
                  'Add ${type == CategoryType.expense ? 'Expense' : 'Income'} Category',
                  style: AppTypography.labelMedium(AppColors.accentBlue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.folderX,
            size: 64,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No categories yet',
            style: AppTypography.titleMedium(
              isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first category to get started',
            style: AppTypography.bodySmall(
              isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addCategory(_selectedTab),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: Text('Add Category'),
          ),
        ],
      ),
    );
  }

  Future<void> _reorderCategories(
    List<CategoryEntity> categories,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex == newIndex) return;

    final reordered = List<CategoryEntity>.from(categories);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    // Update sort orders
    final categoriesDao = ref.read(categoriesDaoProvider);
    final orderedIds = reordered.map((c) => c.id).toList();
    await categoriesDao.reorderCategories(orderedIds);

    // Refresh the list
    setState(() {});
  }

  Future<void> _addCategory(CategoryType type) async {
    final result = await AddCategoryModal.show(
      context,
      defaultType: type,
    );
    // Category added silently
  }

  Future<void> _editCategory(CategoryEntity category) async {
    await AddCategoryModal.show(
      context,
      existingCategory: category,
    );
  }

  Future<void> _toggleCategoryEnabled(CategoryEntity category, bool enabled) async {
    try {
      final categoriesDao = ref.read(categoriesDaoProvider);
      await categoriesDao.updateCategoryById(
        category.id,
        CategoriesCompanion(isEnabled: Value(enabled)),
      );
      // Category enabled/disabled silently
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
                    'Error updating category: $e',
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
    }
  }

  Future<void> _deleteCategory(CategoryEntity category) async {
    // Check if category is used in transactions
    final transactionsDao = ref.read(transactionsDaoProvider);
    final transactions = await transactionsDao.getTransactionsByCategory(category.id);

    if (transactions.isNotEmpty) {
      // Show confirmation with usage count
      if (!mounted) return;
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete Category'),
          content: Text(
            'This category is used in ${transactions.length} transaction(s). '
            'Please reassign or delete those transactions first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Confirm deletion (with warning for default categories)
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category.isDefault ? 'Delete Default Category?' : 'Delete Category?'),
        content: Text(
          category.isDefault
              ? 'Are you sure you want to delete the default category "${category.name}"? '
                  'This action cannot be undone, and the category will not be automatically recreated.'
              : 'Are you sure you want to delete "${category.name}"? '
                  'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final categoriesDao = ref.read(categoriesDaoProvider);
        await categoriesDao.deleteCategory(category.id);

        // Category deleted silently
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
                      'Error deleting category: $e',
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
      }
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
      'briefcase': LucideIcons.briefcase,
      'laptop': LucideIcons.laptop,
      'trending-up': LucideIcons.trendingUp,
      'gift': LucideIcons.gift,
      'home': LucideIcons.home,
      'coffee': LucideIcons.coffee,
      'music': LucideIcons.music,
      'film': LucideIcons.film,
      'dumbbell': LucideIcons.dumbbell,
      'book': LucideIcons.book,
      'wallet': LucideIcons.wallet,
      'credit-card': LucideIcons.creditCard,
      'zap': LucideIcons.zap,
      'droplet': LucideIcons.droplet,
      'wifi': LucideIcons.wifi,
      'phone': LucideIcons.phone,
      'shirt': LucideIcons.shirt,
      'baby': LucideIcons.baby,
      'dog': LucideIcons.dog,
      'fuel': LucideIcons.fuel,
      'lightbulb': LucideIcons.lightbulb,
      'battery': LucideIcons.battery,
      'battery-charging': LucideIcons.batteryCharging,
      'plug': LucideIcons.plug,
      'plug-zap': LucideIcons.plugZap,
      'power': LucideIcons.power,
      'circle': LucideIcons.circle,
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

