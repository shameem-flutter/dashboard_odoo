import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/riverpod_providers.dart';
import '../../models/pnl_by_store_model.dart';

class PnlByStoreChart extends ConsumerStatefulWidget {
  const PnlByStoreChart({super.key});

  @override
  ConsumerState<PnlByStoreChart> createState() => _PnlByStoreChartState();
}

class _PnlByStoreChartState extends ConsumerState<PnlByStoreChart> {
  String selectedMetric = 'Profit';

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(pnlByStoreProvider);
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
        final hasData = rawData != null && rawData.detailed.isNotEmpty;
        final details = hasData ? rawData.detailed : <DetailedPnlByStore>[];

        double maxVal = 0;
        double minVal = 0;

        if (hasData) {
          for (final item in details) {
            double val;
            if (selectedMetric == 'Revenue') {
              val = item.revenue;
            } else if (selectedMetric == 'Cost') {
              val = item.cost;
            } else {
              val = item.profit;
            }
            if (val > maxVal) {
              maxVal = val;
            }
            if (val < minVal) {
              minVal = val;
            }
          }
        }

        double maxY = maxVal == 0 ? (minVal < 0 ? 0 : 10) : maxVal * 1.2;
        double minY = minVal == 0 ? (maxVal > 0 ? 0 : -10) : minVal * 1.2;
        if (maxY == minY) {
          maxY += 10;
        }

        final Color barColor = const Color(0xFF0EA5E9); // Light Blue

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8EAF5)),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // const Text('🏪', style: TextStyle(fontSize: 18)),
                      // const SizedBox(width: 8),
                      Text(
                        'P&L by Store ($selectedMetric)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1D2E),
                        ),
                      ),
                    ],
                  ),
                  // Dropdown
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMetric,
                        dropdownColor: Colors.white,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.black87,
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        items: ['Profit', 'Revenue', 'Cost'].map((String val) {
                          return DropdownMenuItem<String>(
                            value: val,
                            child: Text(val),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedMetric = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Legend ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 10,
                    decoration: BoxDecoration(color: barColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedMetric,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF4B5563),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Expanded(
                child: hasData
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final int barCount = details.length;
                          double dynamicWidth = barCount > 0
                              ? (constraints.maxWidth / barCount) * 0.4
                              : 36.0;
                          if (dynamicWidth > 48) {
                            dynamicWidth = 48.0;
                          }
                          if (dynamicWidth < 12) {
                            dynamicWidth = 12.0;
                          }

                          final int skipCount = barCount > 8
                              ? (barCount / 8).ceil()
                              : 1;

                          return BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxY,
                              minY: minY,
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (group) => Colors.white,
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                        final item = details[groupIndex];
                                        return BarTooltipItem(
                                          '${item.name}\n',
                                          TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          children: [
                                            TextSpan(
                                              text:
                                                  '$selectedMetric: ${_formatValue(rod.toY)}',
                                              style: TextStyle(
                                                color: rod.color,
                                                fontWeight: FontWeight.w600,
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
                                    reservedSize: 64,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= details.length) {
                                        return const SizedBox.shrink();
                                      }

                                      if (idx % skipCount != 0 &&
                                          idx != details.length - 1) {
                                        return const SizedBox.shrink();
                                      }

                                      return SideTitleWidget(
                                        meta: meta,
                                        space: 12,
                                        child: Transform.rotate(
                                          angle: -0.3,
                                          child: Text(
                                            details[idx].name,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: const Color(0xFF64748B),
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
                                    reservedSize: 68,
                                    getTitlesWidget: (value, meta) {
                                      if (value == meta.max ||
                                          value == meta.min) {
                                        if (value != 0) {
                                          return const SizedBox.shrink();
                                        }
                                      }
                                      return SideTitleWidget(
                                        meta: meta,
                                        space: 8,
                                        child: Text(
                                          _formatValue(value),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: value == 0
                                      ? (Colors.black26)
                                      : (const Color(0xFFEFF0F6)),
                                  strokeWidth: value == 0 ? 1.5 : 1,
                                ),
                                getDrawingVerticalLine: (value) => FlLine(
                                  color: const Color(0xFFEFF0F6),
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(
                                  color: const Color(0xFFE8EAF5),
                                ),
                              ),
                              barGroups: List.generate(details.length, (index) {
                                double val;
                                if (selectedMetric == 'Revenue') {
                                  val = details[index].revenue;
                                } else if (selectedMetric == 'Cost') {
                                  val = details[index].cost;
                                } else {
                                  val = details[index].profit;
                                }

                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: val,
                                      color: barColor,
                                      width: dynamicWidth,
                                      borderRadius: BorderRadius.zero,
                                    ),
                                  ],
                                );
                              }),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          'No P&L by Store data available',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              // ── Footer Export Buttons ──
              Row(
                children: [
                  _ExportButton(
                    icon: Icons.description,
                    label: 'Export PDF',
                    color: Colors.white,
                    backgroundColor: const Color(0xFF3B82F6),
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _ExportButton(
                    icon: Icons.table_chart,
                    label: 'Export Excel',
                    color: Colors.white,
                    backgroundColor: const Color(0xFF22C55E),
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatValue(double v) {
    if (v == 0) {
      return '0';
    }
    final absVal = v.abs();
    String formatted = absVal
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    if (v < 0) {
      formatted = '-$formatted';
    }
    return formatted;
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
