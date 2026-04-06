class SalespersonLeaderboardModel {
  final List<String> labels;
  final List<double> data;
  final String metric;
  final List<SalespersonLeaderboardDetailed> detailed;

  SalespersonLeaderboardModel({
    required this.labels,
    required this.data,
    required this.metric,
    required this.detailed,
  });

  factory SalespersonLeaderboardModel.fromJson(Map<String, dynamic> json) {
    return SalespersonLeaderboardModel(
      labels: List<String>.from(json['labels'] ?? []),
      data: (json['data'] as List?)
              ?.map((e) => (e is num) ? e.toDouble() : 0.0)
              .toList() ??
          [],
      metric: json['metric'] ?? 'Revenue',
      detailed: (json['detailed'] as List?)
              ?.map((e) => SalespersonLeaderboardDetailed.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SalespersonLeaderboardDetailed {
  final String name;
  final double revenue;
  final double cost;
  final double profit;

  SalespersonLeaderboardDetailed({
    required this.name,
    required this.revenue,
    required this.cost,
    required this.profit,
  });

  factory SalespersonLeaderboardDetailed.fromJson(Map<String, dynamic> json) {
    return SalespersonLeaderboardDetailed(
      name: json['name'] ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
