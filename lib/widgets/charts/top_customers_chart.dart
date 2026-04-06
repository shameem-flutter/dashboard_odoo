import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/customer_top_model.dart';
import '../../providers/riverpod_providers.dart';

class TopCustomersChart extends ConsumerStatefulWidget {
  const TopCustomersChart({super.key});

  @override
  ConsumerState<TopCustomersChart> createState() => _TopCustomersChartState();
}

class _TopCustomersChartState extends ConsumerState<TopCustomersChart> {
  String selectedMetric = 'Revenue';
  String _selectedTop = '10';
  int? _hoveredIndex;

  int get _topCount => _selectedTop == 'All' ? 9999 : int.parse(_selectedTop);
  String get _topLabel => _selectedTop == 'All' ? 'All' : 'Top $_selectedTop';

  static const Color _barColor = Color(0xFF009688);
  static const Color _barHoverColor = Color(0xFF00B09B);

  // ── Layout constants ────────────────────────────────────────────────────────
  static const double _rankWidth = 28.0;
  static const double _labelWidth = 140.0;
  static const double _gapRL = 4.0;
  static const double _gapLB = 12.0;
  static const double _barOffset = _rankWidth + _gapRL + _labelWidth + _gapLB;
  static const double _barHeight = 20.0;
  static const double _rowSpacing = 12.0;

  // ── Formatters ──────────────────────────────────────────────────────────────
  String _formatTick(double v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    } else if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(0)}k';
    }
    return v.toStringAsFixed(0);
  }

  String _formatValue(double v) {
    if (v == 0) return '0';
    // Sharp data: no rounding, remove insignificant trailing zeros
    final s = v.toStringAsFixed(4).replaceAll(RegExp(r'\.?0+$'), '');
    final parts = s.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(customerTopProvider);
    const isDark = false; // Forced Light Mode

    return asyncData.when(
      skipLoadingOnReload: true,
      loading: () => const SizedBox(
        height: 380,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          SizedBox(height: 380, child: Center(child: Text('Error: $e'))),
      data: (rawData) {
        final hasData = rawData != null && rawData.isNotEmpty;

        List<CustomerTopModel> displayData = [];
        double roundedMax = 100;
        List<double> xTicks = [0, 25, 50, 75, 100];
        double tickInterval = 25;

        if (hasData) {
          displayData = rawData.take(_topCount).toList();

          double getValue(CustomerTopModel item) =>
              selectedMetric == 'Profit' ? item.profit : item.revenue;

          double maxVal = 0;
          for (final item in displayData) {
            final v = getValue(item);
            if (v > maxVal) {
              maxVal = v;
            }
          }

          // --- DYNAMIC SCALING ---
          if (maxVal <= 0) {
            roundedMax = 100;
            tickInterval = 25;
          } else if (maxVal <= 1000) {
            roundedMax = (maxVal / 100).ceil() * 100.0;
            tickInterval = roundedMax / 4;
          } else if (maxVal <= 10000) {
            roundedMax = (maxVal / 1000).ceil() * 1000.0;
            tickInterval = roundedMax / 4;
          } else if (maxVal <= 100000) {
            roundedMax = (maxVal / 10000).ceil() * 10000.0;
            tickInterval = roundedMax / 5;
          } else if (maxVal <= 1000000) {
            roundedMax = (maxVal / 100000).ceil() * 100000.0;
            tickInterval = roundedMax / 5;
          } else {
            roundedMax = (maxVal / 1000000).ceil() * 1000000.0;
            tickInterval = 1000000.0;
          }

          xTicks = [];
          for (double i = 0; i <= roundedMax; i += tickInterval) {
            xTicks.add(i);
          }
          if (xTicks.isEmpty || xTicks.last < roundedMax) {
            xTicks.add(roundedMax);
          }
        }

        double getValue(CustomerTopModel item) =>
            selectedMetric == 'Profit' ? item.profit : item.revenue;

        return Container(
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
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FF),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  border: Border(
                    bottom: BorderSide(color: const Color(0xFFE8EAF5)),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Container(
                        //   width: 36,
                        //   height: 36,
                        //   decoration: BoxDecoration(
                        //     color: const Color(
                        //       0xFF009688,
                        //     ).withValues(alpha: 0.12),
                        //     borderRadius: BorderRadius.circular(9),
                        //   ),
                        //   alignment: Alignment.center,
                        //   child: const Text(
                        //     '📊',
                        //     style: TextStyle(fontSize: 17),
                        //   ),
                        // ),
                        // const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'TOP CUSTOMERS',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                  color: const Color(0xFF1A1D2E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline_rounded,
                                    size: 10,
                                    color: const Color(0xFF0D9488),
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      'Showing $_topLabel by $selectedMetric',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontStyle: FontStyle.italic,
                                        color: const Color(0xFF0D9488),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _HeaderDropdown(
                          isDark: isDark,
                          value: _selectedTop,
                          items: const ['5', '10', '20', 'All'],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedTop = val;
                                _hoveredIndex = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _MetricToggle(
                      isDark: isDark,
                      selected: selectedMetric,
                      onChanged: (val) => setState(() => selectedMetric = val),
                    ),
                  ],
                ),
              ),

              // Chart Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: hasData
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            final double chartWidth =
                                (constraints.maxWidth - _barOffset).clamp(
                                  0.0,
                                  double.infinity,
                                );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    physics: _selectedTop == '5'
                                        ? const NeverScrollableScrollPhysics()
                                        : const ClampingScrollPhysics(),
                                    clipBehavior: Clip.none,
                                    itemCount: displayData.length,
                                    itemBuilder: (context, index) {
                                      final item = displayData[index];
                                      final val = getValue(item);
                                      final fraction = (val / roundedMax).clamp(
                                        0.0,
                                        1.0,
                                      );
                                      final isHovered = _hoveredIndex == index;
                                      final tickLabel = _formatTick(val);

                                      const double charW = 6.5;
                                      final double labelPx =
                                          tickLabel.length * charW;
                                      final double barEndX =
                                          chartWidth * fraction;
                                      final bool labelOutside =
                                          (chartWidth - barEndX) >=
                                          (labelPx + 8);
                                      final bool labelInsideVisible =
                                          !labelOutside &&
                                          barEndX > (labelPx + 8);

                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: _rowSpacing,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: _rankWidth,
                                              child: Center(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: index == 0
                                                        ? const Color(
                                                            0xFFFBBF24,
                                                          ).withValues(
                                                            alpha: 0.15,
                                                          )
                                                        : index == 1
                                                        ? const Color(
                                                            0xFF94A3B8,
                                                          ).withValues(
                                                            alpha: 0.12,
                                                          )
                                                        : index == 2
                                                        ? const Color(
                                                            0xFFCD7C2F,
                                                          ).withValues(
                                                            alpha: 0.12,
                                                          )
                                                        : const Color(
                                                            0xFFF3F4F6,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '#${index + 1}',
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: index == 0
                                                          ? const Color(
                                                              0xFFF59E0B,
                                                            )
                                                          : index == 1
                                                          ? const Color(
                                                              0xFF94A3B8,
                                                            )
                                                          : index == 2
                                                          ? const Color(
                                                              0xFFCD7C2F,
                                                            )
                                                          : const Color(
                                                              0xFF9CA3AF,
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: _gapRL),
                                            SizedBox(
                                              width: _labelWidth,
                                              child: Text(
                                                item.customer,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(
                                                    0xFF6B7280,
                                                  ),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                            const SizedBox(width: _gapLB),
                                            Expanded(
                                              child: GestureDetector(
                                                onTapDown: (_) => setState(
                                                  () => _hoveredIndex = index,
                                                ),
                                                onTapUp: (_) => setState(
                                                  () => _hoveredIndex = null,
                                                ),
                                                onTapCancel: () => setState(
                                                  () => _hoveredIndex = null,
                                                ),
                                                onLongPressStart: (_) =>
                                                    setState(
                                                      () =>
                                                          _hoveredIndex = index,
                                                    ),
                                                onLongPressEnd: (_) => setState(
                                                  () => _hoveredIndex = null,
                                                ),
                                                onLongPressCancel: () =>
                                                    setState(
                                                      () =>
                                                          _hoveredIndex = null,
                                                    ),
                                                child: SizedBox(
                                                  height: _barHeight,
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    clipBehavior: Clip.none,
                                                    children: [
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFFF3F4F6,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                3,
                                                              ),
                                                        ),
                                                      ),
                                                      ...xTicks.map((tick) {
                                                        final x =
                                                            (tick /
                                                                roundedMax) *
                                                            chartWidth;
                                                        return Positioned(
                                                          left: x.clamp(
                                                            0.0,
                                                            chartWidth,
                                                          ),
                                                          top: 0,
                                                          bottom: 0,
                                                          width: 1,
                                                          child: ColoredBox(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.9,
                                                                ),
                                                          ),
                                                        );
                                                      }),
                                                      Positioned(
                                                        left: 0,
                                                        top: 0,
                                                        bottom: 0,
                                                        child: AnimatedContainer(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    400,
                                                              ),
                                                          curve: Curves
                                                              .easeOutCubic,
                                                          width:
                                                              chartWidth *
                                                              fraction,
                                                          decoration: BoxDecoration(
                                                            color: isHovered
                                                                ? _barHoverColor
                                                                : _barColor,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  3,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      if (labelOutside)
                                                        Positioned(
                                                          left: barEndX + 5,
                                                          top: 0,
                                                          bottom: 0,
                                                          child: Align(
                                                            alignment: Alignment
                                                                .centerLeft,
                                                            child: Text(
                                                              tickLabel,
                                                              style: TextStyle(
                                                                fontSize: 9.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    const Color(
                                                                      0xFF6B7280,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      else if (labelInsideVisible)
                                                        Positioned(
                                                          right:
                                                              chartWidth -
                                                              barEndX +
                                                              5,
                                                          top: 0,
                                                          bottom: 0,
                                                          child: Align(
                                                            alignment: Alignment
                                                                .centerRight,
                                                            child: Text(
                                                              tickLabel,
                                                              style: const TextStyle(
                                                                fontSize: 9.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      if (isHovered)
                                                        Positioned(
                                                          top:
                                                              -100, // Increased to fit all rows
                                                          left: 0,
                                                          child: Material(
                                                            color: Colors
                                                                .transparent,
                                                            elevation: 8,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        12,
                                                                    vertical: 9,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .black87,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      10,
                                                                    ),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .black
                                                                        .withValues(
                                                                          alpha:
                                                                              0.3,
                                                                        ),
                                                                    blurRadius:
                                                                        12,
                                                                    offset:
                                                                        const Offset(
                                                                          0,
                                                                          4,
                                                                        ),
                                                                  ),
                                                                ],
                                                              ),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Text(
                                                                    item.customer,
                                                                    style: const TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines: 1,
                                                                  ),
                                                                  const Padding(
                                                                    padding:
                                                                        EdgeInsets.symmetric(
                                                                          vertical:
                                                                              4,
                                                                        ),
                                                                    child: Divider(
                                                                      color: Colors
                                                                          .white24,
                                                                      height: 1,
                                                                    ),
                                                                  ),
                                                                  _TooltipMetricRow(
                                                                    label:
                                                                        'Revenue',
                                                                    value: _formatValue(
                                                                      item.revenue,
                                                                    ),
                                                                    isSelected:
                                                                        selectedMetric ==
                                                                        'Revenue',
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 3,
                                                                  ),
                                                                  _TooltipMetricRow(
                                                                    label:
                                                                        'Cost',
                                                                    value: _formatValue(
                                                                      item.cost,
                                                                    ),
                                                                    isSelected:
                                                                        false,
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 3,
                                                                  ),
                                                                  _TooltipMetricRow(
                                                                    label:
                                                                        'Profit',
                                                                    value: _formatValue(
                                                                      item.profit,
                                                                    ),
                                                                    isSelected:
                                                                        selectedMetric ==
                                                                        'Profit',
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Row(
                                  children: [
                                    const SizedBox(width: _barOffset),
                                    SizedBox(
                                      width: chartWidth,
                                      height: 26,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: xTicks.map((tick) {
                                          final xPos =
                                              (tick / roundedMax) * chartWidth;
                                          final label = _formatTick(tick);
                                          final labelW = label.length * 6.5;

                                          final double left = tick == 0
                                              ? 0
                                              : tick == roundedMax
                                              ? (chartWidth - labelW).clamp(
                                                  0.0,
                                                  chartWidth,
                                                )
                                              : (xPos - labelW / 2).clamp(
                                                  0.0,
                                                  chartWidth - labelW,
                                                );

                                          return Positioned(
                                            left: left,
                                            top: 5,
                                            child: Text(
                                              label,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF6B7280),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            'No top customer data available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                ),
              ),

              // Export Footer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FF),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                  border: Border(
                    top: BorderSide(color: const Color(0xFFE8EAF5)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.download_outlined,
                      size: 13,
                      color: const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Export report',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    const Spacer(),
                    _ExportButton(
                      label: 'PDF',
                      icon: Icons.picture_as_pdf_outlined,
                      backgroundColor: const Color(0xFF3B82F6),
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    _ExportButton(
                      label: 'Excel',
                      icon: Icons.table_chart_outlined,
                      backgroundColor: const Color(0xFF22C55E),
                      onTap: () {},
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
}

class _HeaderDropdown extends StatelessWidget {
  final bool isDark;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _HeaderDropdown({
    required this.isDark,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          onChanged: onChanged,
          dropdownColor: isDark ? const Color(0xFF1A1E33) : Colors.white,
          items: items.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text(
                'Top $t',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MetricToggle extends StatelessWidget {
  final bool isDark;
  final String selected;
  final ValueChanged<String> onChanged;

  const _MetricToggle({
    required this.isDark,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: ['Revenue', 'Profit'].map((m) {
          final isSel = selected == m;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(m),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSel
                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    if (isSel && !isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: Text(
                  m,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    color: isSel
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white38 : Colors.black45),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _ExportButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TooltipMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;

  const _TooltipMetricRow({
    required this.label,
    required this.value,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isSelected ? const Color(0xFF5EEAD4) : Colors.white,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
