import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'services/auth_service.dart';
import 'services/local_storage_service.dart';
import 'providers/product_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/purchase_provider.dart';
import 'package:provider/provider.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  
  // Start the app immediately, init happens inside splash
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const UsahakuApp(),
    ),
  );
}

class UsahakuApp extends StatelessWidget {
  const UsahakuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Usahaku POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthCheckWrapper(),
      routes: AppRoutes.routes,
    );
  }
}

class AuthCheckWrapper extends StatefulWidget {
  const AuthCheckWrapper({super.key});

  @override
  State<AuthCheckWrapper> createState() => _AuthCheckWrapperState();
}

class _AuthCheckWrapperState extends State<AuthCheckWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    try {
      // 1. Run all initialization and checks in parallel
      final results = await Future.wait([
        LocalStorageService.init(), // This now opens all boxes
        AuthService().isLoggedIn().timeout(const Duration(seconds: 3), onTimeout: () => false),
        Future.delayed(const Duration(milliseconds: 500)), 
      ]);
      
      final bool isLoggedIn = results[1] as bool;

      if (!mounted) return;

      // 2. Start Provider initialization in background (non-blocking)
      context.read<DashboardProvider>().init();

      // Start fade out animation
      await _fadeController.forward();

      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint("Startup Error: $e");
      // Recovery: try to proceed to login if everything fails
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: ReverseAnimation(_fadeController),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Hero(
                tag: 'app_logo',
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: const Icon(Icons.store_rounded, size: 90, color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "USAHAKU",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 50),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
