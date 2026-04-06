class TrendModel {
  final String month;
  final double revenue;
  final double profit;

  TrendModel({
    required this.month,
    required this.revenue,
    required this.profit,
  });

  factory TrendModel.fromJson(Map<String, dynamic> json) {
    return TrendModel(
      month: json['Month'] ?? '',
      revenue: (json['Revenue'] as num?)?.toDouble() ?? 0.0,
      profit: (json['Profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
