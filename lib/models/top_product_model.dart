class TopProductModel {
  final String product;
  final double revenue;

  TopProductModel({
    required this.product,
    required this.revenue,
  });

  factory TopProductModel.fromJson(Map<String, dynamic> json) {
    return TopProductModel(
      product: json['Product'] ?? '',
      revenue: (json['Revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Product': product,
      'Revenue': revenue,
    };
  }
}
