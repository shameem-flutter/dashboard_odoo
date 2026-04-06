import 'kpi_model.dart';

class SummaryModel {
  final double totalRevenue;
  final double totalOtherIncome;
  final double totalCost;
  final double totalProfit;
  final String topProduct;
  final String topSalesperson;
  final HealthCheck healthCheck;

  SummaryModel({
    required this.totalRevenue,
    required this.totalOtherIncome,
    required this.totalCost,
    required this.totalProfit,
    required this.topProduct,
    required this.topSalesperson,
    required this.healthCheck,
  });

  factory SummaryModel.fromJson(Map<String, dynamic> json) {
    return SummaryModel(
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalOtherIncome: (json['total_other_income'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (json['total_profit'] as num?)?.toDouble() ?? 0.0,
      topProduct: json['top_product'] ?? '',
      topSalesperson: json['top_salesperson'] ?? '',
      healthCheck: HealthCheck.fromJson(json['health_check'] ?? {}),
    );
  }
}
