import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/product_hive.dart';
import '../models/category_hive.dart';
import '../models/transaction_hive.dart';
import '../models/sync_queue.dart';
import '../repositories/product_repository.dart';
import '../repositories/sync_repository.dart';
import '../services/local_storage_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ProductProvider with ChangeNotifier {
  final ProductRepository _repository = ProductRepository();
  final SyncRepository _syncRepository = SyncRepository();

  List<ProductHive> _products = [];
  List<CategoryHive> _categories = [];
  bool _isLoading = false;
  String? _error;
  
  // Pagination State
  int _currentPage = 1;
  static const int _limit = 50; 
  bool _hasMore = true;

  List<ProductHive> get products => _products;
  List<CategoryHive> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get pendingSyncCount => _repository.getQueue().length;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Initial load: Local first, then BG sync
  Future<void> loadProducts() async {
    _products = await _repository.getLocalProducts();
    _categories = _repository.getLocalCategories();
    notifyListeners();

    _currentPage = 1;
    _hasMore = true;
    
    await performSync();
  }

  /// Performs a background sync (Delta Sync + Queue Processing)
  Future<void> performSync({bool isLoadMore = false}) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // 1. Fetch changes from server
      await _syncRepository.performDeltaSync();
      // 2. Send local changes to server
      await _syncRepository.processSyncQueue();
      
      // Update local state
      _products = await _repository.getLocalProducts();
      _categories = _repository.getLocalCategories();
    } catch (e) {
      _error = "Sinkronisasi gagal: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alias for performSync to maintain compatibility with legacy pages
  Future<void> syncData({bool isLoadMore = false}) async {
    await performSync(isLoadMore: isLoadMore);
  }

  Future<void> loadCategories() async {
    _categories = _repository.getLocalCategories();
    notifyListeners();
    await syncCategories();
  }

  Future<void> syncCategories() async {
    try {
      final freshCats = await _repository.syncCategories();
      _categories = freshCats;
    } catch (e) {
      _error = "Gagal sinkronisasi kategori";
    } finally {
      notifyListeners();
    }
  }

  // search logic: filter local data
  Future<void> searchProducts(String query) async {
    final allProducts = await _repository.getLocalProducts();
    if (query.isEmpty) {
      _products = allProducts;
    } else {
      final lowercaseQuery = query.toLowerCase();
      _products = allProducts.where((p) => 
        p.nama.toLowerCase().contains(lowercaseQuery) || 
        p.barcode.contains(query)
      ).toList();
    }
    notifyListeners();
  }

  // --- OPTIMISTIC UI UTILS ---

  Future<void> saveLocalTransaction(TransactionHive tx) async {
    await _repository.saveTransaction(tx);
  }

  Future<void> saveLocalProduct(ProductHive product) async {
    // 1. Save to local
    final box = Hive.lazyBox<ProductHive>(LocalStorageService.productBoxName);
    await box.put(product.id, product);
    
    // 2. Add to queue
    await addToSyncQueue(
      action: 'CREATE', // SyncRepository logic will need to handle UPDATE too
      entity: 'PRODUCT',
      data: product.toMap(),
    );
    
    _products = await _repository.getLocalProducts();
    notifyListeners();
  }

  Future<void> deleteLocalProduct(String id) async {
    final box = Hive.lazyBox<ProductHive>(LocalStorageService.productBoxName);
    final p = await box.get(id);
    if (p != null) {
      final deleted = ProductHive(
        id: p.id,
        nama: p.nama,
        kategoriId: p.kategoriId,
        harga: p.harga,
        hargaDasar: p.hargaDasar,
        stok: p.stok,
        minStok: p.minStok,
        barcode: p.barcode,
        isJasa: p.isJasa,
        image: p.image,
        isDeleted: true,
      );
      await box.put(id, deleted);
      
      await addToSyncQueue(
        action: 'DELETE',
        entity: 'PRODUCT',
        data: {'id': id},
      );
    }
    _products = await _repository.getLocalProducts();
    notifyListeners();
  }

  Future<void> saveLocalCategory(CategoryHive cat) async {
    await _repository.saveCategory(cat);
    _categories = _repository.getLocalCategories();
    notifyListeners();
  }

  Future<void> deleteLocalCategory(String id) async {
    await _repository.deleteCategory(id);
    _categories = _repository.getLocalCategories();
    notifyListeners();
  }

  Future<void> addToSyncQueue({
    required String action,
    required String entity,
    required Map<String, dynamic> data,
  }) async {
    final item = SyncQueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      action: action,
      entity: entity,
      data: data,
      createdAt: DateTime.now(),
    );
    await _repository.addToQueue(item);
    
    // Attempt processing if online
    final result = await Connectivity().checkConnectivity();
    if (!result.contains(ConnectivityResult.none)) {
       // We don't await here to keep UI responsive
       _syncRepository.processSyncQueue().then((_) async {
         _products = await _repository.getLocalProducts();
         _categories = _repository.getLocalCategories();
         notifyListeners();
       });
    }
    notifyListeners(); 
  }
}
