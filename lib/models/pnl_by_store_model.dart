class PnlByStoreModel {
  final List<String> labels;
  final List<double> data;
  final String metric;
  final List<DetailedPnlByStore> detailed;

  PnlByStoreModel({
    required this.labels,
    required this.data,
    required this.metric,
    required this.detailed,
  });

  factory PnlByStoreModel.fromJson(Map<String, dynamic> json) {
    return PnlByStoreModel(
      labels: List<String>.from(json['labels'] ?? []),
      data: List<num>.from(json['data'] ?? [])
          .map((e) => e.toDouble())
          .toList(),
      metric: json['metric'] ?? '',
      detailed: (json['detailed'] as List<dynamic>?)
              ?.map((e) => DetailedPnlByStore.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DetailedPnlByStore {
  final String name;
  final double revenue;
  final double cost;
  final double profit;

  DetailedPnlByStore({
    required this.name,
    required this.revenue,
    required this.cost,
    required this.profit,
  });

  factory DetailedPnlByStore.fromJson(Map<String, dynamic> json) {
    return DetailedPnlByStore(
      name: json['name'] ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
