import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/product_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/input_draft_provider.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'services/auth_service.dart';
import 'services/local_storage_service.dart';
import 'providers/dashboard_provider.dart';
import 'core/app_shell.dart';
import 'core/route_awareness.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  runApp(const UsahakuApp());
}

class UsahakuApp extends StatelessWidget {
  const UsahakuApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => InputDraftProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Usahaku POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthCheckWrapper(),
        routes: AppRoutes.routes,
        navigatorObservers: [AppRouteObserver()],
        builder: (context, child) => AppShell(child: child ?? const SizedBox.shrink()),
      ),
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
      await Future.wait([
        LocalStorageService.init(),
        AuthService().isLoggedIn().timeout(const Duration(seconds: 3), onTimeout: () => false),
        Future.delayed(const Duration(milliseconds: 500)), 
      ]);
      
      if (!mounted) return;
      
      final bool isLoggedIn = await AuthService().isLoggedIn();
      
      if (!mounted) return;
      
      // context.read<DashboardProvider>().init(); // MOVED TO DASHBOARD PAGE
      // context.read<DashboardProvider>().refreshDashboard(); // MOVED TO DASHBOARD PAGE
      await _fadeController.forward();

      if (!mounted) return;

      if (isLoggedIn) {
        UsahakuApp.navigatorKey.currentState?.pushReplacementNamed('/dashboard');
      } else {
        UsahakuApp.navigatorKey.currentState?.pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) UsahakuApp.navigatorKey.currentState?.pushReplacementNamed('/login');
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
              Hero(
                tag: 'app_logo',
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: 10)
                    ],
                  ),
                  child: const Icon(Icons.store_rounded, size: 90, color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 30),
              const Text("USAHAKU", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 4)),
              const SizedBox(height: 50),
              const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor))),
            ],
          ),
        ),
      ),
    );
  }
}
