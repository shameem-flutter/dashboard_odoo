import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/riverpod_providers.dart';

class AiSummarySection extends ConsumerWidget {
  const AiSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(summaryProvider);
    // Dark mode removal: isDark is now always false
    const isDark = false;

    return summaryAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error: $e'),
      data: (summary) {
        if (summary == null) return const SizedBox.shrink();

        // Check if we actually have health data (API sometimes omits it)
        final hasHealthData =
            summary.healthCheck.totalRevenue > 0 ||
            summary.healthCheck.suspiciousMarginCount > 0 ||
            summary.healthCheck.zeroCostCount > 0;

        final hasIssues = hasHealthData && !summary.healthCheck.isHealthy;

        // Slightly refined colors to match the premium slate theme
        // final accentColor = hasIssues
        //     ? const Color(0xFFF59E0B)
        //     : const Color(0xFF10B981); // A slightly deeper, crisper emerald

        final bgColor = hasIssues
            ? (const Color(0xFFFFFBEB))
            : (const Color(0xFFF0FDF4));

        final borderColor = hasIssues
            ? (const Color(0xFFFDE68A))
            : (const Color(0xFFBBF7D0));

        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16), // Matched to 16px standard
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ), // 1.5px for crispness
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────────────────
              Row(
                children: [
                  // AI chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5450E8).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: Color(0xFF5450E8),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Color(0xFF5450E8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Wrapped in Expanded to prevent overflow on narrow screens!
                  Expanded(
                    child: Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Status badge
                ],
              ),

              const SizedBox(height: 16),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 16),

              // ── Stat pills ─────────────────────────────────────────
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatPill(
                    label: 'Top Product',
                    value: summary.topProduct,
                    icon: Icons.workspace_premium_outlined,
                    isDark: isDark,
                  ),
                  _StatPill(
                    label: 'Top Salesperson',
                    value: summary.topSalesperson,
                    icon: Icons.person_pin_outlined,
                    isDark: isDark,
                  ),
                  if (summary.totalOtherIncome > 0)
                    _StatPill(
                      label: 'Other Income',
                      value: '\$${summary.totalOtherIncome.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_outlined,
                      isDark: isDark,
                    ),
                ],
              ),

              // ── Alert section ──────────────────────────────────────
              if (hasIssues) ...[
                const SizedBox(height: 16),
                // Container(
                //   padding: const EdgeInsets.all(16),
                //   decoration: BoxDecoration(
                //   color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.1 : 0.05),
                //     borderRadius: BorderRadius.circular(12),
                //     border: Border.all(
                //       color: const Color(
                //         0xFFF59E0B,
                //       ).withValues(alpha: isDark ? 0.3 : 0.2),
                //       width: 1,
                //     ),
                //   ),
                //   child: Row(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       const Padding(
                //         padding: EdgeInsets.only(
                //           top: 2,
                //         ), // Aligns icon with first line of text
                //         child: Icon(
                //           Icons.warning_amber_rounded,
                //           size: 18,
                //           color: Color(0xFFF59E0B),
                //         ),
                //       ),
                //       const SizedBox(width: 12),
                //       // Expanded(
                //       //   child: RichText(
                //       //     text: TextSpan(
                //       //       style: TextStyle(
                //       //         fontSize: 14, // Bumped up for readability
                //       //         color: isDark
                //       //             ? const Color(0xFFDDE3F8)
                //       //             : const Color(0xFF334155),
                //       //         height: 1.5,
                //       //       ),
                //       //       children: [
                //       //         TextSpan(
                //       //           text:
                //       //               'Suspicious margins detected on ${summary.healthCheck.suspiciousMarginCount} item(s): ',
                //       //         ),
                //       //         TextSpan(
                //       //           text: summary.healthCheck.suspiciousMarginProducts
                //       //               .join(', '),
                //       //           style: const TextStyle(
                //       //             fontWeight: FontWeight.w700,
                //       //             color: Color(
                //       //               0xFFD97706,
                //       //             ), // Slightly darker amber for text contrast
                //       //           ),
                //       //         ),
                //       //       ],
                //       //     ),
                //       //   ),
                //       // ),
                //     ],
                //   ),
                // ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Determine screen width to give the pill a responsive max-width
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      // Ensure the pill doesn't stretch infinitely, but can fill half the screen on mobile
      constraints: BoxConstraints(
        maxWidth: screenWidth < 600 ? double.infinity : 240,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2135) : Colors.white,
        borderRadius: BorderRadius.circular(12), // Matched to 12px standard
        border: Border.all(
          color: isDark ? const Color(0xFF2D354A) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5450E8).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF5450E8)),
          ),
          const SizedBox(width: 12),
          // Flexible ensures long product/salesperson names truncate instead of breaking layout
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label, // Removed heavy uppercase
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF8F9BB3)
                        : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: isDark
                        ? const Color(0xFFF4F6FF)
                        : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
