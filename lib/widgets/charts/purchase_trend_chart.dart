import 'package:flutter/material.dart';
import '../../models/purchase_trend_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart';
import 'package:google_fonts/google_fonts.dart';

class PurchaseTrendChart extends ConsumerStatefulWidget {
  const PurchaseTrendChart({super.key});

  @override
  ConsumerState<PurchaseTrendChart> createState() => _PurchaseTrendChartState();
}

class _PurchaseTrendChartState extends ConsumerState<PurchaseTrendChart> {
  bool showPurchases = true;
  bool showRefunds = true;

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
    }
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(purchaseTrendProvider);
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

        final purchaseColor = hasData
            ? _hexToColor(rawData.datasets[0].backgroundColor)
            : const Color(0xFF1976D2);
        final refundColor = hasData && rawData.datasets.length > 1
            ? _hexToColor(rawData.datasets[1].backgroundColor)
            : const Color(0xFFF44336);

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
                        'Purchase Trend',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1D2E),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Gross purchases vs refunds',
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
                    ? BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _calculateMaxY(rawData.datasets),
                          minY: 0,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => Colors.white,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                    final dateLabel = _formatDate(
                                      rawData.labels[group.x.toInt()],
                                    );
                                    String datasetLabel = '';
                                    if (showPurchases && showRefunds) {
                                      datasetLabel =
                                          rawData.datasets[rodIndex].label;
                                    } else if (showPurchases) {
                                      datasetLabel = rawData.datasets[0].label;
                                    } else if (showRefunds) {
                                      datasetLabel = rawData.datasets[1].label;
                                    }

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
                            bottomTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                                reservedSize: 12,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                getTitlesWidget: (value, meta) {
                                  String label = "";
                                  if (value == 0) {
                                    label = '0';
                                  } else {
                                    label = value
                                        .toStringAsFixed(0)
                                        .replaceAllMapped(
                                          RegExp(
                                            r'(\d{1,3})(?=(\d{3})+(?!\d))',
                                          ),
                                          (Match m) => '${m[1]},',
                                        );
                                  }
                                  return SideTitleWidget(
                                    meta: meta,
                                    space: 4,
                                    child: Text(
                                      label,
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
                            checkToShowHorizontalLine: (value) => value != 0,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: const Color(0xFFE5E7EB),
                              strokeWidth: 1,
                            ),
                            drawVerticalLine: false,
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
                            if (showPurchases && rawData.datasets.isNotEmpty) {
                              rods.add(
                                BarChartRodData(
                                  toY: rawData.datasets[0].data.length > index
                                      ? rawData.datasets[0].data[index]
                                      : 0,
                                  color: purchaseColor,
                                  width: 8,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(2),
                                  ),
                                ),
                              );
                            }
                            if (showRefunds && rawData.datasets.length > 1) {
                              rods.add(
                                BarChartRodData(
                                  toY: rawData.datasets[1].data.length > index
                                      ? rawData.datasets[1].data[index]
                                      : 0,
                                  color: refundColor,
                                  width: 8,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(2),
                                  ),
                                ),
                              );
                            }

                            return BarChartGroupData(
                              x: index,
                              barRods: rods,
                              barsSpace: 2,
                            );
                          }),
                        ),
                      )
                    : Center(
                        child: Text(
                          'No purchase trend data available',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ),
              ),
              // const SizedBox(height: 12),
              // Legend
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     if (hasData && rawData.datasets.isNotEmpty)
              //       _buildLegendItem(
              //         rawData.datasets[0].label,
              //         purchaseColor,
              //         isDark,
              //         showPurchases,
              //         () => setState(() => showPurchases = !showPurchases),
              //       ),
              //     // const SizedBox(width: 20),
              //     // if (hasData && rawData.datasets.length > 1)
              //     //   _buildLegendItem(
              //     //     rawData.datasets[1].label,
              //     //     refundColor,
              //     //     isDark,
              //     //     showRefunds,
              //     //     () => setState(() => showRefunds = !showRefunds),
              //     //   ),
              //   ],
              // ),
            ],
          ),
        );
      },
    );
  }

  double _calculateMaxY(List<PurchaseTrendDataset> datasets) {
    double max = 0;
    for (final ds in datasets) {
      for (final v in ds.data) {
        if (v > max) max = v;
      }
    }
    return max == 0 ? 100 : max * 1.2;
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

  // Widget _buildLegendItem(
  //   String label,
  //   Color color,
  //   bool isDark,
  //   bool isActive,
  //   VoidCallback onTap,
  // ) {
  //   return InkWell(
  //     onTap: onTap,
  //     borderRadius: BorderRadius.circular(4),
  //     child: Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
  //       child: Row(
  //         children: [
  //           Container(
  //             width: 12,
  //             height: 12,
  //             decoration: BoxDecoration(
  //               color: isActive ? color : color.withValues(alpha: 0.2),
  //               borderRadius: BorderRadius.circular(2),
  //             ),
  //           ),
  //           const SizedBox(width: 8),
  //           Text(
  //             label,
  //             style: TextStyle(
  //               fontSize: 11,
  //               fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
  //               color: isDark ? Colors.white70 : Colors.black87,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
