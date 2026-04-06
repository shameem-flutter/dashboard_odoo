import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/top_product_model.dart';
import '../../providers/riverpod_providers.dart';

abstract class _ChartColors {
  static const border = Color(0xFF1A1E33);
  static const titleDark = Color(0xFFF4F6FF);
  static const titleLight = Color(0xFF1F2937);
  static const lightBorder = Color(0xFFE8EAF5);
}

class BreakdownChart extends ConsumerStatefulWidget {
  const BreakdownChart({super.key});

  @override
  ConsumerState<BreakdownChart> createState() => _BreakdownChartState();
}

class _BreakdownChartState extends ConsumerState<BreakdownChart> {
  int _topCount = 10;
  final List<int> _topOptions = [5, 10, 20, 0]; // 0 means All

  String _formatValue(double value) {
    return NumberFormat.compact().format(value);
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(breakdownProvider);
    const isDark = false; // Forced Light Mode

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (rawData) {
        final hasData = rawData != null && rawData.isNotEmpty;

        // Apply Top X filter and sort (only if data exists)
        List<TopProductModel> displayData = [];
        double maxRevenue = 1.0;

        if (hasData) {
          final sortedData = List<TopProductModel>.from(rawData)
            ..sort((a, b) => b.revenue.compareTo(a.revenue));
          displayData = _topCount == 0
              ? sortedData
              : sortedData.take(_topCount).toList();
          maxRevenue = displayData.isEmpty ? 1.0 : displayData.first.revenue;
          if (maxRevenue == 0) maxRevenue = 1.0;
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
                    ? _buildChartBody(displayData, maxRevenue, isDark)
                    : Center(
                        child: Text(
                          'No product data available',
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

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              // const Text('📊', style: TextStyle(fontSize: 22)),
              // const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Product Breakdown (${_topCount == 0 ? "All" : "Top $_topCount"})',
                  overflow: TextOverflow.clip,
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
        _buildTopSelector(isDark),
      ],
    );
  }

  Widget _buildTopSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black12,
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _topCount,
          dropdownColor: isDark ? _ChartColors.border : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (int? newValue) {
            if (newValue != null) {
              setState(() => _topCount = newValue);
            }
          },
          items: _topOptions.map<DropdownMenuItem<int>>((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text(value == 0 ? 'Top All' : 'Top $value'),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChartBody(
    List<TopProductModel> data,
    double maxVal,
    bool isDark,
  ) {
    const double leftLabelWidth = 120.0;
    const barColor = Color(
      0xFF0D9488,
    ); // Teal color matching the user's screenshot area

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth =
            constraints.maxWidth -
            leftLabelWidth -
            60; // Extra space for value labels on the right

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            final widthPct = (item.revenue / maxVal).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  // Left Label
                  SizedBox(
                    width: leftLabelWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Text(
                        item.product,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ),
                  // Bar
                  Container(
                    height: 20,
                    width: widthPct * chartWidth,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Value Label
                  const SizedBox(width: 8),
                  Text(
                    _formatValue(item.revenue),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
