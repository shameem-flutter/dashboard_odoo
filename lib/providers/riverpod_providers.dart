import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/filter_model.dart';
import '../models/kpi_model.dart';
import '../models/profit_trend_model.dart';
import '../models/purchase_return_rate_model.dart';
import '../models/purchase_trend_model.dart';
import '../models/return_rate_model.dart';
import '../models/salesperson_target_model.dart';
import '../models/summary_model.dart';
import '../models/pnl_by_month_model.dart';
import '../models/wholesale_vs_retail_model.dart';
import '../models/salesperson_leaderboard_model.dart';
import '../models/pnl_by_store_model.dart';
import '../models/target_achievement_model.dart';
import '../models/customer_top_model.dart';
import '../models/customer_insights_model.dart';
import '../models/top_product_model.dart';
import '../models/supplier_performance_model.dart';
import '../models/channel_mix_model.dart';
import '../models/trend_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

// ── Auth & API ──────────────────────────────────────────────────────────────

final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  final auth = AuthService();
  auth.init(); // Load persistent session data asynchronously
  return auth;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final auth = ref.watch(authServiceProvider);
  final api = ApiService();
  api.setSessionId(auth.currentAuth?.sessionId);
  return api;
});

// ── Selected Filters (immediate — UI state) ─────────────────────────────────

class SelectedFiltersNotifier extends StateNotifier<Map<String, String?>> {
  SelectedFiltersNotifier()
    : super({
        'product': null,
        'store': null,
        'salesperson': null,
        'channel': null,
        'customer': null,
        'transaction_type': null,
        'valuation_method': null,
        'tax_type': 'exclusive', // Default to exclusive to match user base data
        'start_date': null,
        'end_date': null,
      });

  void updateFilter(String filterKey, String? value) {
    state = {...state, filterKey: value};
  }

  void applyFilters(Map<String, String?> nextFilters) {
    state = {...state, ...nextFilters};
  }

  void clearFilters() {
    state = {
      for (final key in state.keys) key: null,
      'tax_type': 'exclusive', // Reset to exclusive to match local UI state
    };
  }
}

final selectedFiltersProvider =
    StateNotifierProvider<SelectedFiltersNotifier, Map<String, String?>>((ref) {
      return SelectedFiltersNotifier();
    });

// ── Debounced Filters ───────────────────────────────────────────────────────
/// Propagates filter changes only after a period of silence.
/// All data FutureProviders must watch THIS provider — not selectedFiltersProvider —
/// so that rapid filter changes are batched into a single API burst.

class DebouncedFiltersNotifier extends StateNotifier<Map<String, String?>> {
  Timer? _timer;
  final Duration delay;

  DebouncedFiltersNotifier(
    super.initialState, {
    this.delay = const Duration(milliseconds: 200),
  });

  void schedule(Map<String, String?> newFilters) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      if (mounted) {
        state = newFilters;
      }
    });
  }

  /// Immediately apply filters without debounce (for reset, etc.)
  void applyNow(Map<String, String?> newFilters) {
    _timer?.cancel();
    state = newFilters;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final debouncedFiltersProvider =
    StateNotifierProvider<DebouncedFiltersNotifier, Map<String, String?>>((
      ref,
    ) {
      final initial = ref.read(selectedFiltersProvider);
      final notifier = DebouncedFiltersNotifier(initial);
      ref.listen<Map<String, String?>>(
        selectedFiltersProvider,
        (_, next) => notifier.schedule(next),
      );
      return notifier;
    });

// ── Fast-debounced filters for cascading filter dropdowns ───────────────────
/// This uses a much shorter debounce (80ms) so filter dropdown options
/// update near-instantly when user changes Filter A, while still batching
/// truly simultaneous changes (like clearFilters).
final _fastDebouncedFiltersProvider =
    StateNotifierProvider<DebouncedFiltersNotifier, Map<String, String?>>((
      ref,
    ) {
      final initial = ref.read(selectedFiltersProvider);
      final notifier = DebouncedFiltersNotifier(
        initial,
        delay: const Duration(milliseconds: 80),
      );
      ref.listen<Map<String, String?>>(
        selectedFiltersProvider,
        (_, next) => notifier.schedule(next),
      );
      return notifier;
    });

// ── Available Filters (cascading, fast-debounced) ───────────────────────────
/// Uses the fast-debounced provider so dropdown options update quickly
/// when user changes one filter, without waiting for the full data debounce.
final availableFiltersProvider = FutureProvider<FilterModel?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(_fastDebouncedFiltersProvider);
  return apiService.fetchFilters(filters);
});

// ── KPIs ────────────────────────────────────────────────────────────────────
final kpiProvider = FutureProvider<KpiModel?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  return apiService.fetchKpis(filters);
});

// ── Summary ─────────────────────────────────────────────────────────────────
final summaryProvider = FutureProvider<SummaryModel?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  return apiService.fetchSummary(filters);
});

// ── Profit Trend by Region ──────────────────────────────────────────────────
final profitTrendProvider = FutureProvider<ProfitTrendModel?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  return apiService.fetchProfitTrendByRegion(filters);
});

// ── Salesperson Targets ─────────────────────────────────────────────────────
final salespersonTargetProvider = FutureProvider<SalespersonTargetModel?>((
  ref,
) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  return apiService.fetchSalespersonTargets(filters);
});

// ── Purchase Trend ──────────────────────────────────────────────────────────
final purchaseTrendProvider = FutureProvider<PurchaseTrendModel?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  final rawData = await apiService.fetchPurchaseTrend(filters);
  if (rawData == null) return null;

  // Local filtering & sorting
  final labels = List<String>.from(rawData.labels);
  final datasets = rawData.datasets;

  final startDate = filters['start_date'];
  final endDate = filters['end_date'];
  final startMonth = (startDate != null && startDate.length >= 7)
      ? startDate.substring(0, 7)
      : null;
  final endMonth = (endDate != null && endDate.length >= 7)
      ? endDate.substring(0, 7)
      : null;

  List<int> validIndices = [];
  for (int i = 0; i < labels.length; i++) {
    bool isWithin = true;
    if (startMonth != null && labels[i].compareTo(startMonth) < 0) {
      isWithin = false;
    }
    if (endMonth != null && labels[i].compareTo(endMonth) > 0) isWithin = false;
    if (isWithin) validIndices.add(i);
  }
  validIndices.sort((a, b) => labels[a].compareTo(labels[b]));

  return PurchaseTrendModel(
    labels: validIndices.map((i) => labels[i]).toList(),
    datasets: datasets
        .map(
          (ds) => PurchaseTrendDataset(
            label: ds.label,
            data: validIndices.map((i) => ds.data[i]).toList(),
            backgroundColor: ds.backgroundColor,
          ),
        )
        .toList(),
  );
});

// ── Return Rates ────────────────────────────────────────────────────────────
final returnRateProvider = FutureProvider<ReturnRateModel?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  return apiService.fetchReturnRate(filters);
});

final purchaseReturnRateProvider = FutureProvider<PurchaseReturnRateModel?>((
  ref,
) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  return apiService.fetchPurchaseReturnRate(filters);
});

// ── P&L by Month ────────────────────────────────────────────────────────────
final pnlByMonthProvider = FutureProvider<PnlByMonthModel?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  final rawData = await apiService.fetchPnlByMonth(filters);
  if (rawData == null) return null;

  // Local filtering & sorting
  final labels = List<String>.from(rawData.labels);
  final datasets = rawData.datasets;

  final startDate = filters['start_date'];
  final endDate = filters['end_date'];
  final startMonth = (startDate != null && startDate.length >= 7)
      ? startDate.substring(0, 7)
      : null;
  final endMonth = (endDate != null && endDate.length >= 7)
      ? endDate.substring(0, 7)
      : null;

  List<int> validIndices = [];
  for (int i = 0; i < labels.length; i++) {
    bool isWithin = true;
    if (startMonth != null && labels[i].compareTo(startMonth) < 0) {
      isWithin = false;
    }
    if (endMonth != null && labels[i].compareTo(endMonth) > 0) isWithin = false;
    if (isWithin) validIndices.add(i);
  }
  validIndices.sort((a, b) => labels[a].compareTo(labels[b]));

  return PnlByMonthModel(
    labels: validIndices.map((i) => labels[i]).toList(),
    datasets: datasets
        .map(
          (ds) => PnlByMonthDataset(
            label: ds.label,
            data: validIndices.map((i) => ds.data[i]).toList(),
          ),
        )
        .toList(),
  );
});

// ── Wholesale vs Retail ─────────────────────────────────────────────────────
final wholesaleVsRetailProvider = FutureProvider<WholesaleVsRetailModel?>((
  ref,
) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  final rawData = await apiService.fetchWholesaleVsRetail(filters);
  if (rawData == null) return null;

  // Local filtering & sorting
  final labels = List<String>.from(rawData.labels);
  final datasets = rawData.datasets;

  final startDate = filters['start_date'];
  final endDate = filters['end_date'];
  final startMonth = (startDate != null && startDate.length >= 7)
      ? startDate.substring(0, 7)
      : null;
  final endMonth = (endDate != null && endDate.length >= 7)
      ? endDate.substring(0, 7)
      : null;

  List<int> validIndices = [];
  for (int i = 0; i < labels.length; i++) {
    bool isWithin = true;
    if (startMonth != null && labels[i].compareTo(startMonth) < 0) {
      isWithin = false;
    }
    if (endMonth != null && labels[i].compareTo(endMonth) > 0) isWithin = false;
    if (isWithin) validIndices.add(i);
  }
  validIndices.sort((a, b) => labels[a].compareTo(labels[b]));

  return WholesaleVsRetailModel(
    labels: validIndices.map((i) => labels[i]).toList(),
    datasets: datasets
        .map(
          (ds) => WholesaleVsRetailDataset(
            label: ds.label,
            data: validIndices.map((i) => ds.data[i]).toList(),
          ),
        )
        .toList(),
  );
});

// ── Salesperson Leaderboard ─────────────────────────────────────────────────
final salespersonLeaderboardProvider =
    FutureProvider<SalespersonLeaderboardModel?>((ref) async {
      final apiService = ref.watch(apiServiceProvider);
      final filters = ref.watch(debouncedFiltersProvider);
      return apiService.fetchSalespersonLeaderboard(filters);
    });

// ── P&L by Store ────────────────────────────────────────────────────────────
final pnlByStoreProvider = FutureProvider<PnlByStoreModel?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  return apiService.fetchPnlByStore(filters);
});

// ── Target Achievement ──────────────────────────────────────────────────────
final targetAchievementProvider = FutureProvider<TargetAchievementModel?>((
  ref,
) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  return apiService.fetchTargetAchievement(filters);
});

// ── Top Customers ───────────────────────────────────────────────────────────
final customerTopProvider = FutureProvider<List<CustomerTopModel>?>((
  ref,
) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  return apiService.fetchCustomerTop(filters);
});

// ── Customer Insights ───────────────────────────────────────────────────────
final customerInsightsProvider = FutureProvider<CustomerInsightsModel?>((
  ref,
) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  return apiService.fetchCustomerInsights(filters);
});

// ── Top Products ────────────────────────────────────────────────────────────
final topProductsLimitProvider = StateProvider<int?>((ref) => 10);

final topProductsProvider = FutureProvider<List<TopProductModel>?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  return apiService.fetchTopProducts(filters);
});

// ── Supplier Performance ────────────────────────────────────────────────────
final supplierPerformanceProvider = FutureProvider<SupplierPerformanceModel?>((
  ref,
) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  return apiService.fetchSupplierPerformance(filters);
});

// ── Channel Mix ─────────────────────────────────────────────────────────────
final channelMixProvider = FutureProvider<ChannelMixModel?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  final rawData = await apiService.fetchChannelMix(filters);
  if (rawData == null) return null;

  // Local filtering & sorting
  final labels = List<String>.from(rawData.labels);
  final datasets = rawData.datasets;

  // 1. Get indices within range
  final startDate = filters['start_date'];
  final endDate = filters['end_date'];
  final startMonth = (startDate != null && startDate.length >= 7)
      ? startDate.substring(0, 7)
      : null;
  final endMonth = (endDate != null && endDate.length >= 7)
      ? endDate.substring(0, 7)
      : null;

  List<int> validIndices = [];
  for (int i = 0; i < labels.length; i++) {
    bool isWithin = true;
    if (startMonth != null && labels[i].compareTo(startMonth) < 0) {
      isWithin = false;
    }
    if (endMonth != null && labels[i].compareTo(endMonth) > 0) isWithin = false;
    if (isWithin) validIndices.add(i);
  }

  // 2. Sort valid indices by label
  validIndices.sort((a, b) => labels[a].compareTo(labels[b]));

  // 3. Rebuild model
  return ChannelMixModel(
    labels: validIndices.map((i) => labels[i]).toList(),
    datasets: datasets
        .map(
          (ds) => ChannelDataset(
            label: ds.label,
            data: validIndices.map((i) => ds.data[i]).toList(),
          ),
        )
        .toList(),
  );
});

// ── Trend ───────────────────────────────────────────────────────────────────
final trendProvider = FutureProvider<List<TrendModel>?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  final rawData = await apiService.fetchTrend(filters);
  if (rawData == null) return null;

  // Local filtering & sorting
  List<TrendModel> data = List.from(rawData);
  data.sort((a, b) => a.month.compareTo(b.month));

  final startDate = filters['start_date'];
  final endDate = filters['end_date'];
  final startMonth = (startDate != null && startDate.length >= 7)
      ? startDate.substring(0, 7)
      : null;
  final endMonth = (endDate != null && endDate.length >= 7)
      ? endDate.substring(0, 7)
      : null;

  if (startMonth != null) {
    data = data.where((item) => item.month.compareTo(startMonth) >= 0).toList();
  }
  if (endMonth != null) {
    data = data.where((item) => item.month.compareTo(endMonth) <= 0).toList();
  }

  return data;
});

// ── Breakdown ───────────────────────────────────────────────────────────────
final breakdownProvider = FutureProvider<List<TopProductModel>?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final filters = ref.watch(debouncedFiltersProvider);
  return apiService.fetchBreakdown(filters);
});

// ── PnL Dataset Selector ────────────────────────────────────────────────────
class PnlDatasetNotifier extends StateNotifier<String> {
  PnlDatasetNotifier() : super('Profit');

  void updateDataset(String dataset) {
    state = dataset;
  }
}

final selectedPnlDatasetProvider =
    StateNotifierProvider<PnlDatasetNotifier, String>((ref) {
      return PnlDatasetNotifier();
    });
