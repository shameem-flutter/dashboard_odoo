class PurchaseReturnRateModel {
  final List<String> labels;
  final List<PurchaseReturnRateDataset> datasets;

  PurchaseReturnRateModel({
    required this.labels,
    required this.datasets,
  });

  factory PurchaseReturnRateModel.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnRateModel(
      labels: List<String>.from(json['labels'] ?? []),
      datasets: (json['datasets'] as List? ?? [])
          .map((d) => PurchaseReturnRateDataset.fromJson(d))
          .toList(),
    );
  }
}

class PurchaseReturnRateDataset {
  final String label;
  final List<double> data;

  PurchaseReturnRateDataset({
    required this.label,
    required this.data,
  });

  factory PurchaseReturnRateDataset.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnRateDataset(
      label: json['label'] ?? '',
      data: (json['data'] as List? ?? [])
          .map((v) => (v as num).toDouble())
          .toList(),
    );
  }
}
