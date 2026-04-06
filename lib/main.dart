import 'package:dashboard_odoo/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'providers/theme_provider.dart'; // REMOVED
import 'services/auth_service.dart';
import 'services/api_constants.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    hide ChangeNotifierProvider, Consumer;
import 'providers/riverpod_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dynamic Base URL from storage
  await ApiConstants.init();
  
  final authService = AuthService();
  await authService.init();

  runApp(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWith((ref) => authService),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authService),
        ],
        child: const DashboardApp(),
      ),
    ),
  );
}

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return MaterialApp(
          title: 'Business Dashboard',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.light, // Forced Light Mode
          theme: ThemeData(
            useMaterial3: true,
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
          // Initial route is always the animated splash screen
          home: const SplashScreen(),
        );
      },
    );
  }
}
