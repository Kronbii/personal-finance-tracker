import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../../../data/drift/database.dart';
import '../../../../data/drift/tables/categories_table.dart';
import '../../../../data/providers/database_provider.dart';

/// Modal dialog for adding/editing categories
class AddCategoryModal extends ConsumerStatefulWidget {
  final CategoryEntity? existingCategory;
  final CategoryType? defaultType;

  const AddCategoryModal({
    super.key,
    this.existingCategory,
    this.defaultType,
  });

  @override
  ConsumerState<AddCategoryModal> createState() => _AddCategoryModalState();

  /// Show the modal as a dialog
  static Future<bool?> show(
    BuildContext context, {
    CategoryEntity? existingCategory,
    CategoryType? defaultType,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddCategoryModal(
        existingCategory: existingCategory,
        defaultType: defaultType,
      ),
    );
  }
}

class _AddCategoryModalState extends ConsumerState<AddCategoryModal> {
  final _nameController = TextEditingController();
  late CategoryType _selectedType;
  String _selectedIcon = 'circle';
  String _selectedColor = '#0A84FF';
  bool _isLoading = false;

  bool get _isEditing => widget.existingCategory != null;

  // Available icons for categories
  static const List<Map<String, dynamic>> availableIcons = [
    {'name': 'utensils', 'icon': LucideIcons.utensils},
    {'name': 'car', 'icon': LucideIcons.car},
    {'name': 'shopping-bag', 'icon': LucideIcons.shoppingBag},
    {'name': 'file-text', 'icon': LucideIcons.fileText},
    {'name': 'gamepad-2', 'icon': LucideIcons.gamepad2},
    {'name': 'heart-pulse', 'icon': LucideIcons.heartPulse},
    {'name': 'graduation-cap', 'icon': LucideIcons.graduationCap},
    {'name': 'plane', 'icon': LucideIcons.plane},
    {'name': 'briefcase', 'icon': LucideIcons.briefcase},
    {'name': 'laptop', 'icon': LucideIcons.laptop},
    {'name': 'trending-up', 'icon': LucideIcons.trendingUp},
    {'name': 'gift', 'icon': LucideIcons.gift},
    {'name': 'home', 'icon': LucideIcons.home},
    {'name': 'coffee', 'icon': LucideIcons.coffee},
    {'name': 'music', 'icon': LucideIcons.music},
    {'name': 'film', 'icon': LucideIcons.film},
    {'name': 'dumbbell', 'icon': LucideIcons.dumbbell},
    {'name': 'book', 'icon': LucideIcons.book},
    {'name': 'wallet', 'icon': LucideIcons.wallet},
    {'name': 'credit-card', 'icon': LucideIcons.creditCard},
    {'name': 'circle', 'icon': LucideIcons.circle},
  ];

  // Available colors
  static const List<String> availableColors = [
    '#FF9F0A', // Orange
    '#0A84FF', // Blue
    '#BF5AF2', // Purple
    '#FF375F', // Pink
    '#64D2FF', // Teal
    '#FF453A', // Red
    '#5E5CE6', // Indigo
    '#30D158', // Green
    '#FFD60A', // Yellow
    '#8E8E93', // Gray
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final category = widget.existingCategory!;
      _nameController.text = category.name;
      _selectedType = category.type;
      _selectedIcon = category.iconName;
      _selectedColor = category.colorHex;
    } else {
      _selectedType = widget.defaultType ?? CategoryType.expense;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
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
                    // Category type selector
                    _buildTypeSelector(isDark),
                    const SizedBox(height: 24),

                    // Name field
                    _buildNameField(isDark),
                    const SizedBox(height: 24),

                    // Icon picker
                    _buildIconPicker(isDark),
                    const SizedBox(height: 24),

                    // Color picker
                    _buildColorPicker(isDark),
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
            _isEditing ? 'Edit Category' : 'Add Category',
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
          'Category Type',
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
            children: CategoryType.values.map((type) {
              final isSelected = _selectedType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getTypeColor(type)
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
                          type == CategoryType.expense ? 'Expense' : 'Income',
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
        ),
      ],
    );
  }

  Widget _buildNameField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Name',
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
            hintText: 'e.g., Food, Salary, Rent',
            hintStyle: AppTypography.bodyMedium(
              isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
            prefixIcon: Icon(
              _getIconData(_selectedIcon),
              size: 20,
              color: _parseHexColor(_selectedColor),
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildIconPicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icon',
          style: AppTypography.labelMedium(
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: availableIcons.map((iconData) {
            final iconName = iconData['name'] as String;
            final isSelected = _selectedIcon == iconName;
            final icon = iconData['icon'] as IconData;

            return GestureDetector(
              onTap: () => setState(() => _selectedIcon = iconName),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? _parseHexColor(_selectedColor).withValues(alpha: 0.2)
                      : (isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurfaceHighlight),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? _parseHexColor(_selectedColor)
                        : Colors.transparent,
                    width: isSelected ? 2 : 0,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? _parseHexColor(_selectedColor)
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorPicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: AppTypography.labelMedium(
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: availableColors.map((colorHex) {
            final isSelected = _selectedColor == colorHex;
            final color = _parseHexColor(colorHex);

            return GestureDetector(
              onTap: () => setState(() => _selectedColor = colorHex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : Colors.transparent,
                    width: isSelected ? 3 : 0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
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
                          size: 20,
                        ),
                      )
                    : null,
              ),
            );
          }).toList(),
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
              onPressed: _isLoading ? null : _saveCategory,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(_isEditing ? 'Update Category' : 'Add Category'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategory() async {
    // Validate
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter a category name');
      return;
    }

    // Check for duplicate name
    final categoriesDao = ref.read(categoriesDaoProvider);
    final nameExists = await categoriesDao.categoryNameExists(
      _nameController.text.trim(),
      _selectedType,
      excludeId: _isEditing ? widget.existingCategory!.id : null,
    );

    if (nameExists) {
      _showError('A category with this name already exists');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        // Update existing category
        await categoriesDao.updateCategoryById(
          widget.existingCategory!.id,
          CategoriesCompanion(
            name: Value(_nameController.text.trim()),
            type: Value(_selectedType),
            iconName: Value(_selectedIcon),
            colorHex: Value(_selectedColor),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        // Get next sort order
        final categories = await categoriesDao.getCategoriesByType(_selectedType);
        final nextSortOrder = categories.length;

        // Insert new category
        await categoriesDao.insertCategory(
          CategoriesCompanion.insert(
            id: const Uuid().v4(),
            name: _nameController.text.trim(),
            type: _selectedType,
            iconName: Value(_selectedIcon),
            colorHex: Value(_selectedColor),
            sortOrder: Value(nextSortOrder),
            isDefault: const Value(false),
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showError('Failed to save category: $e');
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
            const Icon(
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

  Color _getTypeColor(CategoryType type) {
    return type == CategoryType.expense
        ? AppColors.expense
        : AppColors.income;
  }

  IconData _getIconData(String iconName) {
    final iconData = availableIcons.firstWhere(
      (icon) => icon['name'] == iconName,
      orElse: () => availableIcons.first,
    );
    return iconData['icon'] as IconData;
  }

  Color _parseHexColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return AppColors.accentBlue;
  }
}

