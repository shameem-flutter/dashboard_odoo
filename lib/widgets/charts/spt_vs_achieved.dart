// spt_vs_achieved.dart — full file

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/riverpod_providers.dart';

class SptVsAchieved extends ConsumerStatefulWidget {
  const SptVsAchieved({super.key});

  @override
  ConsumerState<SptVsAchieved> createState() => _SptvsAchievedState();
}

class _SptvsAchievedState extends ConsumerState<SptVsAchieved> {
  int? touchedGroupIndex;
  bool _showTarget = true;
  bool _showAchieved = true;

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  String _formatFullValue(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(salespersonTargetProvider);

    // ✅ Side effect: Warn user if targets are zero
    ref.listen(salespersonTargetProvider, (previous, next) {
      next.whenData((rawData) {
        if (rawData != null &&
            rawData.datasets.isNotEmpty &&
            rawData.datasets[0].data.any((v) => v == 0)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Warning: One or more targets are zero (0)'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
            ),
          );
        }
      });
    });

    return asyncData.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (rawData) {
        final hasData = rawData != null && rawData.labels.isNotEmpty;

        if (!hasData) {
          return const Center(
            child: Text('No salesperson target data available'),
          );
        }

        double maxVal = 0;
        if (_showTarget) {
          for (var v in rawData.datasets[0].data) {
            if (v > maxVal) maxVal = v;
          }
        }
        if (_showAchieved) {
          for (var v in rawData.datasets[1].data) {
            if (v > maxVal) maxVal = v;
          }
        }

        final double maxY = maxVal == 0 ? 1000000 : (maxVal * 1.25);
        final double interval = (maxY / 4).ceilToDouble();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                children: [
                  // Text('🤵', style: TextStyle(fontSize: 22)),
                  // SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Salesperson Target vs Achieved',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Legend ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(
                    'Target',
                    const Color(0xFF3B82F6),
                    _showTarget,
                    () => setState(() => _showTarget = !_showTarget),
                  ),
                  const SizedBox(width: 30),
                  _buildLegendItem(
                    'Achieved',
                    const Color(0xFF10B981),
                    _showAchieved,
                    () => setState(() => _showAchieved = !_showAchieved),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Chart ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 10),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF1E293B),
                          tooltipPadding: const EdgeInsets.all(8),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final name = rawData.labels[groupIndex];
                            // Match metric with rodIndex, keeping track of active series
                            String metric = '';
                            if (_showTarget && _showAchieved) {
                              metric = rodIndex == 0 ? 'Target' : 'Achieved';
                            } else if (_showTarget) {
                              metric = 'Target';
                            } else if (_showAchieved) {
                              metric = 'Achieved';
                            }

                            return BarTooltipItem(
                              '$name\n$metric: ${_formatFullValue(rod.toY)}',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        touchCallback: (event, response) {
                          if (response == null || response.spot == null) {
                            setState(() => touchedGroupIndex = -1);
                            return;
                          }
                          setState(
                            () => touchedGroupIndex =
                                response.spot!.touchedBarGroupIndex,
                          );
                        },
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
                            reservedSize: 100,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= rawData.labels.length) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                space: 8,
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: SizedBox(
                                    width: 80,
                                    child: Text(
                                      rawData.labels[index],
                                      style: TextStyle(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
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
                            reservedSize: 65,
                            interval: interval > 0 ? interval : 1000000,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _formatCurrency(value).replaceAll('.0', ''),
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: interval > 0 ? interval : 1000000,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: const Color(0xFFF1F5F9),
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: const Color(0xFFF1F5F9),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.black.withValues(alpha: 0.1),
                            width: 1,
                          ),
                          left: BorderSide(
                            color: Colors.black.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      barGroups: List.generate(rawData.labels.length, (i) {
                        final rods = <BarChartRodData>[];
                        if (_showTarget) {
                          rods.add(
                            BarChartRodData(
                              toY: rawData.datasets[0].data[i],
                              color: const Color(0xFF3B82F6),
                              width: 14,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(2),
                                topRight: Radius.circular(2),
                              ),
                            ),
                          );
                        }
                        if (_showAchieved) {
                          rods.add(
                            BarChartRodData(
                              toY: rawData.datasets[1].data[i],
                              color: const Color(0xFF10B981),
                              width: 14,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(2),
                                topRight: Radius.circular(2),
                              ),
                            ),
                          );
                        }
                        return BarChartGroupData(
                          x: i,
                          barRods: rods,
                          showingTooltipIndicators: touchedGroupIndex == i
                              ? List.generate(rods.length, (n) => n)
                              : [],
                        );
                      }),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Footer ──
              Row(
                children: [
                  Expanded(
                    child: _buildFooterButton(
                      'Export PDF',
                      Icons.description_outlined,
                      const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFooterButton(
                      'Export Excel',
                      Icons.table_view_outlined,
                      const Color(0xFF10B981),
                    ),
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
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isActive ? 1.0 : 0.4,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterButton(String label, IconData icon, Color color) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
