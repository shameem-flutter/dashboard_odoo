import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/riverpod_providers.dart';
import '../widgets/ai_summary_section.dart';
import '../widgets/charts_grid.dart';
import '../widgets/filters_bar.dart';
import '../widgets/header_bar.dart';
import '../widgets/kpi_row.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final compact = screenWidth < 760;
    
    // Check if the primary data provider is refreshing or loading to determine overall dashboard loading state
    final kpiState = ref.watch(kpiProvider);
    final isReloading = kpiState.isRefreshing || kpiState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F3),
      body: SafeArea(
        child: Column(
          children: [
            const HeaderBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 38,
                  compact ? 20 : 34,
                  compact ? 16 : 38,
                  compact ? 28 : 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   'Business Dashboard',
                    //   style: TextStyle(
                    //     fontSize: compact ? 30 : 44,
                    //     fontWeight: FontWeight.w800,
                    //     letterSpacing: -1.2,
                    //     color: isDark
                    //         ? const Color(0xFFF4F6FF)
                    //         : const Color(0xFF071B3A),
                    //   ),
                    // ),
                    AnimatedOpacity(
                      opacity: isReloading ? 0.4 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: const KpiRow(),
                    ),
                    SizedBox(height: compact ? 16 : 20),
                    const FiltersBar(),
                    SizedBox(height: compact ? 24 : 36),
                    Text(
                      'Performance Overview',
                      style: TextStyle(
                        fontSize: compact ? 20 : 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF071B3A),
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 16),
                    AnimatedOpacity(
                      opacity: isReloading ? 0.4 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AiSummarySection(),
                          SizedBox(height: compact ? 18 : 24),
                          const ChartsGrid(),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 24 : 36),

                    // const ProfitTrendByRegion(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
