import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/product_hive.dart';
import '../models/category_hive.dart';
import '../models/transaction_hive.dart';
import '../models/sync_queue.dart';
import '../repositories/product_repository.dart';
import '../repositories/sync_repository.dart';
import '../services/local_storage_service.dart';
import '../config/storage_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ProductProvider with ChangeNotifier {
  final ProductRepository _repository = ProductRepository();
  final SyncRepository _syncRepository = SyncRepository();

  List<ProductHive> _products = [];
  List<CategoryHive> _categories = [];
  String _userRole = 'kasir';
  bool _isLoading = false;
  String? _error;
  
  // Pagination State
  int _currentPage = 1;
  static const int _limit = 50; 
  bool _hasMore = true;

  List<ProductHive> get products => _products;
  List<CategoryHive> get categories => _categories;
  String get userRole => _userRole;
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
    
    // Load Role
    final role = await StorageConfig.storage.read(key: 'role');
    _userRole = role ?? 'kasir';
    
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

  bool isDuplicateName(String name, {String? excludeId}) {
    // Check against all products in memory (which reflects local storage)
    return _products.any((p) {
      if (excludeId != null && p.id == excludeId) return false;
      return p.nama.toLowerCase() == name.toLowerCase() && !p.isDeleted;
    });
  }

  // --- OPTIMISTIC UI UTILS ---

  Future<void> saveLocalTransaction(TransactionHive tx) async {
    // 1. Save Transaction Record
    await _repository.saveTransaction(tx);
    
    // 2. DEDUCT STOCK LOCALLY (Optimistic Update)
    for (var item in tx.items) {
      final product = await _repository.getLocalProduct(item.productId);
      if (product != null) {
        final updatedProduct = ProductHive(
          id: product.id,
          nama: product.nama,
          kategoriId: product.kategoriId,
          harga: product.harga,
          hargaDasar: product.hargaDasar,
          stok: product.stok - item.qty,
          minStok: product.minStok,
          barcode: product.barcode,
          isJasa: product.isJasa,
          image: product.image,
          isDeleted: product.isDeleted,
        );
        await _repository.saveLocalProduct(updatedProduct);
      }
    }
    
    // 3. Refresh UI
    _products = await _repository.getLocalProducts();
    notifyListeners();
  }

  Future<void> saveLocalProduct(ProductHive product, {Uint8List? imageBytes, String? imageFilename}) async {
    // 1. Save to local
    await _repository.saveLocalProduct(product);
    
    // 2. Determine Sync Action
    // If ID is local (starts with LOC-), it's a new creation.
    // If ID is from server (no LOC-), it's an update.
    final isLocal = product.id.toString().startsWith('LOC-');
    final action = isLocal ? 'CREATE' : 'UPDATE';

    // 3. Add to queue
    await addToSyncQueue(
      action: action, 
      entity: 'PRODUCT',
      data: product.toMap(),
      imageBytes: imageBytes,
      imageFilename: imageFilename,
    );
    
    _products = await _repository.getLocalProducts();
    notifyListeners();
  }

  Future<void> deleteLocalProduct(String id) async {
    final p = await _repository.getLocalProduct(id);
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
      await _repository.saveLocalProduct(deleted);
      
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
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    // Inject Image Data into Map for Queue Storage
    if (imageBytes != null) {
      data['imageBytes'] = imageBytes;
      data['imageFilename'] = imageFilename;
    }

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

  void resetState() {
    _products = [];
    _categories = [];
    _userRole = 'kasir';
    _isLoading = false;
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }
}
