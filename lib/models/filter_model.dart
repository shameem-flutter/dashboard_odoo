class FilterModel {
  final List<String> products;
  final List<String> stores;
  final List<String> salespersons;
  final List<String> channels;
  final List<String> customers;
  final List<String> transactionTypes;
  final List<String> valuationMethods;
  final List<String> dates;

  FilterModel({
    required this.products,
    required this.stores,
    required this.salespersons,
    required this.channels,
    required this.customers,
    required this.transactionTypes,
    required this.valuationMethods,
    required this.dates,
  });

  factory FilterModel.fromJson(Map<String, dynamic> json) {
    return FilterModel(
      products: List<String>.from(json['products'] ?? []),
      stores: List<String>.from(json['stores'] ?? []),
      salespersons: List<String>.from(json['salespersons'] ?? []),
      channels: List<String>.from(json['channels'] ?? []),
      customers: List<String>.from(json['customers'] ?? []),
      transactionTypes: List<String>.from(json['transaction_types'] ?? []),
      valuationMethods: List<String>.from(json['valuation_methods'] ?? []),
      dates: List<String>.from(json['dates'] ?? []),
    );
  }
}
