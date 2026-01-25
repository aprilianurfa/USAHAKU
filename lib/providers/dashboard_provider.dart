import 'package:flutter/material.dart';
import '../services/transaction_service.dart';
import '../services/shift_service.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../repositories/sync_repository.dart';
import '../models/sales_report_model.dart';

class DashboardProvider with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  final ShiftService _shiftService = ShiftService();
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();

  // Data State
  DashboardSummary? _summary;
  Map<String, dynamic>? _currentShift;
  String _role = 'kasir';
  String _shopName = 'Toko Anda';
  String? _shopLogo;
  int _lowStockCount = 0;

  bool _isLoading = false;
  
  // Getters
  DashboardSummary? get summary => _summary;
  Map<String, dynamic>? get currentShift => _currentShift;
  String get role => _role;
  String get shopName => _shopName;
  String? get shopLogo => _shopLogo;
  int get lowStockCount => _lowStockCount;
  bool get isLoading => _isLoading;
  bool get isShiftOpen => _currentShift != null;

  // Initialize: Non-blocking background tasks
  void init() {
    // 1. Kick off background tasks without 'await' to let UI render immediately
    _initInBackground();
  }

  Future<void> _initInBackground() async {
    // a. Load basic profile (async but fast)
    await _loadUserFromStorage();
    
    // b. First pass: Load local data instantly
    await _loadLocalSummary();

    // d. Second pass: Sync with server in background
    syncData();
  }

  Future<void> _loadLocalSummary() async {
    // Try to load cached summary or just zero it
    _summary = DashboardSummary(salesToday: 0, trxCountToday: 0, profitToday: 0);
    notifyListeners();
  }

  /// Implements Delta Sync logic and background refresh
  Future<void> syncData() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Delta Sync (Inbound & Outbound)
      final syncRepo = SyncRepository();
      await syncRepo.performDeltaSync();
      await syncRepo.processSyncQueue();

      // 2. Refresh the statistics from Server
      await _fetchDashboardStats();
    } catch (e) {
      debugPrint("Delta Sync Failure: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    // Top-level refresh: perform sync which then updates stats
    await syncData();
  }

  /// Internal method to fetch fresh stats from server
  Future<void> _fetchDashboardStats() async {
    try {
      // Always re-load user context (role, shop name) 
      await _loadUserFromStorage();

      // Refresh Shift Status
      _currentShift = await _shiftService.getCurrentShift();
      
      
      // Fix: Dashboard should always show TODAY's sales, not just current shift sales.
      // This ensures it matches "Laporan Penjualan" which defaults to today.
      final now = DateTime.now();
      final startTime = DateTime(now.year, now.month, now.day); 
      // Ignored: Shift Start Time logic removed to align with Report
      // if (_currentShift != null) { ... }

      // Fetch Summary (Sales, Trx Count, Profit)
      final rawSummary = await _transactionService.getDashboardSummary(startTime: startTime);
      _summary = rawSummary;

      // Low Stock Alert
      final lowStockProducts = await _productService.getLowStockProducts();
      _lowStockCount = lowStockProducts.length;

    } catch (e) {
      debugPrint("Stats Fetch Error: $e");
    }
  }

  Future<void> _loadUserFromStorage() async {
    final role = await _authService.getRole();
    final shopName = await _authService.getShopName();
    final shopLogo = await _authService.getShopLogo();
    
    _role = role ?? 'kasir';
    _shopName = shopName ?? 'Toko Anda';
    _shopLogo = shopLogo;
    notifyListeners();
  }

  void resetState() {
    _summary = null;
    _currentShift = null;
    _role = 'kasir';
    _shopName = 'Toko Anda';
    _shopLogo = null;
    _lowStockCount = 0;
    _isLoading = false;
    notifyListeners();
  }
}
