class CustomerTopModel {
  final String customer;
  final double revenue;
  final double profit;
  final double cost;

  CustomerTopModel({
    required this.customer,
    required this.revenue,
    required this.profit,
    required this.cost,
  });

  factory CustomerTopModel.fromJson(Map<String, dynamic> json) {
    return CustomerTopModel(
      customer: json['Customer'] ?? json['Product'] ?? '',
      revenue: (json['Revenue'] as num?)?.toDouble() ?? 0.0,
      profit: (json['Profit'] as num?)?.toDouble() ?? 0.0,
      cost: (json['Cost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static List<CustomerTopModel> fromBulkJson(Map<String, dynamic> json) {
    final labels = (json['labels'] as List<dynamic>?) ?? [];
    final revenues = (json['revenue'] as List<dynamic>?) ?? [];
    final profits = (json['profit'] as List<dynamic>?) ?? [];

    final List<CustomerTopModel> results = [];
    for (int i = 0; i < labels.length; i++) {
      results.add(CustomerTopModel(
        customer: labels[i].toString(),
        revenue: (revenues[i] as num?)?.toDouble() ?? 0.0,
        profit: (profits.length > i) ? (profits[i] as num?)?.toDouble() ?? 0.0 : 0.0,
        cost: 0.0, // Cost not provided in bulk JSON
      ));
    }
    return results;
  }
}
