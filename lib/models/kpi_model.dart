class KpiModel {
  final double grossRevenue;
  final double totalRevenue;
  final double totalReturns;
  final double netRevenue;
  final double totalCost;
  final double totalProfit;
  final double totalQuantity;
  final double returnQuantity;
  final double achievementPct;
  final HealthCheck healthCheck;

  KpiModel({
    required this.grossRevenue,
    required this.totalRevenue,
    required this.totalReturns,
    required this.netRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.totalQuantity,
    required this.returnQuantity,
    required this.achievementPct,
    required this.healthCheck,
  });

  factory KpiModel.fromJson(Map<String, dynamic> json) {
    return KpiModel(
      grossRevenue: (json['gross_revenue'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalReturns: (json['total_returns'] as num?)?.toDouble() ?? 0.0,
      netRevenue: (json['net_revenue'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (json['total_profit'] as num?)?.toDouble() ?? 0.0,
      totalQuantity: (json['total_quantity'] as num?)?.toDouble() ?? 0.0,
      returnQuantity: (json['return_quantity'] as num?)?.toDouble() ?? 0.0,
      achievementPct: (json['achievement_pct'] as num?)?.toDouble() ?? 0.0,
      healthCheck: HealthCheck.fromJson(json['health_check'] ?? {}),
    );
  }
}

class HealthCheck {
  final bool isHealthy;
  final int zeroCostCount;
  final int suspiciousMarginCount;
  final List<String> zeroCostProducts;
  final List<String> suspiciousMarginProducts;
  final double totalRevenue;

  HealthCheck({
    required this.isHealthy,
    required this.zeroCostCount,
    required this.suspiciousMarginCount,
    required this.zeroCostProducts,
    required this.suspiciousMarginProducts,
    required this.totalRevenue,
  });

  factory HealthCheck.fromJson(Map<String, dynamic> json) {
    return HealthCheck(
      isHealthy: json['is_healthy'] ?? false,
      zeroCostCount: json['zero_cost_count'] ?? 0,
      suspiciousMarginCount: json['suspicious_margin_count'] ?? 0,
      zeroCostProducts: List<String>.from(json['zero_cost_products'] ?? []),
      suspiciousMarginProducts: List<String>.from(json['suspicious_margin_products'] ?? []),
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
