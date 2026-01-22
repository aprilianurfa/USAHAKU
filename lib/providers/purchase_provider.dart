import 'package:flutter/material.dart';
import '../models/purchase_hive.dart';
import '../models/purchase_model.dart';
import '../models/sync_queue.dart';
import '../services/local_storage_service.dart';
import '../repositories/sync_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

class PurchaseProvider with ChangeNotifier {
  final LocalStorageService _localService = LocalStorageService();
  final SyncRepository _syncRepository = SyncRepository();

  List<PurchaseHive> _purchases = [];
  bool _isLoading = false;
  String? _error;

  List<PurchaseHive> get purchases => _purchases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PurchaseProvider() {
    // We don't await in constructor, but kick off loading
    loadLocalPurchases();
  }

  Future<void> loadLocalPurchases() async {
    _purchases = await _localService.getPurchases();
    // Sort by date descending
    _purchases.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    notifyListeners();
  }

  Future<void> saveLocalPurchase(PurchaseHive purchase) async {
    // 1. Save to Hive
    await _localService.savePurchase(purchase);
    
    // 2. Add to Sync Queue
    final queueItem = SyncQueueItem(
      id: "PQ-${DateTime.now().millisecondsSinceEpoch}",
      action: 'CREATE',
      entity: 'PURCHASE',
      data: {
        'supplier': purchase.supplier,
        'total_biaya': purchase.totalBiaya,
        'keterangan': purchase.keterangan,
        'items': purchase.items.map((i) => {
          'product_id': i.productId,
          'jumlah': i.jumlah,
          'harga_beli': i.hargaBeli,
        }).toList(),
      },
      createdAt: DateTime.now(),
    );
    await _localService.addToQueue(queueItem);
    
    // 3. Update local state
    loadLocalPurchases();

    // 4. Attempt sync if online
    final connectivity = await Connectivity().checkConnectivity();
    if (!connectivity.contains(ConnectivityResult.none)) {
       _syncRepository.processSyncQueue().then((_) => loadLocalPurchases());
    }
  }

  Future<void> performSync() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Delta Sync (Fetch from server)
      await _syncRepository.performDeltaSync();
      // 2. Process Queue (Send to server)
      await _syncRepository.processSyncQueue();
      
      await loadLocalPurchases();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alias for consistency across providers
  Future<void> syncData() async {
    await performSync();
  }
}
