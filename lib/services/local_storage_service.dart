import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product_hive.dart';
import '../models/category_hive.dart';
import '../models/transaction_hive.dart';
import '../models/purchase_hive.dart';
import '../models/sync_queue.dart';

class LocalStorageService {
  static const String productBoxName = 'productBox';
  static const String categoryBoxName = 'categoryBox';
  static const String transactionBoxName = 'transactionBox';
  static const String purchaseBoxName = 'purchaseBox';
  static const String syncQueueBoxName = 'syncQueueBox';
  static const String settingsBoxName = 'settingsBox';

  static Future<void>? _initFuture;

  static Future<void> init() {
    _initFuture ??= _doInit();
    return _initFuture!;
  }

  static Future<void> _doInit() async {
    await Hive.initFlutter();
    
    // Register Adapters safely
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProductHiveAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CategoryHiveAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(TransactionHiveAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(TransactionItemHiveAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(PurchaseHiveAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(PurchaseItemHiveAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(SyncQueueItemAdapter());
    
    try {
      await _openAllBoxes();
    } catch (e) {
      debugPrint("Hive initialization failed: $e. Wiping boxes and retrying...");
      // Nuclear option: delete all boxes and try again one more time
      final boxes = [
        productBoxName, categoryBoxName, transactionBoxName,
        purchaseBoxName, syncQueueBoxName, settingsBoxName
      ];
      for (final box in boxes) {
        try {
          await Hive.deleteBoxFromDisk(box);
        } catch (err) {
          debugPrint("Failed to delete box $box: $err");
        }
      }
      await _openAllBoxes();
    }
  }

  static Future<void> _openAllBoxes() async {
    await Future.wait([
      Hive.openBox(settingsBoxName),
      Hive.openBox<SyncQueueItem>(syncQueueBoxName),
      Hive.openBox<CategoryHive>(categoryBoxName),
      Hive.openLazyBox<ProductHive>(productBoxName),
      Hive.openLazyBox<PurchaseHive>(purchaseBoxName),
      Hive.openBox<TransactionHive>(transactionBoxName),
    ]).timeout(const Duration(seconds: 15));
  }


  // --- PRODUCTS (Updated for LazyBox) ---

  Future<void> saveProducts(List<ProductHive> products, {bool clear = false}) async {
    await init();
    final box = Hive.lazyBox<ProductHive>(productBoxName);
    if (clear) await box.clear();
    final Map<String, ProductHive> productMap = {
      for (var p in products) p.id: p
    };
    await box.putAll(productMap);
  }

  Future<List<ProductHive>> getProducts() async {
    await init();
    final box = Hive.lazyBox<ProductHive>(productBoxName);
    if (box.isEmpty) return [];
    
    // Using Future.wait to load keys in parallel is faster than sequential loop
    final keys = box.keys.toList();
    final results = await Future.wait(keys.map((k) => box.get(k)));
    
    return results
      .whereType<ProductHive>()
      .where((p) => !p.isDeleted)
      .toList();
  }

  Future<void> saveProduct(ProductHive product) async {
    await init();
    final box = Hive.lazyBox<ProductHive>(productBoxName);
    await box.put(product.id, product);
  }

  Future<ProductHive?> getProduct(String id) async {
    await init();
    final box = Hive.lazyBox<ProductHive>(productBoxName);
    return await box.get(id);
  }

  Future<void> deleteProductFromDisk(String id) async {
    await init();
    final box = Hive.lazyBox<ProductHive>(productBoxName);
    await box.delete(id);
  }

  // --- CATEGORIES ---

  Future<void> saveCategories(List<CategoryHive> categories, {bool clear = false}) async {
    await init();
    final box = Hive.box<CategoryHive>(categoryBoxName);
    if (clear) await box.clear();
    final Map<String, CategoryHive> categoryMap = {
      for (var c in categories) c.id: c
    };
    await box.putAll(categoryMap);
  }

  List<CategoryHive> getLocalCategories() {
    if (!Hive.isBoxOpen(categoryBoxName)) return [];
    final box = Hive.box<CategoryHive>(categoryBoxName);
    // Filter out deleted items for UI
    return box.values.where((c) => !c.isDeleted).toList();
  }

  Future<void> saveCategory(CategoryHive category) async {
    await init();
    final box = Hive.box<CategoryHive>(categoryBoxName);
    await box.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    await init();
    final box = Hive.box<CategoryHive>(categoryBoxName);
    final cat = box.get(id);
    if (cat != null) {
      // Create a copy with isDeleted = true
      final deletedCat = CategoryHive(
        id: cat.id,
        nama: cat.nama,
        isDeleted: true,
      );
      await box.put(id, deletedCat);
    }
  }

  // --- TRANSACTIONS ---

  Future<void> saveTransactions(List<TransactionHive> transactions, {bool clear = false}) async {
    await init();
    final box = Hive.box<TransactionHive>(transactionBoxName);
    if (clear) await box.clear();
    final Map<String, TransactionHive> txMap = {
      for (var t in transactions) t.id: t
    };
    await box.putAll(txMap);
  }

  Future<void> saveTransaction(TransactionHive transaction) async {
    await init();
    final box = Hive.box<TransactionHive>(transactionBoxName);
    await box.put(transaction.id, transaction);
  }

  List<TransactionHive> getLocalTransactions() {
    if (!Hive.isBoxOpen(transactionBoxName)) return [];
    final box = Hive.box<TransactionHive>(transactionBoxName);
    return box.values.toList();
  }

  // --- PURCHASES ---

  // --- PURCHASES (Updated for LazyBox) ---

  Future<void> savePurchases(List<PurchaseHive> purchases, {bool clear = false}) async {
    await init();
    final box = Hive.lazyBox<PurchaseHive>(purchaseBoxName);
    if (clear) await box.clear();
    final Map<String, PurchaseHive> purchaseMap = {
      for (var p in purchases) p.id: p
    };
    await box.putAll(purchaseMap);
  }

  Future<void> savePurchase(PurchaseHive purchase) async {
    await init();
    final box = Hive.lazyBox<PurchaseHive>(purchaseBoxName);
    await box.put(purchase.id, purchase);
  }

  Future<List<PurchaseHive>> getPurchases() async {
    await init();
    final box = Hive.lazyBox<PurchaseHive>(purchaseBoxName);
    if (box.isEmpty) return [];

    final keys = box.keys.toList();
    final results = await Future.wait(keys.map((k) => box.get(k)));

    return results.whereType<PurchaseHive>().toList();
  }

  // --- SYNC QUEUE ---

  Future<void> addToQueue(SyncQueueItem item) async {
    await init();
    final box = Hive.box<SyncQueueItem>(syncQueueBoxName);
    await box.put(item.id, item);
  }

  Future<void> removeFromQueue(String id) async {
    await init();
    final box = Hive.box<SyncQueueItem>(syncQueueBoxName);
    await box.delete(id);
  }

  List<SyncQueueItem> getQueue() {
    if (!Hive.isBoxOpen(syncQueueBoxName)) return [];
    final box = Hive.box<SyncQueueItem>(syncQueueBoxName);
    return box.values.toList();
  }

  // --- SETTINGS (Last Sync Time) ---

  Future<void> setLastSyncTime(DateTime time) async {
    await init();
    final box = Hive.box(settingsBoxName);
    await box.put('lastSyncTime', time.toIso8601String());
  }

  Future<void> setLastSyncedShopId(String shopId) async {
    await init();
    final box = Hive.box(settingsBoxName);
    await box.put('lastSyncedShopId', shopId);
  }

  DateTime? getLastSyncTime() {
    if (!Hive.isBoxOpen(settingsBoxName)) return null;
    final box = Hive.box(settingsBoxName);
    final str = box.get('lastSyncTime');
    return str != null ? DateTime.parse(str) : null;
  }

  String? getLastSyncedShopId() {
    if (!Hive.isBoxOpen(settingsBoxName)) return null;
    final box = Hive.box(settingsBoxName);
    return box.get('lastSyncedShopId');
  }

  Future<void> clearAll() async {
    try {
      // 1. Ensure all boxes are open before clearing (to avoid errors)
      await _openAllBoxes();

      // 2. Clear all boxes
      await Future.wait([
        Hive.lazyBox<ProductHive>(productBoxName).clear(),
        Hive.box<CategoryHive>(categoryBoxName).clear(),
        Hive.box<TransactionHive>(transactionBoxName).clear(),
        Hive.lazyBox<PurchaseHive>(purchaseBoxName).clear(),
        Hive.box<SyncQueueItem>(syncQueueBoxName).clear(),
        Hive.box(settingsBoxName).clear(),
      ]);

      // 3. Close all boxes to release file locks
      await Hive.close();

      // 4. Delete boxes from disk to be ABSOLUTELY sure (Nuclear Logout)
      final boxes = [
        productBoxName, categoryBoxName, transactionBoxName,
        purchaseBoxName, syncQueueBoxName, settingsBoxName
      ];
      for (final box in boxes) {
        await Hive.deleteBoxFromDisk(box);
      }
    } catch (e) {
      debugPrint("Error during clearAll: $e");
    } finally {
      // 5. Reset the init future
      _initFuture = null;
    }
  }
}
