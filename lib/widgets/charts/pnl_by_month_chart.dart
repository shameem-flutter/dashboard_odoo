import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/pnl_by_month_model.dart';
import '../../providers/riverpod_providers.dart';

// ── Constants ────────────────────────────────────────────────────────────────

abstract class _PnlChartColors {
  static const background = Color(0xFF0E1120);
  static const border = Color(0xFF1A1E33);
  static const titleDark = Color(0xFFF4F6FF);
  static const titleLight = Color(0xFF1F2937);
  static const exportBlue = Color(0xFF2563EB);
  static const exportGreen = Color(0xFF16A34A);
  static const datasetRevenue = Color(0xFF3B82F6);
  static const datasetCost = Color(0xFFEF4444);
  static const datasetProfit = Color(0xFF10B981);
  static const lightBorder = Color(0xFFE8EAF5);
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Color _colorForLabel(String label) {
  final l = label.toLowerCase();
  if (l.contains('revenue')) {
    return _PnlChartColors.datasetRevenue;
  }
  if (l.contains('cost')) {
    return _PnlChartColors.datasetCost;
  }
  if (l.contains('profit')) {
    return _PnlChartColors.datasetProfit;
  }
  return Colors.blue;
}

String _yAxisLabel(double v) {
  return NumberFormat.decimalPattern().format(v);
}

// ── Main Dashboard Widget ───────────────────────────────────────────────────

class PnlByMonth extends ConsumerStatefulWidget {
  const PnlByMonth({super.key});

  @override
  ConsumerState<PnlByMonth> createState() => _PnlByMonthState();
}

class _PnlByMonthState extends ConsumerState<PnlByMonth> {
  final Set<String> _hiddenDatasets = {};

  void _toggleDataset(String label) {
    setState(() {
      if (_hiddenDatasets.contains(label)) {
        _hiddenDatasets.remove(label);
      } else {
        // Optional: Ensure at least one dataset stays visible
        if (_hiddenDatasets.length < 2) {
          _hiddenDatasets.add(label);
        } else if (_hiddenDatasets.length == 2 &&
            !_hiddenDatasets.contains(label)) {
          // If 2 are hidden and this is the 3rd, don't hide it so chart doesn't go empty
          // Or we can just let it hide. Let's let them hide it if they really want an empty chart,
          // but to be safe, let's keep at least one visible.
          // Wait, simple toggle is usually better.
          _hiddenDatasets.add(label);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(pnlByMonthProvider);
    const isDark = false; // Forced Light Mode

    return asyncData.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error: $e'),
      data: (rawData) {
        final hasData = rawData != null && rawData.labels.isNotEmpty;

        return _ChartCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ChartHeader(isDark: isDark),
              const SizedBox(height: 16),
              _LegendRow(
                isDark: isDark,
                hiddenDatasets: _hiddenDatasets,
                onToggle: _toggleDataset,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: hasData
                    ? _StoreLineChart(
                        isDark: isDark,
                        data: rawData,
                        hiddenDatasets: _hiddenDatasets,
                      )
                    : Center(
                        child: Text(
                          'No P&L data available',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              _ExportRow(),
            ],
          ),
        );
      },
    );
  }
}

// ── Card Shell ───────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? _PnlChartColors.background : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? _PnlChartColors.border : _PnlChartColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _ChartHeader extends StatelessWidget {
  final bool isDark;

  const _ChartHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // const Text('💰', style: TextStyle(fontSize: 22)),
        // const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Net P&L by Month',
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? _PnlChartColors.titleDark
                  : _PnlChartColors.titleLight,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Legend ───────────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  final bool isDark;
  final Set<String> hiddenDatasets;
  final ValueChanged<String> onToggle;

  const _LegendRow({
    required this.isDark,
    required this.hiddenDatasets,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          label: 'Revenue',
          color: _PnlChartColors.datasetRevenue,
          isDark: isDark,
          isFaded: hiddenDatasets.contains('Revenue'),
          onTap: () => onToggle('Revenue'),
        ),
        const SizedBox(width: 12),
        _LegendItem(
          label: 'Cost',
          color: _PnlChartColors.datasetCost,
          isDark: isDark,
          isFaded: hiddenDatasets.contains('Cost'),
          onTap: () => onToggle('Cost'),
        ),
        const SizedBox(width: 12),
        _LegendItem(
          label: 'Profit',
          color: _PnlChartColors.datasetProfit,
          isDark: isDark,
          isFaded: hiddenDatasets.contains('Profit'),
          onTap: () => onToggle('Profit'),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  final bool isFaded;
  final VoidCallback onTap;

  const _LegendItem({
    required this.label,
    required this.color,
    required this.isDark,
    required this.isFaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = isFaded ? Colors.grey.withValues(alpha: 0.4) : color;
    final textColor = isFaded
        ? Colors.grey.withValues(alpha: 0.6)
        : (isDark ? Colors.white70 : const Color(0xFF6B7280));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 14,
              decoration: BoxDecoration(
                color: displayColor.withValues(alpha: 0.15),
                border: Border.all(color: displayColor, width: 2.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Line Chart ───────────────────────────────────────────────────────────────

class _StoreLineChart extends StatelessWidget {
  const _StoreLineChart({
    required this.isDark,
    required this.data,
    required this.hiddenDatasets,
  });

  final bool isDark;
  final PnlByMonthModel data;
  final Set<String> hiddenDatasets;

  @override
  Widget build(BuildContext context) {
    final visibleDatasets = data.datasets
        .where((d) => !hiddenDatasets.contains(d.label))
        .toList();

    final double maxY = _calculateMax(visibleDatasets);
    final double minY = _calculateMin(visibleDatasets);

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) =>
                isDark ? const Color(0xFF1E293B) : Colors.white,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final dataset = visibleDatasets[spot.barIndex];
                final value = spot.y;
                final index = spot.x.toInt();
                String label = '';
                if (index >= 0 && index < data.labels.length) {
                  label = data.labels[index];
                }

                String displayDate = label;
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
                      displayDate = '${monthNames[month - 1]} \'$year';
                    }
                  }
                }

                return LineTooltipItem(
                  '$displayDate\n${dataset.label}: ${_yAxisLabel(value)}',
                  TextStyle(
                    color: _colorForLabel(dataset.label),
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
        maxY: maxY,
        minY: minY < 0 ? minY : 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (v) => FlLine(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (v) => FlLine(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1),
              width: 1,
            ),
            left: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1),
              width: 1,
            ),
            top: BorderSide.none,
            right: BorderSide.none,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: data.labels.length > 8
                  ? (data.labels.length / 6).ceilToDouble()
                  : 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.labels.length) {
                  return const SizedBox.shrink();
                }

                String label = data.labels[i];
                // Try to format "2024-01" as "Jan '24" for compactness
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
                      label = '${monthNames[month - 1]} \'$year';
                    }
                  }
                }

                return SideTitleWidget(
                  meta: meta,
                  space: 12,
                  child: Transform.rotate(
                    angle: -0.5,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10, // Slightly smaller text for fit
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 75,
              getTitlesWidget: (value, meta) => Text(
                _yAxisLabel(value),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
          ),
        ),
        lineBarsData: visibleDatasets.map((dataset) {
          return LineChartBarData(
            spots: List.generate(data.labels.length, (i) {
              return FlSpot(i.toDouble(), dataset.data[i]);
            }),
            isCurved: true,
            color: _colorForLabel(dataset.label),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: isDark ? _PnlChartColors.background : Colors.white,
                  strokeWidth: 2,
                  strokeColor: barData.color ?? Colors.blue,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          );
        }).toList(),
      ),
    );
  }

  double _calculateMax(List<PnlByMonthDataset> datasets) {
    double max = 0;
    for (var d in datasets) {
      for (var v in d.data) {
        if (v > max) max = v;
      }
    }
    return max == 0 ? 100 : (max * 1.2).ceilToDouble();
  }

  double _calculateMin(List<PnlByMonthDataset> datasets) {
    double min = 0;
    for (var d in datasets) {
      for (var v in d.data) {
        if (v < min) min = v;
      }
    }
    return min >= 0 ? 0 : (min * 1.2).floorToDouble();
  }
}

// ── Export Row ───────────────────────────────────────────────────────────────

class _ExportRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ExportButton(
          label: 'Export PDF',
          icon: Icons.description,
          color: _PnlChartColors.exportBlue,
        ),
        const SizedBox(width: 12),
        _ExportButton(
          label: 'Export Excel',
          icon: Icons.poll,
          color: _PnlChartColors.exportGreen,
        ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 0,
      ),
    );
  }
}
