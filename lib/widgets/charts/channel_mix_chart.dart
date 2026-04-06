import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/channel_mix_model.dart';
import '../../providers/riverpod_providers.dart';

class ChannelMixChart extends ConsumerStatefulWidget {
  const ChannelMixChart({super.key});

  @override
  ConsumerState<ChannelMixChart> createState() => _ChannelMixChartState();
}

class _ChannelMixChartState extends ConsumerState<ChannelMixChart> {
  final Set<String> _hiddenDatasets = {}; // To toggle line visibility

  // Color palette for multiple datasets
  final List<Color> _lineColors = [
    const Color(0xFFB91C1C), // Sales (Dark Red)
    const Color(0xFFA3E635), // Sales team 2 (Lime)
    const Color(0xFF22C55E), // Other (Green)
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFF59E0B), // Amber
  ];

  String _formatValue(double v) {
    if (v == 0) return '0';
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(channelMixProvider);
    const isDark = false; // Forced Light Mode

    return asyncData.when(
      skipLoadingOnReload: true,
      loading: () => const SizedBox(
        height: 380,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          SizedBox(height: 380, child: Center(child: Text('Error: $e'))),
      data: (data) {
        final hasData = data != null && data.datasets.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8EAF5)),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(isDark),

              if (hasData) ...[
                // Legend
                const SizedBox(height: 10),
                _buildLegend(data.datasets, isDark),

                // Chart Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 20, 25, 10),
                    child: _buildLineChart(data, isDark),
                  ),
                ),
              ] else
                Expanded(
                  child: Center(
                    child: Text(
                      'No channel mix data available',
                      style: TextStyle(fontSize: 14, color: Colors.black45),
                    ),
                  ),
                ),

              // Export Footer (only if data exists, or always? usually always for consistency)
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _FooterButton(
                      label: 'Export PDF',
                      icon: Icons.description_outlined,
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 10),
                    _FooterButton(
                      label: 'Export Excel',
                      icon: Icons.bar_chart_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // const Text('🧮', style: TextStyle(fontSize: 20)),
          // const SizedBox(width: 10),
          Text(
            'Channel Mix Over Time',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(List<ChannelDataset> datasets, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: datasets.asMap().entries.map((entry) {
          final label = entry.value.label;
          final isHidden = _hiddenDatasets.contains(label);
          final color = _lineColors[entry.key % _lineColors.length];

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isHidden) {
                  _hiddenDatasets.remove(label);
                } else {
                  _hiddenDatasets.add(label);
                }
              });
            },
            child: Opacity(
              opacity: isHidden ? 0.3 : 1.0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: color, width: 2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight: isHidden
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart(ChannelMixModel data, bool isDark) {
    // Calculate max Y for interval and scaling
    double maxY = 0;
    for (var dataset in data.datasets) {
      for (var val in dataset.data) {
        if (val > maxY) maxY = val;
      }
    }

    // Dynamic rounding for Y axis
    double roundedMax;
    if (maxY <= 100000) {
      roundedMax = (maxY / 20000).ceil() * 20000.0;
    } else if (maxY <= 1000000) {
      roundedMax = (maxY / 200000).ceil() * 200000.0;
    } else if (maxY <= 5000000) {
      roundedMax = (maxY / 500000).ceil() * 500000.0;
    } else {
      roundedMax = (maxY / 1000000).ceil() * 1000000.0;
    }
    if (roundedMax == 0) roundedMax = 1000000;

    return LineChart(
      LineChartData(
        maxY: roundedMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.white10 : Colors.black12,
            strokeWidth: 0.5,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: isDark ? Colors.white10 : Colors.black12,
            strokeWidth: 0.5,
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
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 80,
              interval: roundedMax / 6,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  space: 10,
                  child: Text(
                    _formatValue(value),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 &&
                    index < data.labels.length &&
                    index % 2 == 0) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 12,
                    child: Transform.rotate(
                      angle: -0.7,
                      child: Text(
                        data.labels[index],
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: data.datasets
            .asMap()
            .entries
            .where((e) => !_hiddenDatasets.contains(e.value.label))
            .map((entry) {
              final idx = entry.key;
              final ds = entry.value;
              final color = _lineColors[idx % _lineColors.length];

              return LineChartBarData(
                spots: ds.data
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value))
                    .toList(),
                isCurved: true,
                color: color,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                        radius: 3.5,
                        color: color,
                        strokeWidth: 2,
                        strokeColor: isDark
                            ? const Color(0xFF0E1120)
                            : Colors.white,
                      ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withValues(alpha: 0.05),
                ),
              );
            })
            .toList(),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? const Color(0xFF1F2937) : Colors.black87,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final ds = data.datasets[spot.barIndex];
                return LineTooltipItem(
                  '${ds.label}: ${_formatValue(spot.y)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _FooterButton({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
