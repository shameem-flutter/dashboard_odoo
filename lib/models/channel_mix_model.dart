class ChannelMixModel {
  final List<String> labels;
  final List<ChannelDataset> datasets;

  ChannelMixModel({
    required this.labels,
    required this.datasets,
  });

  factory ChannelMixModel.fromJson(Map<String, dynamic> json) {
    return ChannelMixModel(
      labels: List<String>.from(json['labels'] ?? []),
      datasets: (json['datasets'] as List? ?? [])
          .map((d) => ChannelDataset.fromJson(d))
          .toList(),
    );
  }
}

class ChannelDataset {
  final String label;
  final List<double> data;

  ChannelDataset({
    required this.label,
    required this.data,
  });

  factory ChannelDataset.fromJson(Map<String, dynamic> json) {
    return ChannelDataset(
      label: json['label'] ?? '',
      data: List<double>.from(
        (json['data'] as List? ?? []).map((x) => x?.toDouble() ?? 0.0),
      ),
    );
  }
}
