/// Model for the /api/customer-insights/ endpoint.
///
/// Response schema:
/// {
///   "labels": ["string"],
///   "data":   [double],
///   "metric": "string"
/// }
/// labels[i] and data[i] are parallel arrays (same length).
class CustomerInsightsModel {
  final List<String> labels;
  final List<double> data;
  final String metric;

  const CustomerInsightsModel({
    required this.labels,
    required this.data,
    required this.metric,
  });

  /// Returns the number of entries. Guaranteed: labels.length == data.length.
  int get length => labels.length;

  factory CustomerInsightsModel.fromJson(Map<String, dynamic> json) {
    final rawLabels = json['labels'] as List<dynamic>? ?? [];
    final rawData = json['data'] as List<dynamic>? ?? [];

    // Guard: truncate to the shorter array to avoid index-out-of-bounds
    final count =
        rawLabels.length < rawData.length ? rawLabels.length : rawData.length;

    return CustomerInsightsModel(
      labels: List<String>.generate(count, (i) => rawLabels[i]?.toString() ?? ''),
      data: List<double>.generate(
        count,
        (i) => (rawData[i] as num?)?.toDouble() ?? 0.0,
      ),
      metric: json['metric']?.toString() ?? 'Revenue',
    );
  }
}
