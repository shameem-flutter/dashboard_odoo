class WholesaleVsRetailModel {
  final List<String> labels;
  final List<WholesaleVsRetailDataset> datasets;

  WholesaleVsRetailModel({
    required this.labels,
    required this.datasets,
  });

  factory WholesaleVsRetailModel.fromJson(Map<String, dynamic> json) {
    return WholesaleVsRetailModel(
      labels: List<String>.from(json['labels'] ?? []),
      datasets: (json['datasets'] as List?)
              ?.map((e) => WholesaleVsRetailDataset.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class WholesaleVsRetailDataset {
  final String label;
  final List<double> data;

  WholesaleVsRetailDataset({
    required this.label,
    required this.data,
  });

  factory WholesaleVsRetailDataset.fromJson(Map<String, dynamic> json) {
    return WholesaleVsRetailDataset(
      label: json['label'] ?? '',
      data: (json['data'] as List?)
              ?.map((e) => (e is num) ? e.toDouble() : 0.0)
              .toList() ??
          [],
    );
  }
}
