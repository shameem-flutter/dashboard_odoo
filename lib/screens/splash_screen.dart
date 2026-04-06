import 'package:dashboard_odoo/providers/riverpod_providers.dart';
import 'package:dashboard_odoo/screens/dashboard_screen.dart';
import 'package:dashboard_odoo/screens/login_screen.dart';
import 'package:dashboard_odoo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy_provider;

abstract final class _Palette {
  static const bgTop = Color(0xFF0D9488); // teal-600
  static const bgBottom = Color(0xFF134E4A); // teal-900
  static const accent = Color(0xFF5EEAD4); // teal-300
  static const ring = Color(0xFF2DD4BF); // teal-400

  static const logoInner = Color(0xFF0F766E); // teal-700
  static const textSub = Color(0xFF99F6E4); // teal-200
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _pulseController;
  late final AnimationController _dotsController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;
  late final Animation<double> _dotsAnimation;

  int? _loadingBatch;
  bool _batchesDone = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
    _handleNavigation();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.65,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _pulseOpacity = Tween<double>(
      begin: 0.5,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _dotsAnimation = CurvedAnimation(
      parent: _dotsController,
      curve: Curves.easeInOut,
    );
  }

  void _startSequence() {
    _logoController.forward().then((_) {
      if (mounted) _textController.forward();
    });
  }

  Future<void> _handleNavigation() async {
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 4800));

    final authService = legacy_provider.Provider.of<AuthService>(
      context,
      listen: false,
    );

    if (authService.isAuthenticated) {
      _setBatch(1);
      await _tryBatch([
        ref.read(availableFiltersProvider.future),
        ref.read(kpiProvider.future),
        ref.read(summaryProvider.future),
        ref.read(topProductsProvider.future),
        ref.read(salespersonTargetProvider.future),
      ], timeout: 15);

      _setBatch(2);
      await _tryBatch([
        ref.read(pnlByMonthProvider.future),
        ref.read(pnlByStoreProvider.future),
        ref.read(purchaseTrendProvider.future),
        ref.read(wholesaleVsRetailProvider.future),
        ref.read(returnRateProvider.future),
        ref.read(profitTrendProvider.future),
      ], timeout: 15);

      _setBatch(3);
      await _tryBatch([
        ref.read(purchaseReturnRateProvider.future),
        ref.read(salespersonLeaderboardProvider.future),
        ref.read(targetAchievementProvider.future),
        ref.read(customerTopProvider.future),
        ref.read(customerInsightsProvider.future),
        ref.read(supplierPerformanceProvider.future),
        ref.read(channelMixProvider.future),
        ref.read(trendProvider.future),
        ref.read(breakdownProvider.future),
      ], timeout: 20);

      if (mounted) setState(() => _batchesDone = true);
    }

    await minDelay;
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: authService.isAuthenticated
              ? const DashboardScreen()
              : const LoginScreen(),
        ),
      ),
    );
  }

  void _setBatch(int batch) {
    if (mounted) setState(() => _loadingBatch = batch);
  }

  Future<void> _tryBatch(
    List<Future<dynamic>> futures, {
    required int timeout,
  }) async {
    try {
      await Future.wait(futures).timeout(Duration(seconds: timeout));
    } catch (e) {
      debugPrint('[Splash] Batch timed out or partially failed: $e');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_Palette.bgTop, _Palette.bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _logoController,
                      _textController,
                      _pulseController,
                    ]),
                    builder: (context, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLogoWithPulse(),
                        const SizedBox(height: 44),
                        _buildTextBlock(),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoWithPulse() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer soft glow ring
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.teal.withValues(alpha: 0.07),
          ),
        ),

        // Animated pulse ring
        Opacity(
          opacity: _pulseOpacity.value,
          child: Transform.scale(
            scale: _pulseScale.value,
            child: Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _Palette.ring, width: 2.0),
              ),
            ),
          ),
        ),

        // Logo with entrance animation
        FadeTransition(
          opacity: _logoFade,
          child: ScaleTransition(
            scale: _logoScale,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    _Palette.bgTop,
                    Color(0xFF0F766E),
                    _Palette.bgBottom,
                  ],
                  stops: [0.0, 0.45, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.55),
                    blurRadius: 36,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.2),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: _Palette.logoInner,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    "assets/logo.jpg",
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 100,
                      width: 100,
                      child: Icon(
                        Icons.hub_rounded,
                        color: _Palette.accent,
                        size: 52,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextBlock() {
    return FadeTransition(
      opacity: _textFade,
      child: SlideTransition(
        position: _textSlide,
        child: Column(
          children: [
            Text(
              "Business Dashboard",
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Automate · Track · Deliver",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _Palette.textSub,
                letterSpacing: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          _AnimatedDots(animation: _dotsAnimation, color: _Palette.accent),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: _buildStatusText(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    if (_batchesDone) {
      return Text(
        "Almost ready...",
        key: const ValueKey('done'),
        style: _statusStyle(Colors.teal.shade200),
      );
    }
    if (_loadingBatch != null) {
      return Text(
        "Loading data $_loadingBatch of 3",
        key: ValueKey('batch_$_loadingBatch'),
        style: _statusStyle(Colors.teal.shade200.withValues(alpha: 0.75)),
      );
    }
    return Text(
      "Powered by Febno",
      key: const ValueKey('powered_by'),
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.teal.shade700,
        letterSpacing: 1.4,
      ),
    );
  }

  TextStyle _statusStyle(Color color) => GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: color,
    letterSpacing: 0.4,
  );
}

class _AnimatedDots extends StatelessWidget {
  final Animation<double> animation;
  final Color color;

  const _AnimatedDots({required this.animation, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = (animation.value + i / 3) % 1.0;
          final t = phase < 0.5 ? phase * 2 : (1.0 - phase) * 2;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Opacity(
              opacity: t.clamp(0.15, 1.0),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          );
        }),
      ),
    );
  }
}
