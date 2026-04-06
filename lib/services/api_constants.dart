import 'package:shared_preferences/shared_preferences.dart';

/// Centralised API endpoint paths used by [ApiService].
///
/// All paths are relative to [ApiConstants.baseUrl].
/// Update this file whenever an endpoint is added, renamed, or removed.
class ApiConstants {
  // ── Base ──────────────────────────────────────────────────────────────────
  static String _baseUrl = 'http://3.110.83.156:8076/api';
  static String get baseUrl => _baseUrl;

  static const String _baseUrlKey = 'custom_base_url';

  /// Loads the persisted base URL if it exists.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
    }
  }

  /// Updates the base URL with a new protocol and host, then persists it.
  static Future<void> updateBaseUrl(String protocol, String host) async {
    String cleanHost = host.trim()
        .replaceFirst('http://', '')
        .replaceFirst('https://', '')
        .replaceAll(RegExp(r'/$'), '');
    
    // Ensure it ends with /api if not already present
    if (!cleanHost.endsWith('/api')) {
      _baseUrl = '$protocol$cleanHost/api';
    } else {
      _baseUrl = '$protocol$cleanHost';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _baseUrl);
  }

  // ── Endpoints ─────────────────────────────────────────────────────────────
  static const String kpis = '/kpis/';
  static const String summary = '/summary/';
  static const String filters = '/filters/';
  static const String profitTrendRegion = '/profit-trend-region/';
  static const String salespersonTargets = '/salesperson-targets/';
  static const String purchaseTrend = '/purchase-trend/';
  static const String returnRate = '/return-rate/';
  static const String purchaseReturnRate = '/purchase-return-rate/';
  static const String pnlByMonth = '/pnl-by-month/';
  static const String wholesaleVsRetail = '/wholesale-vs-retail/';
  static const String salespersonLeaderboard = '/salesperson-leaderboard/';
  static const String pnlByStore = '/pnl-by-store/';
  static const String targetAchievement = '/target-achievement/';
  static const String customerTop = '/customer-top/';
  static const String customerInsights = '/customer-insights/';
  static const String topProducts = '/top/';
  static const String supplierPerformance = '/supplier-performance/';
  static const String channelMix = '/channel-mix/';
  static const String trend = '/trend/';
  static const String breakdown = '/breakdown/';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String authenticate = '/web/session/authenticate';
}
