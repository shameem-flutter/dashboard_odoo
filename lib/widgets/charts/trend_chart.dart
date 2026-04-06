import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/trend_model.dart';
import '../../providers/riverpod_providers.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class _ChartColors {
  static const titleDark = Color(0xFFF4F6FF);
  static const titleLight = Color(0xFF1F2937);
  static const revenueColor = Color(0xFF0000FF); // Blue
  static const profitColor = Color(0xFF008000); // Green
  static const lightBorder = Color(0xFFE8EAF5);
}

class TrendChart extends ConsumerStatefulWidget {
  const TrendChart({super.key});

  @override
  ConsumerState<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends ConsumerState<TrendChart> {
  bool _showRevenue = true;
  bool _showProfit = true;

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(trendProvider);
    const isDark = false; // Forced Light Mode

    return asyncData.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (data) {
        final hasData = data != null && data.isNotEmpty;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _ChartColors.lightBorder, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ChartHeader(isDark: isDark),
              if (hasData) ...[
                const SizedBox(height: 16),
                _LegendRow(
                  showRevenue: _showRevenue,
                  showProfit: _showProfit,
                  onToggleRevenue: () =>
                      setState(() => _showRevenue = !_showRevenue),
                  onToggleProfit: () =>
                      setState(() => _showProfit = !_showProfit),
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _LineChartWidget(
                    data: data,
                    showRevenue: _showRevenue,
                    showProfit: _showProfit,
                    isDark: isDark,
                  ),
                ),
              ] else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No data available for the selected filters',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ChartHeader extends StatelessWidget {
  final bool isDark;

  const _ChartHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // const Text('📈', style: TextStyle(fontSize: 22)),
        // const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Monthly Trend',
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? _ChartColors.titleDark : _ChartColors.titleLight,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final bool showRevenue;
  final bool showProfit;
  final VoidCallback onToggleRevenue;
  final VoidCallback onToggleProfit;
  final bool isDark;

  const _LegendRow({
    required this.showRevenue,
    required this.showProfit,
    required this.onToggleRevenue,
    required this.onToggleProfit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          label: 'Revenue',
          color: _ChartColors.revenueColor,
          isActive: showRevenue,
          onTap: onToggleRevenue,
          isDark: isDark,
        ),
        const SizedBox(width: 24),
        _LegendItem(
          label: 'Profit',
          color: _ChartColors.profitColor,
          isActive: showProfit,
          onTap: onToggleProfit,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _LegendItem({
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 16,
            decoration: BoxDecoration(
              color: isActive
                  ? color.withValues(alpha: 0.1)
                  : Colors.transparent,
              border: Border.all(
                color: isActive ? color : Colors.grey.withValues(alpha: 0.5),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? (isDark ? Colors.white : Colors.black87)
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  final List<TrendModel> data;
  final bool showRevenue;
  final bool showProfit;
  final bool isDark;

  const _LineChartWidget({
    required this.data,
    required this.showRevenue,
    required this.showProfit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    double minY = 0;
    double maxY = 0;

    bool hasData = false;
    for (var d in data) {
      if (showRevenue) {
        if (d.revenue < minY) minY = d.revenue;
        if (d.revenue > maxY) maxY = d.revenue;
        hasData = true;
      }
      if (showProfit) {
        if (d.profit < minY) minY = d.profit;
        if (d.profit > maxY) maxY = d.profit;
        hasData = true;
      }
    }

    if (!hasData) {
      maxY = 1000;
      minY = 0;
    } else {
      // Round to "nice" numbers for cleaner axis
      final range = maxY - minY;
      double step;
      if (range > 1000000) {
        step = 500000;
      } else if (range > 100000) {
        step = 50000;
      } else if (range > 10000) {
        step = 5000;
      } else {
        step = 1000;
      }

      maxY = (maxY / step).ceil() * step;
      minY = (minY / step).floor() * step;

      // Add one more step if they are too close to data points
      if (maxY - minY == 0) {
        maxY += step;
        minY -= step;
      }
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.white10 : Colors.black12,
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: isDark ? Colors.white10 : Colors.black12,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false, reservedSize: 12),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 80,
              getTitlesWidget: (value, meta) {
                // Ensure we only show labels on "nice" steps to match the grid
                // This prevents the messy exact min/max labels shown in the user's issue
                final range = meta.max - meta.min;
                double step;
                if (range > 1000000) {
                  step = 500000;
                } else if (range > 100000) {
                  step = 50000;
                } else if (range > 10000) {
                  step = 5000;
                } else {
                  step = 1000;
                }

                // If the value is not a multiple of the step, don't show it
                // We use a small epsilon for double comparison
                if ((value % step).abs() > 0.01 &&
                    (value % step).abs() < step - 0.01) {
                  return const SizedBox.shrink();
                }

                return SideTitleWidget(
                  meta: meta,
                  space: 10,
                  child: Text(
                    _formatNumber(value),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white24 : Colors.black12,
              width: 1,
            ),
            left: BorderSide(
              color: isDark ? Colors.white24 : Colors.black12,
              width: 1,
            ),
          ),
        ),
        lineBarsData: [
          if (showRevenue)
            LineChartBarData(
              spots: data
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.revenue))
                  .toList(),
              isCurved: true,
              color: _ChartColors.revenueColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: _ChartColors.revenueColor,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
          if (showProfit)
            LineChartBarData(
              spots: data
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.profit))
                  .toList(),
              isCurved: true,
              color: _ChartColors.profitColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: _ChartColors.profitColor,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) =>
                isDark ? const Color(0xFF1A1E33) : Colors.white,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                String dateLabel = data[index].month;
                try {
                  final date = DateTime.parse('${data[index].month}-01');
                  dateLabel = DateFormat("MMM ''yy").format(date);
                } catch (e) {
                  // Keep original
                }

                // Determine which category (Revenue or Profit) this spot belongs to
                // We check against the visible datasets
                String category = "";
                if (showRevenue && showProfit) {
                  category = spot.barIndex == 0 ? "Revenue" : "Profit";
                } else if (showRevenue) {
                  category = "Revenue";
                } else if (showProfit) {
                  category = "Profit";
                }

                return LineTooltipItem(
                  '$dateLabel\n',
                  const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10,
                    fontWeight: FontWeight.normal,
                  ),
                  children: [
                    if (category.isNotEmpty)
                      TextSpan(
                        text: '$category: ',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    TextSpan(
                      text: NumberFormat.currency(symbol: '\$').format(spot.y),
                      style: TextStyle(
                        color: spot.bar.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == 0) return '0';
    return NumberFormat.decimalPattern().format(value.toInt());
  }
}
