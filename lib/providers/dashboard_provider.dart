import 'package:flutter/material.dart';
import '../services/transaction_service.dart';
import '../services/shift_service.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/local_storage_service.dart';
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
      // 1. Delta Sync (Inbound)
      final syncRepo = SyncRepository();
      await syncRepo.performDeltaSync();

      // 2. Process Queue (Outbound)
      await syncRepo.processSyncQueue();

      // 3. Refresh Dashboard with Fresh Data
      await refreshDashboard();
    } catch (e) {
      debugPrint("Delta Sync Failure: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    try {
      // Refresh Shift Status
      _currentShift = await _shiftService.getCurrentShift();
      
      if (_currentShift != null) {
        final startTimeStr = _currentShift!['startTime'] ?? _currentShift!['start_time'];
        final startTime = startTimeStr != null ? DateTime.tryParse(startTimeStr) : null;
        _summary = await _transactionService.getDashboardSummary(startTime: startTime);
      }

      final lowStockProducts = await _productService.getLowStockProducts();
      _lowStockCount = lowStockProducts.length;

      notifyListeners();
    } catch (e) {
      debugPrint("Dashboard Refresh Error: $e");
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
}
