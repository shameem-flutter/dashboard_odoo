import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/riverpod_providers.dart';

class TargetAchievementChart extends ConsumerStatefulWidget {
  const TargetAchievementChart({super.key});

  @override
  ConsumerState<TargetAchievementChart> createState() =>
      _TargetAchievementChartState();
}

class _TargetAchievementChartState
    extends ConsumerState<TargetAchievementChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(targetAchievementProvider);

    return asyncData.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (rawData) {
        final hasData = rawData != null && rawData.labels.isNotEmpty;

        if (!hasData) {
          return const Center(child: Text('No achievement data available'));
        }

        return Container(
          padding: const EdgeInsets.all(20),
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
              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  // const Text('🎯', style: TextStyle(fontSize: 22)),
                  // const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Salesperson Target Achievement % (${rawData.labels.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Optional: Show a hint
              const Text(
                'Tap on a bar to see exact percentage',
                style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 12),

              // ── Chart Area ──────────────────────────────────────────
              Expanded(
                child: Column(
                  children: [
                    // Rows
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: rawData.labels.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final name = rawData.labels[index];
                          final value = rawData.data[index];
                          final isTouched = _touchedIndex == index;
                          final isDimmed = _touchedIndex != null && !isTouched;

                          return _buildBarRow(
                            index,
                            name,
                            value,
                            isTouched,
                            isDimmed,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // X-Axis Labels
                    Row(
                      children: [
                        const SizedBox(
                          width: 140,
                        ), // Match label width + padding
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                '0',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                '50',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                '100',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                '150',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Footer ──────────────────────────────────────────────
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

  Widget _buildBarRow(
    int index,
    String name,
    double value,
    bool isTouched,
    bool isDimmed,
  ) {
    final displayedValue = value.clamp(0.0, 150.0);
    final barColor = value >= 100
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);

    return GestureDetector(
      onTap: () {
        setState(() {
          _touchedIndex = (_touchedIndex == index) ? null : index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDimmed ? 0.3 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              // Name Label
              SizedBox(
                width: 130,
                child: Text(
                  name,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isTouched ? FontWeight.w700 : FontWeight.w500,
                    color: isTouched
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Bar Container
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    final barWidth =
                        ((displayedValue / 150).clamp(0.01, 1.0) * totalWidth);

                    // Logic to ensure tooltip doesn't overflow
                    // If barWidth is large (> 70% of total), show it inside the bar
                    // Otherwise show it at the end
                    final showInside = barWidth > (totalWidth * 0.7);
                    final tooltipLeft = showInside
                        ? (barWidth - 65)
                        : barWidth + 8;

                    return Container(
                      height: 32,
                      alignment: Alignment.centerLeft,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        clipBehavior: Clip.none,
                        children: [
                          // Background Grid Lines
                          SizedBox(
                            width: totalWidth,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                4,
                                (_) => Container(
                                  width: 1,
                                  height: 28,
                                  color: const Color(0xFFF1F5F9),
                                ),
                              ),
                            ),
                          ),
                          // The Actual Bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            width: barWidth,
                            height: isTouched ? 28 : 22,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: isTouched
                                  ? [
                                      BoxShadow(
                                        color: barColor.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                              border: isTouched
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                            ),
                          ),
                          // Tooltip
                          if (isTouched)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              left: tooltipLeft.clamp(0.0, totalWidth - 50),
                              child: AnimatedOpacity(
                                opacity: 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: showInside
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${value.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: showInside
                                          ? const Color(0xFF1E293B)
                                          : Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
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
            ],
          ),
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
