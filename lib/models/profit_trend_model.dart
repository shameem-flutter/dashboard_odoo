class ProfitTrendModel {
  final List<String> labels;
  final List<ProfitDataset> datasets;

  ProfitTrendModel({
    required this.labels,
    required this.datasets,
  });

  factory ProfitTrendModel.fromJson(Map<String, dynamic> json) {
    return ProfitTrendModel(
      labels: List<String>.from(json['labels'] ?? []),
      datasets: (json['datasets'] as List? ?? [])
          .map((d) => ProfitDataset.fromJson(d))
          .toList(),
    );
  }
}

class ProfitDataset {
  final String label;
  final List<double> data;

  ProfitDataset({
    required this.label,
    required this.data,
  });

  factory ProfitDataset.fromJson(Map<String, dynamic> json) {
    return ProfitDataset(
      label: json['label'] ?? '',
      data: (json['data'] as List? ?? [])
          .map((v) => (v as num).toDouble())
          .toList(),
    );
  }
}
