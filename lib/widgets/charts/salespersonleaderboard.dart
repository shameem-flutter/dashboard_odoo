import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../../models/salesperson_leaderboard_model.dart';
import '../../providers/riverpod_providers.dart';

abstract class _ChartColors {
  static const border = Color(0xFF1A1E33);
  static const titleDark = Color(0xFFF4F6FF);
  static const titleLight = Color(0xFF1F2937);
  static const exportBlue = Color(0xFF2563EB);
  static const exportGreen = Color(0xFF16A34A);
  static const barColor = Color(0xFF22C55E); // Green
  static const lightBorder = Color(0xFFE8EAF5);
}

class SalespersonLeaderboard extends ConsumerStatefulWidget {
  const SalespersonLeaderboard({super.key});

  @override
  ConsumerState<SalespersonLeaderboard> createState() =>
      _SalespersonLeaderboardState();
}

class _SalespersonLeaderboardState
    extends ConsumerState<SalespersonLeaderboard> {
  String _selectedMetric = 'Profit';
  final List<String> _metrics = ['Profit', 'Revenue', 'Cost'];

  String _formatValue(double value) {
    if (value == 0) return '0';
    return NumberFormat.decimalPattern().format(value);
  }

  double _getMetricValue(SalespersonLeaderboardDetailed item, String metric) {
    switch (metric.toLowerCase()) {
      case 'profit':
        return item.profit;
      case 'revenue':
        return item.revenue;
      case 'cost':
        return item.cost;
      default:
        return item.revenue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(salespersonLeaderboardProvider);
    const isDark = false; // Forced Light Mode

    return asyncData.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error: $e'),
      data: (data) {
        final hasData = data != null && data.detailed.isNotEmpty;

        List<SalespersonLeaderboardDetailed> detailedData = [];
        double chartMax = 100;
        List<double> gridValues = [0, 25, 50, 75, 100];

        if (hasData) {
          // Sort data descending by selected metric
          detailedData = List.from(data.detailed);
          detailedData.sort(
            (a, b) => _getMetricValue(
              b,
              _selectedMetric,
            ).compareTo(_getMetricValue(a, _selectedMetric)),
          );

          // Determine max value for scaling
          double maxVal = 0;
          for (var item in detailedData) {
            final val = _getMetricValue(item, _selectedMetric);
            if (val > maxVal) maxVal = val;
          }
          if (maxVal == 0) maxVal = 100;

          final double step = (maxVal / 3).ceilToDouble();
          gridValues = [0, step, step * 2, step * 3];
          chartMax = step * 3;
        }

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
              _buildHeader(isDark),
              const SizedBox(height: 24),
              Expanded(
                child: hasData
                    ? _buildChartBody(
                        detailedData,
                        chartMax,
                        gridValues,
                        isDark,
                      )
                    : Center(
                        child: Text(
                          'No salesperson data available',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              _buildExportRow(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // const Text('📈', style: TextStyle(fontSize: 22)),
                  // const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Salesperson Leaderboard',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? _ChartColors.titleDark
                            : _ChartColors.titleLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 30.0),
                child: Text(
                  '($_selectedMetric)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? _ChartColors.titleDark
                        : _ChartColors.titleLight,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 30, // Fixed height for compact look
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.black12,
              width: 1.0,
            ),
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedMetric,
              dropdownColor: isDark ? _ChartColors.border : Colors.white,
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedMetric = newValue;
                  });
                }
              },
              items: _metrics.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartBody(
    List<SalespersonLeaderboardDetailed> data,
    double maxVal,
    List<double> gridValues,
    bool isDark,
  ) {
    const double leftLabelWidth = 180.0;
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = constraints.maxWidth - leftLabelWidth;

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Vertical grid lines
                  Positioned(
                    left: leftLabelWidth,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(gridValues.length, (index) {
                        return Container(
                          width: 1,
                          color: index == 0
                              ? (isDark ? Colors.white24 : Colors.black26)
                              : gridColor,
                        );
                      }),
                    ),
                  ),
                  // Bars and labels
                  ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      final value = _getMetricValue(item, _selectedMetric);
                      final widthPct = (value / maxVal).clamp(0.0, 1.0);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            // Left Label
                            SizedBox(
                              width: leftLabelWidth,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  item.name,
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ),
                            // Bar
                            Tooltip(
                              message:
                                  '${item.name}\n$_selectedMetric: ${_formatValue(value)}',
                              triggerMode: TooltipTriggerMode.tap,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black12,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              textStyle: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              child: Container(
                                height: 18,
                                width: widthPct * chartWidth,
                                decoration: const BoxDecoration(
                                  color: _ChartColors.barColor,
                                  // Give it a slight corner curve for modern look
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(2),
                                    bottomRight: Radius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Bottom Axis
            Container(
              height: 1,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  const SizedBox(width: leftLabelWidth),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: List.generate(gridValues.length, (index) {
                        final val = gridValues[index];
                        final leftPos =
                            (index / (gridValues.length - 1)) * chartWidth;

                        return Positioned(
                          left: leftPos - 30, // Center text approximation
                          top: 8,
                          width: 60,
                          child: Transform.rotate(
                            angle: -math.pi / 8, // slight rotate matching mock
                            child: Text(
                              _formatValue(val),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExportRow() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.description, size: 16, color: Colors.white),
          label: const Text(
            'Export PDF',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _ChartColors.exportBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            elevation: 0,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.poll, size: 16, color: Colors.white),
          label: const Text(
            'Export Excel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _ChartColors.exportGreen,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}
