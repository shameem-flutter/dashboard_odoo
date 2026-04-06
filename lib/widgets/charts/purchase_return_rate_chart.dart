import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart';
import 'package:google_fonts/google_fonts.dart';

class PurchaseReturnRateChart extends ConsumerStatefulWidget {
  const PurchaseReturnRateChart({super.key});

  @override
  ConsumerState<PurchaseReturnRateChart> createState() =>
      _PurchaseReturnRateChartState();
}

class _PurchaseReturnRateChartState
    extends ConsumerState<PurchaseReturnRateChart> {
  bool showPurchases = true;
  bool showReturns = true;

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(purchaseReturnRateProvider);
    const isDark = false; // Forced Light Mode

    return asyncData.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (rawData) {
        final hasData =
            rawData != null &&
            rawData.labels.isNotEmpty &&
            rawData.datasets.isNotEmpty;

        const purchasesColor = Color(0xFF3B82F6);
        const returnsColor = Color(0xFFEF4444);

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Purchase Return Rate (Purchases vs Returns)',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1D2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Purchases vs Returns',
                          style: TextStyle(
                            fontSize: 10,
                            color: const Color(0xFFAAAEC8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Legend (toggleable) ──
                  Row(
                    children: [
                      _LegendDot(
                        label: 'Purchases',
                        color: purchasesColor,
                        isDark: isDark,
                        isActive: showPurchases,
                        onTap: () =>
                            setState(() => showPurchases = !showPurchases),
                      ),
                      const SizedBox(width: 12),
                      _LegendDot(
                        label: 'Returns',
                        color: returnsColor,
                        isDark: isDark,
                        isActive: showReturns,
                        onTap: () => setState(() => showReturns = !showReturns),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Chart body ──
              Expanded(
                child: hasData
                    ? _buildChart(
                        context,
                        rawData,
                        isDark,
                        purchasesColor,
                        returnsColor,
                      )
                    : Center(
                        child: Text(
                          'No data available',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart(
    BuildContext context,
    dynamic data,
    bool isDark,
    Color purchasesColor,
    Color returnsColor,
  ) {
    // ── Dynamic bounds with 20% headroom ──
    double maxVal = 0;
    double minVal = 0;

    if (showPurchases && data.datasets.isNotEmpty) {
      for (final v in data.datasets[0].data) {
        if (v > maxVal) maxVal = v;
      }
    }
    if (showReturns && data.datasets.length > 1) {
      for (final v in data.datasets[1].data) {
        if (v < minVal) minVal = v;
      }
    }

    double maxY = maxVal == 0 ? (minVal < 0 ? 0 : 10) : maxVal * 1.2;
    double minY = minVal == 0 ? (maxVal > 0 ? 0 : -10) : minVal * 1.2;
    if (maxY == minY) maxY += 10;

    return Padding(
      padding: const EdgeInsets.only(right: 16, left: 4, bottom: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final int barCount = data.labels.length;
          // Dynamically compute width to fit in the box
          double dynamicWidth = barCount > 0
              ? (constraints.maxWidth / barCount) * 0.8
              : 32.0;
          if (dynamicWidth > 32) dynamicWidth = 32.0;
          if (dynamicWidth < 4) dynamicWidth = 4.0;

          final int skipCount = barCount > 6 ? (barCount / 6).ceil() : 1;

          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              minY: minY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) =>
                      isDark ? const Color(0xFF1A1E33) : Colors.white,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final dateLabel = _formatDate(data.labels[group.x.toInt()]);
                    final purchaseVal = data.datasets.isNotEmpty
                        ? data.datasets[0].data[groupIndex]
                        : 0.0;
                    final returnVal = data.datasets.length > 1
                        ? data.datasets[1].data[groupIndex]
                        : 0.0;

                    final lines = <TextSpan>[];
                    if (showPurchases && purchaseVal > 0) {
                      lines.add(
                        TextSpan(
                          text: 'Purchases: ${_formatValue(purchaseVal)}\n',
                          style: TextStyle(
                            color: purchasesColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    if (showReturns && returnVal < 0) {
                      lines.add(
                        TextSpan(
                          text: 'Returns: ${_formatValue(returnVal)}',
                          style: TextStyle(
                            color: returnsColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    if (lines.isEmpty) return null;

                    // Remove the trailing newline if it's the last line
                    if (lines.length == 1 && lines[0].text!.endsWith('\n')) {
                      lines[0] = TextSpan(
                        text: lines[0].text!.trimRight(),
                        style: lines[0].style,
                      );
                    }

                    return BarTooltipItem(
                      '$dateLabel\n',
                      const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 10,
                        fontWeight: FontWeight.normal,
                      ),
                      children: lines,
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: 1, // Let getTitlesWidget handle skipping
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= data.labels.length) {
                        return const SizedBox.shrink();
                      }

                      // Only show every `skipCount` label, but guarantee the first and last (or just skipping cleanly)
                      // This avoids drawing all 24 labels in BarChart overlapping each other!
                      if (idx % skipCount != 0 &&
                          idx != data.labels.length - 1) {
                        return const SizedBox.shrink();
                      }

                      String label = _formatDate(data.labels[idx]);

                      return SideTitleWidget(
                        meta: meta,
                        space: 12,
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? const Color(0xFF6B7280)
                                  : const Color(
                                      0xFF6B7280,
                                    ), // Matched to images
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
                    reservedSize: 56,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max && value != 0) {
                        return const SizedBox.shrink();
                      }
                      if (value == meta.min && value != 0) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        space: 8,
                        child: Text(
                          _formatValue(value),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF6B7280),
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
                      ? (isDark ? Colors.white30 : Colors.black26)
                      : (isDark
                            ? const Color(0xFF1E2235)
                            : const Color(0xFFEFF0F6)),
                  strokeWidth: value == 0 ? 1.5 : 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: isDark
                      ? const Color(0xFF1E2235)
                      : const Color(0xFFEFF0F6),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E2235)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              barGroups: List.generate(data.labels.length, (index) {
                final double purchaseVal =
                    data.datasets.isNotEmpty &&
                        index < data.datasets[0].data.length
                    ? data.datasets[0].data[index].toDouble()
                    : 0.0;
                final double returnVal =
                    data.datasets.length > 1 &&
                        index < data.datasets[1].data.length
                    ? data.datasets[1].data[index].toDouble()
                    : 0.0;

                final double actualPurchase = showPurchases ? purchaseVal : 0.0;
                final double actualReturn = showReturns ? returnVal : 0.0;

                return BarChartGroupData(
                  x: index,
                  barsSpace: 0,
                  barRods: [
                    BarChartRodData(
                      fromY: actualReturn < 0 ? actualReturn : 0,
                      toY: actualPurchase > 0 ? actualPurchase : 0,
                      width: dynamicWidth,
                      borderRadius: BorderRadius.zero,
                      color: Colors.transparent,
                      rodStackItems: [
                        if (actualReturn < 0)
                          BarChartRodStackItem(actualReturn, 0, returnsColor),
                        if (actualPurchase > 0)
                          BarChartRodStackItem(
                            0,
                            actualPurchase,
                            purchasesColor,
                          ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }

  String _formatValue(double v) {
    if (v == 0) return '0';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    if (v <= -1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v <= -1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
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

// ─────────────────────────────────────────────────────────────────────────────
// Legend dot widget
// ─────────────────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.label,
    required this.color,
    required this.isDark,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isDark;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? color : color.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? (isDark ? const Color(0xFFDDE0F5) : const Color(0xFF1A1D2E))
                  : (isDark
                        ? const Color(0xFF3E4470)
                        : const Color(0xFFAAAEC8)),
            ),
          ),
        ],
      ),
    );
  }
}
