import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/kpi_model.dart';
import '../models/summary_model.dart';
import '../models/filter_model.dart';
import '../models/profit_trend_model.dart';
import '../models/salesperson_target_model.dart';
import '../models/purchase_trend_model.dart';
import '../models/return_rate_model.dart';
import '../models/purchase_return_rate_model.dart';
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

import 'api_constants.dart';

// ── Throttled request queue ─────────────────────────────────────────────────
/// Limits concurrent HTTP requests to avoid overwhelming the Odoo server.
/// Requests are processed in FIFO order with a configurable concurrency limit.
class _RequestQueue {
  final int maxConcurrent;
  int _active = 0;
  final _queue = <Completer<void>>[];

  _RequestQueue({this.maxConcurrent = 3});

  Future<T> run<T>(Future<T> Function() task) async {
    // Wait for a slot to become available
    if (_active >= maxConcurrent) {
      final completer = Completer<void>();
      _queue.add(completer);
      await completer.future;
    }

    _active++;
    try {
      return await task();
    } finally {
      _active--;
      // Release next waiting request
      if (_queue.isNotEmpty) {
        _queue.removeAt(0).complete();
      }
    }
  }
}

/// Central service that handles every API call in the application.
///
/// Endpoint paths are maintained in [ApiConstants] — update that file
/// whenever a URL changes so this class stays free of raw strings.
///
/// Uses a throttled request queue to limit concurrent requests to 3,
/// preventing the Odoo server from being overwhelmed when many providers
/// fire simultaneously after a filter change.
class ApiService {
  final http.Client _client = http.Client();
  String? _sessionId;

  // Throttle concurrent requests: max 3 at a time to avoid server overload
  final _queue = _RequestQueue(maxConcurrent: 3);

  void setSessionId(String? sessionId) {
    _sessionId = sessionId;
  }

  // ── Auth headers ───────────────────────────────────────────────────────────
  Map<String, String> _getHeaders({bool includeContentType = true}) {
    final headers = {
      'Cookie': 'session_id=${_sessionId ?? ""}',
    };
    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  // ── URI builder ────────────────────────────────────────────────────────────
  /// Builds a [Uri] from an endpoint path and an optional filter map.
  /// Filters with null or empty values are ignored.
  Uri _buildUri(String path, Map<String, dynamic>? filters) {
    final base = Uri.parse('${ApiConstants.baseUrl}$path');

    final queryParameters = <String, String>{};

    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          queryParameters[key] = value.toString();
        }
      });
    }

    final uri = queryParameters.isEmpty
        ? base
        : base.replace(queryParameters: queryParameters);
    
    return uri;
  }

  // ── Generic GET helper ────────────────────────────────────────────────────
  /// Performs a throttled GET request and returns the decoded JSON body,
  /// or [null] on non-200 responses and network errors.
  /// JSON parsing is done inline (no isolate) since responses are typically
  /// small enough that isolate spawn overhead (~20-50ms) is worse than
  /// inline parsing.
  Future<Map<String, dynamic>?> _getJson(
    String path, {
    Map<String, dynamic>? filters,
    required String label,
  }) async {
    return _queue.run(() async {
      try {
        final uri = _buildUri(path, filters);
        final headers = _getHeaders(includeContentType: false);
        
        final response = await _client.get(uri, headers: headers);

        if (response.statusCode == 200) {
          // Inline decode — faster than compute() for typical dashboard payloads
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        debugPrint('Failed to load $label: ${response.statusCode}');
        return null;
      } catch (e) {
        debugPrint('Error fetching $label: $e');
        return null;
      }
    });
  }

  // ── Generic throttled GET for list/other responses ────────────────────────
  Future<http.Response?> _throttledGet(Uri uri) async {
    return _queue.run(() async {
      try {
        final headers = _getHeaders(includeContentType: false);
        final response = await _client.get(uri, headers: headers);
        return response;
      } catch (e) {
        debugPrint('Error in throttled GET: $e');
        return null;
      }
    });
  }

  // ── KPIs ───────────────────────────────────────────────────────────────────
  Future<KpiModel?> fetchKpis(Map<String, dynamic>? currentFilters) async {
    final data = await _getJson(
      ApiConstants.kpis,
      filters: currentFilters,
      label: 'KPIs',
    );
    return data != null ? KpiModel.fromJson(data) : null;
  }

  // ── Summary ────────────────────────────────────────────────────────────────
  Future<SummaryModel?> fetchSummary(
    Map<String, dynamic>? currentFilters,
  ) async {
    final data = await _getJson(
      ApiConstants.summary,
      filters: currentFilters,
      label: 'Summary',
    );
    return data != null ? SummaryModel.fromJson(data) : null;
  }

  // ── Filters ────────────────────────────────────────────────────────────────
  /// Filters are fetched WITHOUT throttle queue to ensure cascading filter
  /// dropdowns update as fast as possible — they should never wait behind
  /// chart data requests.
  Future<FilterModel?> fetchFilters(Map<String, dynamic>? currentFilters) async {
    try {
      final uri = _buildUri(ApiConstants.filters, currentFilters);
      final headers = _getHeaders(includeContentType: false);
      final response = await _client.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return FilterModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      debugPrint('Failed to load Filters: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error fetching Filters: $e');
      return null;
    }
  }

  // ── Profit Trend by Region ─────────────────────────────────────────────────
  Future<ProfitTrendModel?> fetchProfitTrendByRegion(
    Map<String, dynamic>? currentFilters,
  ) async {
    final data = await _getJson(
      ApiConstants.profitTrendRegion,
      filters: currentFilters,
      label: 'Profit Trend',
    );
    return data != null ? ProfitTrendModel.fromJson(data) : null;
  }

  // ── Salesperson Targets ────────────────────────────────────────────────────
  Future<SalespersonTargetModel?> fetchSalespersonTargets(
    Map<String, dynamic>? currentFilters,
  ) async {
    final data = await _getJson(
      ApiConstants.salespersonTargets,
      filters: currentFilters,
      label: 'Salesperson Targets',
    );
    return data != null ? SalespersonTargetModel.fromJson(data) : null;
  }

  // ── Purchase Trend ─────────────────────────────────────────────────────────
  Future<PurchaseTrendModel?> fetchPurchaseTrend(
    Map<String, dynamic>? currentFilters,
  ) async {
    final data = await _getJson(
      ApiConstants.purchaseTrend,
      filters: currentFilters,
      label: 'Purchase Trend',
    );
    return data != null ? PurchaseTrendModel.fromJson(data) : null;
  }

  // ── Sales Return Rate ──────────────────────────────────────────────────────
  Future<ReturnRateModel?> fetchReturnRate(
    Map<String, dynamic>? currentFilters,
  ) async {
    final data = await _getJson(
      ApiConstants.returnRate,
      filters: currentFilters,
      label: 'Return Rate',
    );
    return data != null ? ReturnRateModel.fromJson(data) : null;
  }

  // ── Purchase Return Rate ───────────────────────────────────────────────────
  Future<PurchaseReturnRateModel?> fetchPurchaseReturnRate(
    Map<String, dynamic>? currentFilters,
  ) async {
    final data = await _getJson(
      ApiConstants.purchaseReturnRate,
      filters: currentFilters,
      label: 'Purchase Return Rate',
    );
    return data != null ? PurchaseReturnRateModel.fromJson(data) : null;
  }

  // ── P&L by Month ──────────────────────────────────────────────────────────
  Future<PnlByMonthModel?> fetchPnlByMonth(
    Map<String, dynamic>? currentFilters,
  ) async {
    final data = await _getJson(
      ApiConstants.pnlByMonth,
      filters: currentFilters,
      label: 'P&L by Month',
    );
    return data != null ? PnlByMonthModel.fromJson(data) : null;
  }

  // ── Wholesale vs Retail ───────────────────────────────────────────────────
  Future<WholesaleVsRetailModel?> fetchWholesaleVsRetail(
    Map<String, dynamic>? currentFilters,
  ) async {
    final data = await _getJson(
      ApiConstants.wholesaleVsRetail,
      filters: currentFilters,
      label: 'Wholesale vs Retail',
    );
    return data != null ? WholesaleVsRetailModel.fromJson(data) : null;
  }

  // ── Salesperson Leaderboard ───────────────────────────────────────────────
  Future<SalespersonLeaderboardModel?> fetchSalespersonLeaderboard(
    Map<String, dynamic>? currentFilters,
  ) async {
    final data = await _getJson(
      ApiConstants.salespersonLeaderboard,
      filters: currentFilters,
      label: 'Salesperson Leaderboard',
    );
    return data != null ? SalespersonLeaderboardModel.fromJson(data) : null;
  }

  // ── P&L by Store ──────────────────────────────────────────────────────────
  Future<PnlByStoreModel?> fetchPnlByStore(
    Map<String, dynamic>? currentFilters,
  ) async {
    final data = await _getJson(
      ApiConstants.pnlByStore,
      filters: currentFilters,
      label: 'P&L by Store',
    );
    return data != null ? PnlByStoreModel.fromJson(data) : null;
  }

  // ── Target Achievement % ──────────────────────────────────────────────────
  Future<TargetAchievementModel?> fetchTargetAchievement(
    Map<String, dynamic>? currentFilters,
  ) async {
    final data = await _getJson(
      ApiConstants.targetAchievement,
      filters: currentFilters,
      label: 'Target Achievement',
    );
    return data != null ? TargetAchievementModel.fromJson(data) : null;
  }

  // ── Top Customers by Revenue ──────────────────────────────────────────────
  Future<List<CustomerTopModel>?> fetchCustomerTop(
    Map<String, dynamic>? currentFilters,
  ) async {
    final uri = _buildUri(ApiConstants.customerTop, currentFilters);
    final response = await _throttledGet(uri);
    if (response == null) return null;
    try {
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return CustomerTopModel.fromBulkJson(decoded);
        } else if (decoded is List) {
          return decoded.map((e) => CustomerTopModel.fromJson(e)).toList();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing CustomerTop: $e');
      return null;
    }
  }

  // ── Customer Insights ─────────────────────────────────────────────────────
  Future<CustomerInsightsModel?> fetchCustomerInsights(
    Map<String, dynamic>? currentFilters,
  ) async {
    final data = await _getJson(
      ApiConstants.customerInsights,
      filters: currentFilters,
      label: 'Customer Insights',
    );
    if (data == null) return null;

    final model = CustomerInsightsModel.fromJson(data);
    // Guard: return null so the UI shows "No data" instead of an empty grid
    if (model.length == 0) return null;
    return model;
  }

  // ── Top Products ──────────────────────────────────────────────────────────
  Future<List<TopProductModel>?> fetchTopProducts(
    Map<String, dynamic>? currentFilters,
  ) async {
    final uri = _buildUri(ApiConstants.topProducts, currentFilters);
    final response = await _throttledGet(uri);
    if (response == null) return null;
    try {
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        return list.map((e) => TopProductModel.fromJson(e)).toList();
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing TopProducts: $e');
      return null;
    }
  }

  // ── Supplier Performance ──────────────────────────────────────────────────
  Future<SupplierPerformanceModel?> fetchSupplierPerformance(
    Map<String, dynamic>? currentFilters,
  ) async {
    final uri = _buildUri(ApiConstants.supplierPerformance, currentFilters);
    final response = await _throttledGet(uri);
    if (response == null) return null;
    try {
      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        return SupplierPerformanceModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing SupplierPerformance: $e');
      return null;
    }
  }

  Future<ChannelMixModel?> fetchChannelMix(Map<String, dynamic>? currentFilters) async {
    final data = await _getJson(
      ApiConstants.channelMix,
      filters: currentFilters,
      label: 'ChannelMix',
    );
    return data != null ? ChannelMixModel.fromJson(data) : null;
  }

  // ── Monthly Trend (Revenue & Profit) ──────────────────────────────────────
  Future<List<TrendModel>?> fetchTrend(Map<String, dynamic>? currentFilters) async {
    final uri = _buildUri(ApiConstants.trend, currentFilters);
    final response = await _throttledGet(uri);
    if (response == null) return null;
    try {
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        return list.map((e) => TrendModel.fromJson(e)).toList();
      }
      debugPrint('Failed to load Trend: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error parsing Trend: $e');
      return null;
    }
  }

  // ── Product Breakdown ──────────────────────────────────────────────────────
  Future<List<TopProductModel>?> fetchBreakdown(Map<String, dynamic>? currentFilters) async {
    final uri = _buildUri(ApiConstants.breakdown, currentFilters);
    final response = await _throttledGet(uri);
    if (response == null) return null;
    try {
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        return list.map((e) => TopProductModel.fromJson(e)).toList();
      }
      debugPrint('Failed to load Breakdown: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error parsing Breakdown: $e');
      return null;
    }
  }
}
