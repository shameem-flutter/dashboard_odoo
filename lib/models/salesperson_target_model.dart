class SalespersonTargetModel {
  final List<String> labels;
  final List<TargetDataset> datasets;

  SalespersonTargetModel({
    required this.labels,
    required this.datasets,
  });

  factory SalespersonTargetModel.fromJson(Map<String, dynamic> json) {
    return SalespersonTargetModel(
      labels: List<String>.from(json['labels'] ?? []),
      datasets: (json['datasets'] as List? ?? [])
          .map((d) => TargetDataset.fromJson(d))
          .toList(),
    );
  }
}

class TargetDataset {
  final String label;
  final List<double> data;

  TargetDataset({
    required this.label,
    required this.data,
  });

  factory TargetDataset.fromJson(Map<String, dynamic> json) {
    return TargetDataset(
      label: json['label'] ?? '',
      data: (json['data'] as List? ?? [])
          .map((v) => (v as num).toDouble())
          .toList(),
    );
  }
}
