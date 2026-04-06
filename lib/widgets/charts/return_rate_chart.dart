import 'package:flutter/material.dart';
import '../../models/return_rate_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart';

import 'package:google_fonts/google_fonts.dart';

class ReturnRateChart extends ConsumerStatefulWidget {
  const ReturnRateChart({super.key});

  @override
  ConsumerState<ReturnRateChart> createState() => _ReturnRateChartState();
}

class _ReturnRateChartState extends ConsumerState<ReturnRateChart> {
  bool showSales = true;
  bool showReturns = true;

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(returnRateProvider);
    const isDark = false; // Forced Light Mode

    return asyncData.when(
      skipLoadingOnReload: true,
      loading: () => const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) =>
          SizedBox(height: 300, child: Center(child: Text('Error: $e'))),
      data: (rawData) {
        final hasData =
            rawData != null &&
            rawData.labels.isNotEmpty &&
            rawData.datasets.isNotEmpty;

        // Colors: Sales (Greenish-Blue), Returns (Reddish)
        const salesColor = Color(0xFF4F6EF7);
        const returnsColor = Color(0xFFEF4444);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8EAF5)),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Sales vs Returns',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1D2E),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Monthly sales vs returns volume',
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFFAAAEC8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: hasData
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final int barCount = rawData.labels.length;
                          double dynamicWidth = barCount > 0
                              ? (constraints.maxWidth / barCount) * 0.4
                              : 10.0;
                          if (dynamicWidth > 10) dynamicWidth = 10.0;
                          if (dynamicWidth < 2) dynamicWidth = 2.0;

                          final int skipCount = barCount > 6
                              ? (barCount / 6).ceil()
                              : 1;

                          return BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _calculateMaxY(rawData.datasets),
                              minY: _calculateMinY(rawData.datasets),
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (group) => Colors.white,
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                        String datasetLabel = '';
                                        if (showSales && showReturns) {
                                          datasetLabel =
                                              rawData.datasets[rodIndex].label;
                                        } else if (showSales) {
                                          datasetLabel = 'Sales';
                                        } else if (showReturns) {
                                          datasetLabel = 'Returns';
                                        }

                                        final dateLabel = _formatLabel(
                                          rawData.labels[group.x.toInt()],
                                        );

                                        return BarTooltipItem(
                                          '$dateLabel\n',
                                          const TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 10,
                                            fontWeight: FontWeight.normal,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: '$datasetLabel: ',
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  '\$${rod.toY.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                color: rod.color,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
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
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize:
                                        56, // ← increased for rotated text
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 ||
                                          idx >= rawData.labels.length) {
                                        return const SizedBox.shrink();
                                      }

                                      if (idx % skipCount != 0 &&
                                          idx != rawData.labels.length - 1) {
                                        return const SizedBox.shrink();
                                      }

                                      String label = _formatLabel(
                                        rawData.labels[idx],
                                      );

                                      // ✅ Wrap with SideTitleWidget for proper axis anchoring
                                      return SideTitleWidget(
                                        meta:
                                            meta, // ← anchors label to correct bar position
                                        space: 4,
                                        child: Transform.rotate(
                                          angle: -0.6,
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: const Color(0xFF6B7280),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.visible,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) {
                                      return SideTitleWidget(
                                        meta: meta,
                                        space: 4,
                                        child: Text(
                                          _formatAmount(value),
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                checkToShowHorizontalLine: (value) =>
                                    value != 0,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: const Color(0xFFE5E7EB),
                                  strokeWidth: 1,
                                ),
                                drawVerticalLine: false,
                                getDrawingVerticalLine: (value) => FlLine(
                                  color: const Color(0xFFE5E7EB),
                                  strokeWidth: 1,
                                ),
                              ),
                              extraLinesData: ExtraLinesData(
                                horizontalLines: [
                                  HorizontalLine(
                                    y: 0,
                                    color: const Color(0xFFE5E7EB),
                                    strokeWidth: 1,
                                  ),
                                ],
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: List.generate(rawData.labels.length, (
                                index,
                              ) {
                                List<BarChartRodData> rods = [];
                                if (showSales && rawData.datasets.isNotEmpty) {
                                  rods.add(
                                    BarChartRodData(
                                      toY:
                                          rawData.datasets[0].data.length >
                                              index
                                          ? rawData.datasets[0].data[index]
                                          : 0,
                                      color: salesColor,
                                      width: dynamicWidth,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  );
                                }
                                if (showReturns &&
                                    rawData.datasets.length > 1) {
                                  rods.add(
                                    BarChartRodData(
                                      toY:
                                          rawData.datasets[1].data.length >
                                              index
                                          ? rawData.datasets[1].data[index]
                                          : 0,
                                      color: returnsColor,
                                      width: dynamicWidth,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  );
                                }

                                return BarChartGroupData(
                                  x: index,
                                  barRods: rods,
                                  barsSpace: 4,
                                );
                              }),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          'No return rate data available',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(
                    'Sales',
                    salesColor,
                    isDark,
                    showSales,
                    () => setState(() => showSales = !showSales),
                  ),
                  const SizedBox(width: 20),
                  _buildLegendItem(
                    'Returns',
                    returnsColor,
                    isDark,
                    showReturns,
                    () => setState(() => showReturns = !showReturns),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(
    String label,
    Color color,
    bool isDark,
    bool isActive,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isActive ? color : color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? (isDark
                          ? const Color(0xFFDDE0F5)
                          : const Color(0xFF1A1D2E))
                    : (isDark
                          ? const Color(0xFF3E4470)
                          : const Color(0xFFAAAEC8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateMaxY(List<ReturnRateDataset> datasets) {
    double max = 0;
    bool hasVisibleData = false;
    for (var dataset in datasets) {
      if ((dataset.label == 'Sales' && !showSales) ||
          (dataset.label == 'Returns' && !showReturns)) {
        continue;
      }
      hasVisibleData = true;
      for (var val in dataset.data) {
        if (val > max) max = val;
      }
    }
    return !hasVisibleData || max == 0 ? 100 : (max * 1.15).ceilToDouble();
  }

  double _calculateMinY(List<ReturnRateDataset> datasets) {
    double min = 0;
    bool hasNegative = false;
    bool hasVisibleData = false;
    for (var dataset in datasets) {
      if ((dataset.label == 'Sales' && !showSales) ||
          (dataset.label == 'Returns' && !showReturns)) {
        continue;
      }
      hasVisibleData = true;
      for (var val in dataset.data) {
        if (val < min) {
          min = val;
          hasNegative = true;
        }
      }
    }
    if (!hasVisibleData) return 0;
    if (!hasNegative) return 0;
    return (min * 1.15).floorToDouble();
  }

  String _formatAmount(double value) {
    if (value == 0) return '0';
    final absVal = value.abs();
    String formatted = absVal
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return value < 0 ? '-$formatted' : formatted;
  }

  String _formatLabel(String label) {
    if (label.contains('-')) {
      final parts = label.split('-');
      if (parts.length >= 2 && parts[0].length == 4) {
        final year = parts[0].substring(2);
        final month = int.tryParse(parts[1]);
        if (month != null && month >= 1 && month <= 12) {
          const monthNames = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
          return '${monthNames[month - 1]} \'$year';
        }
      }
    } else if (label.contains(' 20') && label.length >= 8) {
      return label.replaceFirst(' 20', ' \'');
    }
    return label;
  }
}
