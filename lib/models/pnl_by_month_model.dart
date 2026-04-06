class PnlByMonthModel {
  final List<String> labels;
  final List<PnlByMonthDataset> datasets;

  PnlByMonthModel({
    required this.labels,
    required this.datasets,
  });

  factory PnlByMonthModel.fromJson(Map<String, dynamic> json) {
    return PnlByMonthModel(
      labels: List<String>.from(json['labels'] ?? []),
      datasets: (json['datasets'] as List? ?? [])
          .map((d) => PnlByMonthDataset.fromJson(d))
          .toList(),
    );
  }
}

class PnlByMonthDataset {
  final String label;
  final List<double> data;

  PnlByMonthDataset({
    required this.label,
    required this.data,
  });

  factory PnlByMonthDataset.fromJson(Map<String, dynamic> json) {
    return PnlByMonthDataset(
      label: json['label'] ?? '',
      data: (json['data'] as List? ?? [])
          .map((v) => (v as num).toDouble())
          .toList(),
    );
  }
}
