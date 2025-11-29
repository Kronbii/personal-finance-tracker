import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../data/services/currency_formatter.dart';

/// Data class for line chart points
class ChartDataPoint {
  final DateTime date;
  final double value;

  ChartDataPoint({required this.date, required this.value});
}

/// Premium line chart widget for trend visualization
class PremiumLineChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final Color lineColor;
  final Color gradientColor;
  final String title;
  final bool isDark;
  final double height;
  final bool showDots;
  final bool showGrid;

  const PremiumLineChart({
    super.key,
    required this.data,
    this.lineColor = AppColors.accentBlue,
    Color? gradientColor,
    this.title = '',
    this.isDark = true,
    this.height = 200,
    this.showDots = true,
    this.showGrid = true,
  }) : gradientColor = gradientColor ?? lineColor;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState();
    }

    final minY = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxY = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    
    // Handle edge case where all values are the same
    final range = maxY - minY;
    final safeRange = range == 0 ? 1.0 : range; // Use 1.0 as default range if all values are same
    final padding = safeRange * 0.1;
    
    // Calculate safe interval (never zero)
    final interval = safeRange / 4;
    final safeInterval = interval == 0 ? 1.0 : interval;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: AppTypography.titleLarge(
                isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 20),
          ],
          SizedBox(
            height: height,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: showGrid,
                  drawVerticalLine: false,
                  horizontalInterval: safeInterval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? AppColors.darkDivider
                        : AppColors.lightDivider,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: safeInterval,
                      getTitlesWidget: (value, meta) => Text(
                        _formatCompact(value),
                        style: AppTypography.caption(
                          isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('MMM').format(data[index].date),
                            style: AppTypography.caption(
                              isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: range == 0 ? minY - 0.5 : minY - padding,
                maxY: range == 0 ? maxY + 0.5 : maxY + padding,
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.value,
                      );
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: showDots,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: lineColor,
                          strokeWidth: 2,
                          strokeColor: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          gradientColor.withValues(alpha: 0.3),
                          gradientColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) =>
                        isDark ? AppColors.darkSurfaceHighlight : AppColors.lightSurface,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        final date = data[index].date;
                        return LineTooltipItem(
                          '${DateFormat('MMM yyyy').format(date)}\n',
                          AppTypography.caption(
                            isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: _formatCurrency(spot.y),
                              style: AppTypography.moneySmall(lineColor),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState() {
    return Container(
      height: height + 80,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          'No data available',
          style: AppTypography.bodyMedium(
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }

  String _formatCompact(double value) {
    return CurrencyFormatter.formatCompact(value, currencyCode: 'USD');
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.format(amount, currencyCode: 'USD');
  }
}

