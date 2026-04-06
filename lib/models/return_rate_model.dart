class ReturnRateModel {
  final List<String> labels;
  final List<ReturnRateDataset> datasets;

  ReturnRateModel({
    required this.labels,
    required this.datasets,
  });

  factory ReturnRateModel.fromJson(Map<String, dynamic> json) {
    return ReturnRateModel(
      labels: List<String>.from(json['labels'] ?? []),
      datasets: (json['datasets'] as List? ?? [])
          .map((d) => ReturnRateDataset.fromJson(d))
          .toList(),
    );
  }
}

class ReturnRateDataset {
  final String label;
  final List<double> data;

  ReturnRateDataset({
    required this.label,
    required this.data,
  });

  factory ReturnRateDataset.fromJson(Map<String, dynamic> json) {
    return ReturnRateDataset(
      label: json['label'] ?? '',
      data: (json['data'] as List? ?? [])
          .map((v) => (v as num).toDouble())
          .toList(),
    );
  }
}
