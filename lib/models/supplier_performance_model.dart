class SupplierDetail {
  final String name;
  final double revenue;
  final double cost;
  final double profit;
  final double purchaseValue;

  SupplierDetail({
    required this.name,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.purchaseValue,
  });

  factory SupplierDetail.fromJson(Map<String, dynamic> json) {
    return SupplierDetail(
      name: json['name'] ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      purchaseValue: (json['purchase_value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SupplierPerformanceModel {
  final List<String> labels;
  final List<double> data; // This seems to be Profit based on the metric field in JSON
  final String metric;
  final List<SupplierDetail> detailed;

  SupplierPerformanceModel({
    required this.labels,
    required this.data,
    required this.metric,
    required this.detailed,
  });

  factory SupplierPerformanceModel.fromJson(Map<String, dynamic> json) {
    return SupplierPerformanceModel(
      labels: List<String>.from(json['labels'] ?? []),
      data: List<double>.from((json['data'] as List<dynamic>?)?.map((e) => (e as num).toDouble()) ?? []),
      metric: json['metric'] ?? '',
      detailed: (json['detailed'] as List<dynamic>?)
              ?.map((e) => SupplierDetail.fromJson(e))
              .toList() ??
          [],
    );
  }
}
