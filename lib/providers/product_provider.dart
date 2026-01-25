import 'dart:async';
import 'package:flutter/foundation.dart'; // Added for compute 
import '../models/product_hive.dart';
import '../models/category_hive.dart';
import '../models/transaction_hive.dart';
import '../models/sync_queue.dart';
import '../repositories/product_repository.dart';
import '../repositories/sync_repository.dart';
import '../config/storage_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Helper function for isolate filtering - MUST use primitive data for thread safety
Map<String, dynamic> _filterProductData(Map<String, dynamic> params) {
  final List<dynamic> rawProducts = params['allProducts'] ?? [];
  final String searchQuery = params['searchQuery'] ?? '';
  final String selectedCategoryId = params['selectedCategoryId'] ?? 'All';
  final String searchCategoryQuery = params['searchCategoryQuery'] ?? '';
  final List<dynamic> rawCategories = params['categories'] ?? [];

  // Product filter logic using Maps
  final filteredProductsRaw = rawProducts.where((p) {
    final Map<String, dynamic> product = Map<String, dynamic>.from(p);
    final matchCategory = selectedCategoryId == 'All' || product['kategori_id'].toString() == selectedCategoryId;
    final matchSearch = searchQuery.isEmpty ||
        product['nama'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
        product['barcode'].toString().contains(searchQuery);
    return matchCategory && matchSearch && product['is_deleted'] != true;
  }).toList();

  // Low stock items and count calculation
  final lowStockItemsRaw = rawProducts.where((p) {
    final Map<String, dynamic> product = Map<String, dynamic>.from(p);
    return (product['stok'] ?? 0) <= (product['min_stok'] ?? 0) && product['is_deleted'] != true;
  }).toList();
  final lowStockCount = lowStockItemsRaw.length;

  // Category filter logic using Maps
  final List<dynamic> filteredCategoriesRaw;
  if (searchCategoryQuery.isEmpty) {
    filteredCategoriesRaw = rawCategories;
  } else {
    filteredCategoriesRaw = rawCategories.where((c) {
      final Map<String, dynamic> cat = Map<String, dynamic>.from(c);
      return cat['nama'].toString().toLowerCase().contains(searchCategoryQuery.toLowerCase());
    }).toList();
  }

  // Return versioned results to allow UI to skip deep list comparison
  return {
    'filteredProducts': filteredProductsRaw,
    'lowStockCount': lowStockCount,
    'lowStockProducts': lowStockItemsRaw,
    'filteredCategories': filteredCategoriesRaw,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
}

class ProductProvider with ChangeNotifier {
  final ProductRepository _repository = ProductRepository();
  final SyncRepository _syncRepository = SyncRepository();

  List<ProductHive> _products = [];
  List<ProductHive> _allProducts = []; // Cache for full list
  List<CategoryHive> _categories = [];
  String _userRole = 'kasir';
  bool _isLoading = false;
  bool _isSyncing = false; // Background sync indicator
  String? _error;
  bool _isInitialized = false;
  int _dataVersion = 0;
  
  bool _hasMore = true;

  int get dataVersion => _dataVersion;
  bool get isInitialized => _isInitialized;
  List<ProductHive> get products => _products;
  List<CategoryHive> get categories => _categories;
  String get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get pendingSyncCount => _repository.getQueue().length;
  List<SyncQueueItem> get syncQueue => _repository.getQueue();

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Initial load: Local first, then BG sync
  Future<void> loadProducts({bool force = false}) async {
    if (_isInitialized && !force) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      _allProducts = await _repository.getLocalProducts();
      _products = List.from(_allProducts); // Initial state shows all
      _categories = _repository.getLocalCategories();
      
      // Load Role
      final role = await StorageConfig.storage.read(key: 'role');
      _userRole = role ?? 'kasir';
      
      _isInitialized = true;
      _applyFilters(); 
      
      // Trigger Silent Sync only on first successful load
      performSync();
    } catch (e) {
      _error = "Gagal memuat data: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    _hasMore = true;
  }

  /// Performs a background sync (Delta Sync + Queue Processing)
  Future<void> performSync({bool isLoadMore = false}) async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    // We notify here ONLY if you want to show a small loading indicator in the app bar.
    // If you want completely silent sync, remove this notifyListeners.
    // For semi-online, a subtle indicator is often good UX.
    notifyListeners(); 
    
    try {
      // 1. Fetch changes from server
      await _syncRepository.performDeltaSync();
      // 2. Send local changes to server
      await _syncRepository.processSyncQueue();
      
      // Update local state - Re-read from DB found changes
      _allProducts = await _repository.getLocalProducts();
      _products = List.from(_allProducts);
      _categories = _repository.getLocalCategories();
      _applyFilters(); // Refresh filtered list with new data
    } catch (e) {
      // For silent sync, we might not want to show a snackbar error for connectivity issues
      debugPrint("Silent Sync Error: $e"); 
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Alias for performSync to maintain compatibility with legacy pages
  Future<void> syncData({bool isLoadMore = false}) async {
    await performSync(isLoadMore: isLoadMore);
  }

  Future<void> loadCategories() async {
    _categories = _repository.getLocalCategories();
    _applyFilters(); // Apply filter to populate filteredCategories
    await syncCategories();
  }

  Future<void> syncCategories() async {
    try {
      final freshCats = await _repository.syncCategories();
      _categories = freshCats;
    } catch (e) {
      _error = "Gagal sinkronisasi kategori";
    } finally {
      // notifyListeners(); // Replaced by applyFilters
      _applyFilters();
    }
  }

  // Filtering State
  String _searchQuery = '';
  String _selectedCategoryId = 'All';
  List<ProductHive> _filteredProducts = [];
  List<ProductHive> _lowStockProducts = [];
  int _lowStockCount = 0; 
  
  String _searchCategoryQuery = '';
  List<CategoryHive> _filteredCategories = [];
  
  Timer? _debounce; 

  List<ProductHive> get filteredProducts => _filteredProducts;
  List<ProductHive> get lowStockProducts => _lowStockProducts;
  List<CategoryHive> get filteredCategories => _filteredCategories; // Exposed for CategoryPage
  String get searchQuery => _searchQuery;
  String get searchCategoryQuery => _searchCategoryQuery;
  String get selectedCategoryId => _selectedCategoryId;
  int get lowStockCount => _lowStockCount;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // --- FILTERING LOGIC ---

  void _applyFilters() {
    // If dataset is large, offload filtering to an isolate using compute
    if (_allProducts.length > 50) { // Lowered threshold for safety
      final params = {
        'allProducts': _allProducts.map((p) => p.toMap()).toList(),
        'searchQuery': _searchQuery,
        'selectedCategoryId': _selectedCategoryId,
        'searchCategoryQuery': _searchCategoryQuery,
        'categories': _categories.map((c) => c.toMap()).toList(),
      };
      compute(_filterProductData, params).then((result) {
        if (!hasListeners) return;
        try {
          _filteredProducts = (result['filteredProducts'] as List).map((m) => ProductHive.fromMap(m)).toList();
          _lowStockCount = result['lowStockCount'] as int;
          _lowStockProducts = (result['lowStockProducts'] as List).map((m) => ProductHive.fromMap(m)).toList();
          _filteredCategories = (result['filteredCategories'] as List).map((m) => CategoryHive.fromMap(m)).toList();
          _dataVersion++; // Increment version to signal UI change
          notifyListeners();
        } catch (e) {
          debugPrint("Filter reconstruction error: $e");
        }
      }).catchError((e) {
        debugPrint("Compute filtering error: $e");
      });
    } else {
      // 1. Product Filter
      int lowStock = 0;
      _filteredProducts = _allProducts.where((p) {
        final matchCategory = _selectedCategoryId == 'All' || p.kategoriId == _selectedCategoryId;
        final matchSearch = _searchQuery.isEmpty ||
            p.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.barcode.contains(_searchQuery);
        return matchCategory && matchSearch && !p.isDeleted;
      }).toList();

      _lowStockProducts = _allProducts.where((b) => b.stok <= b.minStok && !b.isDeleted).toList();
      _lowStockCount = _lowStockProducts.length;

      // 2. Category Filter (Simple contains)
      if (_searchCategoryQuery.isEmpty) {
        _filteredCategories = List.from(_categories);
      } else {
        _filteredCategories = _categories.where((c) =>
            c.nama.toLowerCase().contains(_searchCategoryQuery.toLowerCase()))
            .toList();
      }
      notifyListeners();
    }
  }

  void searchProducts(String query) {
    if (_searchQuery == query) return;
    
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void searchCategories(String query) {
     // Usually categories are few, so debounce might not be strictly necessary, 
     // but beneficial for consistency.
    if (_searchCategoryQuery == query) return;
    _searchCategoryQuery = query;
    _applyFilters();
  }



  void setCategory(String categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    _applyFilters();
  }
  
  // Replaces the old searchProducts logic
  // search logic: filter local data
  // void searchProducts(String query) { ... } -> REPLACED above

  bool isDuplicateName(String name, {String? excludeId}) {
    // Check against all products in memory (which reflects local storage)
    return _allProducts.any((p) {
      if (excludeId != null && p.id == excludeId) return false;
      return p.nama.toLowerCase() == name.toLowerCase() && !p.isDeleted;
    });
  }

  // --- OPTIMISTIC UI UTILS ---

  Future<void> saveLocalTransaction(TransactionHive tx) async {
    // 1. Save Transaction Record
    await _repository.saveTransaction(tx);
    
    // 2. DEDUCT STOCK LOCALLY (Optimistic Update & Parallel Persistence)
    final List<Future> persistenceTasks = [];

    for (var item in tx.items) {
      // Find and update in _allProducts (Master List)
      final indexAll = _allProducts.indexWhere((p) => p.id == item.productId);
      if (indexAll != -1) {
        final p = _allProducts[indexAll];
        final updatedProduct = ProductHive(
          id: p.id,
          nama: p.nama,
          kategoriId: p.kategoriId,
          harga: p.harga,
          hargaDasar: p.hargaDasar,
          stok: p.stok - item.qty,
          minStok: p.minStok,
          barcode: p.barcode,
          isJasa: p.isJasa,
          image: p.image,
          isDeleted: p.isDeleted,
        );
        _allProducts[indexAll] = updatedProduct;
        
        // Persist to DB in background
        persistenceTasks.add(_repository.saveLocalProduct(updatedProduct));
      }

      // Also update in _products (Displayed List) if present
      final indexDisplay = _products.indexWhere((p) => p.id == item.productId);
      if (indexDisplay != -1) {
         final p = _products[indexDisplay];
         _products[indexDisplay] = ProductHive(
          id: p.id,
          nama: p.nama,
          kategoriId: p.kategoriId,
          harga: p.harga,
          hargaDasar: p.hargaDasar,
          stok: p.stok - item.qty,
          minStok: p.minStok,
          barcode: p.barcode,
          isJasa: p.isJasa,
          image: p.image,
          isDeleted: p.isDeleted,
        );
      }
    }
    
    // 3. UI Update Immediate
    // notifyListeners(); // Replaced by applyFilters
    _applyFilters();
    
    // 4. Ensure persistence completes
    await Future.wait(persistenceTasks);
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
    
    _allProducts = await _repository.getLocalProducts();
    _products = List.from(_allProducts);
    _applyFilters();
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
    _allProducts = await _repository.getLocalProducts();
    _products = List.from(_allProducts);
    _applyFilters();
  }

  Future<void> saveLocalCategory(CategoryHive cat) async {
    await _repository.saveCategory(cat);
    _categories = _repository.getLocalCategories();
    _applyFilters();
  }

  Future<void> deleteLocalCategory(String id) async {
    await _repository.deleteCategory(id);
    _categories = _repository.getLocalCategories();
    _applyFilters();
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
    _hasMore = true;
    notifyListeners();
  }
}
