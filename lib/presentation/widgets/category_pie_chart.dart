import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Data class for pie chart sections
class CategoryChartData {
  final String id;
  final String name;
  final double amount;
  final Color color;
  final String iconName;

  CategoryChartData({
    required this.id,
    required this.name,
    required this.amount,
    required this.color,
    this.iconName = 'circle',
  });
}

/// Premium pie chart for category breakdown
/// Shows spending distribution with animated sections
class CategoryPieChart extends StatefulWidget {
  final List<CategoryChartData> data;
  final double totalAmount;
  final bool isDark;
  final String centerLabel;
  final String centerValue;
  final bool showContainer;
  final bool showLegend;

  const CategoryPieChart({
    super.key,
    required this.data,
    required this.totalAmount,
    this.isDark = true,
    this.centerLabel = 'Total',
    this.centerValue = '',
    this.showContainer = true,
    this.showLegend = true,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return _buildEmptyState();
    }

    // If showContainer is false, just return the chart content
    if (!widget.showContainer) {
      return _buildChartOnly();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Breakdown',
            style: AppTypography.titleLarge(
              widget.isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Pie Chart
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 200,
                  child: _buildPieChartWithCenter(),
                ),
              ),
              if (widget.showLegend) ...[
                const SizedBox(width: 24),
                // Legend
                Expanded(
                  flex: 2,
                  child: _buildLegend(),
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildChartOnly() {
    return _buildPieChartWithCenter();
  }

  Widget _buildPieChartWithCenter() {
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    touchedIndex = -1;
                    return;
                  }
                  touchedIndex = pieTouchResponse
                      .touchedSection!.touchedSectionIndex;
                });
              },
            ),
            startDegreeOffset: -90,
            borderData: FlBorderData(show: false),
            sectionsSpace: 2,
            centerSpaceRadius: 50,
            sections: _buildSections(),
          ),
        ),
        // Center content
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.centerLabel,
              style: AppTypography.caption(
                widget.isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.centerValue.isEmpty
                  ? _formatAmount(widget.totalAmount)
                  : widget.centerValue,
              style: AppTypography.moneySmall(
                widget.isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections() {
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == touchedIndex;
      final percentage = (data.amount / widget.totalAmount * 100);

      return PieChartSectionData(
        color: data.color,
        value: data.amount,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 50 : 40,
        titleStyle: AppTypography.labelSmall(Colors.white),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }

  Widget _buildLegend() {
    // Sort by amount and take top 5
    final sortedData = List<CategoryChartData>.from(widget.data)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final displayData = sortedData.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...displayData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return _buildLegendItem(data, index);
        }),
        if (widget.data.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+${widget.data.length - 5} more',
              style: AppTypography.caption(
                widget.isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLegendItem(CategoryChartData data, int index) {
    final percentage = (data.amount / widget.totalAmount * 100);
    final isHighlighted = index == touchedIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() {
          touchedIndex = touchedIndex == index ? -1 : index;
        }),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isHighlighted
                ? data.color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: data.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  data.name,
                  style: AppTypography.bodySmall(
                    widget.isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: AppTypography.labelSmall(
                  widget.isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Breakdown',
            style: AppTypography.titleLarge(
              widget.isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 64,
                  color: widget.isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No data available',
                  style: AppTypography.bodyMedium(
                    widget.isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add transactions to see breakdown',
                  style: AppTypography.caption(
                    widget.isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\$${amount.toStringAsFixed(2)}';
  }
}

