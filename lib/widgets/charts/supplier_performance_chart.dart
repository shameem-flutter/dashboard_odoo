import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/supplier_performance_model.dart';
import '../../providers/riverpod_providers.dart';

class SupplierPerformanceChart extends ConsumerStatefulWidget {
  const SupplierPerformanceChart({super.key});

  @override
  ConsumerState<SupplierPerformanceChart> createState() =>
      _SupplierPerformanceChartState();
}

class _SupplierPerformanceChartState
    extends ConsumerState<SupplierPerformanceChart> {
  int? _hoveredIndex;

  static const Color _purchaseColor = Color(0xFF3B82F6);

  // ── Layout constants (matching TopCustomersChart for consistency) ──────────
  static const double _rankWidth = 28.0;
  static const double _labelWidth = 140.0;
  static const double _gapLB = 12.0;
  static const double _barOffset = _rankWidth + _labelWidth + _gapLB + 10;

  String _formatTick(double v) {
    if (v == 0) return '0';
    final absV = v.abs();
    String result;
    if (absV >= 1000000) {
      result = '${(v / 1000000).toStringAsFixed(1)}M';
    } else if (absV >= 1000) {
      result = '${(v / 1000).toStringAsFixed(0)}k';
    } else {
      result = v.toStringAsFixed(0);
    }
    return result;
  }

  String _formatValue(double v) {
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(supplierPerformanceProvider);
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
        final hasData = rawData != null && rawData.detailed.isNotEmpty;

        double roundedMax = 100000;
        List<double> xTicks = [0, 20000, 40000, 60000, 80000, 100000];
        final items = hasData ? rawData.detailed : <SupplierDetail>[];

        if (hasData) {
          double getValue(SupplierDetail item) => item.purchaseValue;

          double maxVal = 0;
          for (final item in items) {
            final v = getValue(item);
            if (v > maxVal) maxVal = v;
          }

          roundedMax = (maxVal <= 100000)
              ? (maxVal / 20000).ceil() * 20000.0
              : (maxVal / 100000).ceil() * 100000.0;
          if (roundedMax == 0) roundedMax = 100000;

          xTicks = [
            0.0,
            roundedMax * 0.2,
            roundedMax * 0.4,
            roundedMax * 0.6,
            roundedMax * 0.8,
            roundedMax,
          ];
        }

        const String metricDisplay = 'PurchaseValue';

        double getValue(SupplierDetail item) => item.purchaseValue;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8EAF5)),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(isDark, metricDisplay),

              // Chart Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: hasData
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            final chartWidth =
                                (constraints.maxWidth - _barOffset).clamp(
                                  0.0,
                                  double.infinity,
                                );

                            return Column(
                              children: [
                                Expanded(
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Vertical Grid Lines
                                      Row(
                                        children: [
                                          const SizedBox(width: _barOffset),
                                          ...xTicks.map(
                                            (_) => Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    left: BorderSide(
                                                      color: Colors.black12,
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                left: BorderSide(
                                                  color: Colors.black12,
                                                  width: 0.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Bars
                                      ListView.builder(
                                        itemCount: items.length,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        clipBehavior: Clip.none,
                                        itemBuilder: (context, index) {
                                          final item = items[index];
                                          final val = getValue(item);
                                          final fraction = (val / roundedMax)
                                              .clamp(0.0, 1.0);

                                          final isHovered =
                                              _hoveredIndex == index;

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: _barOffset - 10,
                                                  child: Text(
                                                    item.name,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.black54,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: GestureDetector(
                                                    onLongPressStart: (_) =>
                                                        setState(
                                                          () => _hoveredIndex =
                                                              index,
                                                        ),
                                                    onLongPressEnd: (_) =>
                                                        setState(
                                                          () => _hoveredIndex =
                                                              null,
                                                        ),
                                                    onLongPressCancel: () =>
                                                        setState(
                                                          () => _hoveredIndex =
                                                              null,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        Stack(
                                                          clipBehavior:
                                                              Clip.none,
                                                          children: [
                                                            AnimatedContainer(
                                                              duration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        500,
                                                                  ),
                                                              height: 18,
                                                              width:
                                                                  (chartWidth *
                                                                          fraction)
                                                                      .clamp(
                                                                        0,
                                                                        chartWidth,
                                                                      ),
                                                              decoration: BoxDecoration(
                                                                color: isHovered
                                                                    ? _purchaseColor.withValues(
                                                                        alpha:
                                                                            0.8,
                                                                      )
                                                                    : _purchaseColor,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      1,
                                                                    ),
                                                              ),
                                                            ),
                                                            if (isHovered)
                                                              Positioned(
                                                                top: -45,
                                                                left: 0,
                                                                child: Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  elevation: 4,
                                                                  child: Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: Colors
                                                                          .black87,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            4,
                                                                          ),
                                                                    ),
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Text(
                                                                          item.name,
                                                                          style: const TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize:
                                                                                10,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          'Purchase Value: ${_formatValue(val)}',
                                                                          style: const TextStyle(
                                                                            color: Color(
                                                                              0xFF5EEAD4,
                                                                            ),
                                                                            fontSize:
                                                                                9,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ],
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
                                // X Axis with rotated labels
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const SizedBox(width: _barOffset),
                                    Expanded(
                                      child: SizedBox(
                                        height: 45, // <--- Add fixed height
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: xTicks.map((t) {
                                            final x =
                                                (t / roundedMax) * chartWidth;
                                            return Positioned(
                                              left: x - 10,
                                              top: 10,
                                              child: Transform.rotate(
                                                angle: -0.6,
                                                child: Text(
                                                  _formatTick(t),
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.black45,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
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
                            'No supplier data available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                ),
              ),

              // Export Footer
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

  Widget _buildHeader(bool isDark, String metricDisplay) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('📦', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Supplier Performance',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    '(PurchaseValue)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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
