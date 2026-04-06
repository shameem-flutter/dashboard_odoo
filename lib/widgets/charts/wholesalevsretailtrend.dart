import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/wholesale_vs_retail_model.dart';
import '../../providers/riverpod_providers.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class _ChartColors {
  static const background = Color(0xFF0E1120);

  static const titleDark = Color(0xFFF4F6FF);
  static const titleLight = Color(0xFF1F2937);
  static const exportBlue = Color(0xFF2563EB);
  static const exportGreen = Color(0xFF16A34A);
  static const wholesaleColor = Color(0xFF3B82F6); // Blue
  static const retailColor = Color(0xFFF59E0B); // Amber/Orange
  static const lightBorder = Color(0xFFE8EAF5);
}

Color _colorForLabel(String label) {
  if (label.toLowerCase().contains('wholesale')) {
    return _ChartColors.wholesaleColor;
  }
  if (label.toLowerCase().contains('retail')) return _ChartColors.retailColor;
  return Colors.blue;
}

String _yAxisLabel(double v) {
  return NumberFormat.decimalPattern().format(v);
}

class WholesaleVsRetailTrendChart extends ConsumerStatefulWidget {
  const WholesaleVsRetailTrendChart({super.key});

  @override
  ConsumerState<WholesaleVsRetailTrendChart> createState() =>
      _WholesaleVsRetailTrendChartState();
}

class _WholesaleVsRetailTrendChartState
    extends ConsumerState<WholesaleVsRetailTrendChart> {
  final Set<String> _hiddenDatasets = {};

  void _toggleDataset(String label) {
    setState(() {
      if (_hiddenDatasets.contains(label)) {
        _hiddenDatasets.remove(label);
      } else {
        if (_hiddenDatasets.isEmpty) {
          // allow max 1 to be hidden
          _hiddenDatasets.add(label);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(wholesaleVsRetailProvider);
    const isDark = false; // Forced Light Mode

    return asyncData.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error: $e'),
      data: (rawData) {
        final hasData = rawData != null && rawData.labels.isNotEmpty;

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
              const SizedBox(height: 16),
              _LegendRow(
                isDark: isDark,
                hiddenDatasets: _hiddenDatasets,
                onToggle: _toggleDataset,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: hasData
                    ? _LineChartWidget(
                        isDark: isDark,
                        data: rawData,
                        hiddenDatasets: _hiddenDatasets,
                      )
                    : Center(
                        child: Text(
                          'No data available',
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

class _ChartHeader extends StatelessWidget {
  final bool isDark;

  const _ChartHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // const Text('🛒', style: TextStyle(fontSize: 22)),
        // const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Wholesale vs Retail Trend',
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
          label: 'Wholesale',
          color: _ChartColors.wholesaleColor,
          isDark: isDark,
          isFaded: hiddenDatasets.contains('Wholesale'),
          onTap: () => onToggle('Wholesale'),
        ),
        const SizedBox(width: 16),
        _LegendItem(
          label: 'Retail',
          color: _ChartColors.retailColor,
          isDark: isDark,
          isFaded: hiddenDatasets.contains('Retail'),
          onTap: () => onToggle('Retail'),
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

class _LineChartWidget extends StatelessWidget {
  const _LineChartWidget({
    required this.isDark,
    required this.data,
    required this.hiddenDatasets,
  });

  final bool isDark;
  final WholesaleVsRetailModel data;
  final Set<String> hiddenDatasets;

  @override
  Widget build(BuildContext context) {
    final visibleDatasets = data.datasets
        .where((d) => !hiddenDatasets.contains(d.label))
        .toList();

    double max = 0;
    for (var d in visibleDatasets) {
      for (var v in d.data) {
        if (v > max) max = v;
      }
    }
    final double maxY = max == 0 ? 100 : (max * 1.2).ceilToDouble();

    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: LineChart(
        LineChartData(
          maxY: maxY,
          minY: 0,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => Colors.white,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = _formatDate(data.labels[spot.x.toInt()]);
                  return LineTooltipItem(
                    '$date\n',
                    const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                    ),
                    children: [
                      TextSpan(
                        text: _yAxisLabel(spot.y),
                        style: TextStyle(
                          color: spot.bar.color ?? Colors.blue,
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
                interval: data.labels.length > 6
                    ? (data.labels.length / 6).ceilToDouble()
                    : 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.labels.length) {
                    return const SizedBox.shrink();
                  }

                  String label = _formatDate(data.labels[i]);

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
              isCurved: false, // Straight lines like in the image
              color: _colorForLabel(dataset.label),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: isDark ? _ChartColors.background : Colors.white,
                    strokeWidth: 2,
                    strokeColor: barData.color ?? Colors.blue,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatDate(String label) {
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

class _ExportRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ExportButton(
          label: 'Export PDF',
          icon: Icons.description,
          color: _ChartColors.exportBlue,
        ),
        const SizedBox(width: 12),
        _ExportButton(
          label: 'Export Excel',
          icon: Icons.poll,
          color: _ChartColors.exportGreen,
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
