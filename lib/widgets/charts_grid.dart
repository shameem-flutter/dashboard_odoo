import 'package:dashboard_odoo/widgets/charts/pnl_by_month_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'charts/spt_vs_achieved.dart';
import 'charts/purchase_trend_chart.dart';
import 'charts/return_rate_chart.dart';
import 'charts/purchase_return_rate_chart.dart';
import 'charts/wholesalevsretailtrend.dart';
import 'charts/salespersonleaderboard.dart';
import 'charts/pnl_by_store_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/riverpod_providers.dart';
import 'charts/top_customers_chart.dart';
import 'charts/supplier_performance_chart.dart';
import 'charts/channel_mix_chart.dart';
import 'charts/trend_chart.dart';
import 'charts/breakdown_chart.dart';
import 'charts/target_achievement_chart.dart';

class ChartsGrid extends StatelessWidget {
  const ChartsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoCols = constraints.maxWidth > 1024;

        return GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTwoCols ? 2 : 1,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            mainAxisExtent: 420,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            SptVsAchieved(),
            PurchaseTrendChart(),
            ReturnRateChart(),
            PnlByStoreChart(),
            WholesaleVsRetailTrendChart(),
            PurchaseReturnRateChart(),
            PnlByMonth(),
            SalespersonLeaderboard(),
            TargetAchievementChart(),
            TopCustomersChart(),
            SupplierPerformanceChart(),
            ChannelMixChart(),
            TrendChart(),
            BreakdownChart(),
            ChartCard(
              title: 'Top Products',
              subtitle: 'By gross revenue',
              exportLabel: 'top_products',
              action: _TopProductsDropdown(),
              child: _ProductsBarChart(),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String exportLabel;
  final Widget child;
  final Widget? action;

  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.exportLabel,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    const isDark = false; // Forced Light Mode

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAF5), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1D2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFFAAAEC8),
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[action!, const SizedBox(width: 12)],
              // Export buttons
              _ExportButton(
                icon: Icons.picture_as_pdf_outlined,
                label: 'PDF',
                color: const Color(0xFFEF4444),
                isDark: isDark,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _ExportButton(
                icon: Icons.table_chart_outlined,
                label: 'XLS',
                color: const Color(0xFF34D399),
                isDark: isDark,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Chart ─────────────────────────────────────────────────
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Charts
// ─────────────────────────────────────────────────────────────────────────────

class _TopProductsDropdown extends ConsumerWidget {
  const _TopProductsDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Forced Light Mode
    final limit = ref.watch(topProductsLimitProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E4EF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: limit,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Colors.black87,
          ),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
          onChanged: (val) =>
              ref.read(topProductsLimitProvider.notifier).state = val,
          items: const [
            // DropdownMenuItem(value: 5, child: Text('Top 5')),
            // DropdownMenuItem(value: 10, child: Text('Top 10')),
          ],
        ),
      ),
    );
  }
}

class _ProductsBarChart extends ConsumerWidget {
  const _ProductsBarChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelColor = const Color(0xFFB8BBCF);

    final topProductsAsync = ref.watch(topProductsProvider);
    final limit = ref.watch(topProductsLimitProvider);

    return topProductsAsync.when(
      skipLoadingOnReload: true,
      data: (products) {
        if (products == null || products.isEmpty) {
          return const Center(child: Text('No product data available'));
        }

        // Apply dynamic limit
        final displayProducts = limit != null
            ? products.take(limit).toList()
            : products;

        final maxRevenue = displayProducts.isEmpty
            ? 1000000.0
            : displayProducts
                  .map((e) => e.revenue)
                  .reduce((a, b) => a > b ? a : b);

        final bgToY = maxRevenue * 1.1;

        final colors = [
          Colors.teal,
          Colors.cyan,
          const Color(0xFF34D399),
          const Color(0xFFF59E0B),
          Colors.blueAccent,
          Colors.purpleAccent,
        ];

        // Adjust bar width based on count to avoid cramming
        final barWidth = displayProducts.length > 10 ? 12.0 : 22.0;

        return BarChart(
          BarChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: const Color(0xFFF0F1F8), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const Text('');
                    String label;
                    if (value >= 1000000) {
                      label = '${(value / 1000000).toStringAsFixed(1)}M';
                    } else if (value >= 1000) {
                      label = '${(value / 1000).toStringAsFixed(0)}k';
                    } else {
                      label = value.toStringAsFixed(0);
                    }
                    return Text(
                      '\$$label',
                      style: TextStyle(fontSize: 10, color: labelColor),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 55, // Extra space for rotated tags
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < displayProducts.length) {
                      return SideTitleWidget(
                        meta: meta,
                        space:
                            8, // Gives a buffer between the bar chart and the label
                        child: Transform.translate(
                          offset: const Offset(
                            -40,
                            0,
                          ), // Shift the label container leftwards slightly to be directly under the bar
                          child: Transform.rotate(
                            angle: -0.75, // ~45 degree angle
                            alignment: Alignment
                                .topRight, // Anchors the top right corner so it swings downward away from the chart
                            child: Container(
                              width: 60,
                              padding: const EdgeInsets.only(
                                right: 8.0,
                              ), // Adds a tiny gap to stop the text from touching the X-axis
                              child: Text(
                                displayProducts[idx].product,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  color: labelColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              displayProducts.length,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: displayProducts[i].revenue,
                    color: colors[i % colors.length],
                    width: barWidth,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: bgToY,
                      color: const Color(0xFFF5F6FD),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (err, stack) => Center(
        child: Text(
          'Error loading products',
          style: TextStyle(
            color: Colors.red.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
