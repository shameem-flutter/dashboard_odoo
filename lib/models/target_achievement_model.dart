class TargetAchievementModel {
  final List<String> labels;
  final List<double> data;

  TargetAchievementModel({
    required this.labels,
    required this.data,
  });

  factory TargetAchievementModel.fromJson(Map<String, dynamic> json) {
    return TargetAchievementModel(
      labels: List<String>.from(json['labels'] ?? []),
      data: List<num>.from(json['data'] ?? [])
          .map((e) => e.toDouble())
          .toList(),
    );
  }
}
