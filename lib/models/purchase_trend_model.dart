class PurchaseTrendModel {
  final List<String> labels;
  final List<PurchaseTrendDataset> datasets;

  PurchaseTrendModel({
    required this.labels,
    required this.datasets,
  });

  factory PurchaseTrendModel.fromJson(Map<String, dynamic> json) {
    return PurchaseTrendModel(
      labels: List<String>.from(json['labels'] ?? []),
      datasets: (json['datasets'] as List? ?? [])
          .map((d) => PurchaseTrendDataset.fromJson(d))
          .toList(),
    );
  }
}

class PurchaseTrendDataset {
  final String label;
  final List<double> data;
  final String backgroundColor;

  PurchaseTrendDataset({
    required this.label,
    required this.data,
    required this.backgroundColor,
  });

  factory PurchaseTrendDataset.fromJson(Map<String, dynamic> json) {
    return PurchaseTrendDataset(
      label: json['label'] ?? '',
      data: (json['data'] as List? ?? [])
          .map((v) => (v as num).toDouble())
          .toList(),
      backgroundColor: json['backgroundColor'] ?? '#000000',
    );
  }
}
