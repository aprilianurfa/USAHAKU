import '../models/product_hive.dart';
import '../models/category_hive.dart';
import '../services/product_service.dart';
import '../services/local_storage_service.dart';
import '../models/transaction_hive.dart';
import '../models/sync_queue.dart';

class ProductRepository {
  final ProductService _apiService = ProductService();
  final LocalStorageService _localService = LocalStorageService();

  // 1. Get from Local first (Async for LazyBox)
  Future<List<ProductHive>> getLocalProducts() async {
    return await _localService.getProducts();
  }

  Future<void> saveLocalProduct(ProductHive product) async {
    await _localService.saveProduct(product);
  }

  Future<ProductHive?> getLocalProduct(String id) async {
    return await _localService.getProduct(id);
  }

  List<CategoryHive> getLocalCategories() {
    return _localService.getLocalCategories();
  }

  Future<void> saveCategory(CategoryHive category) async {
    await _localService.saveCategory(category);
  }

  Future<void> deleteCategory(String id) async {
    await _localService.deleteCategory(id);
  }

  Future<void> saveTransaction(TransactionHive transaction) async {
    await _localService.saveTransaction(transaction);
  }

  Future<void> addToQueue(SyncQueueItem item) async {
    await _localService.addToQueue(item);
  }

  List<SyncQueueItem> getQueue() {
    return _localService.getQueue();
  }

  // 2. Fetch from API and Sync
  Future<List<ProductHive>> syncProducts({int page = 1, int limit = 100}) async {
    try {
      final apiProducts = await _apiService.getProducts(page: page, limit: limit);
      
      if (apiProducts.isEmpty && page == 1) {
        return await _localService.getProducts();
      }
      
      final hiveProducts = apiProducts.map((p) => ProductHive(
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
        isDeleted: p.isDeleted,
      )).toList();

      // For full sync (page 1), clear old data. For pagination, append.
      await _localService.saveProducts(hiveProducts, clear: page == 1);
      
      return await _localService.getProducts();
    } catch (e) {
      return await _localService.getProducts();
    }
  }

  // 3. Sync Categories
  Future<List<CategoryHive>> syncCategories() async {
    try {
      final apiCategories = await _apiService.getCategories();
      
      final hiveCategories = apiCategories.map((c) => CategoryHive(
        id: c.id,
        nama: c.nama,
        isDeleted: c.isDeleted,
      )).toList();

      await _localService.saveCategories(hiveCategories, clear: true);
      return _localService.getLocalCategories();
    } catch (e) {
      return _localService.getLocalCategories();
    }
  }
}
