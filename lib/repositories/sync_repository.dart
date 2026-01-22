import 'package:dio/dio.dart';
import '../models/product_hive.dart';
import '../models/category_hive.dart';
import '../models/transaction_hive.dart';
import '../models/purchase_hive.dart';
import '../models/sync_queue.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../config/constants.dart';

class SyncRepository {
  final Dio _dio = Dio();
  final LocalStorageService _localService = LocalStorageService();
  final AuthService _authService = AuthService();

  SyncRepository() {
    _dio.options.baseUrl = AppConstants.baseUrl;
  }

  /// 1. DELTA SYNC (Inbound)
  /// Fetches only changed data since last_sync_time and merges into local Hive.
  Future<void> performDeltaSync() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final lastSync = _localService.getLastSyncTime();
      
      final response = await _dio.get(
        '/sync',
        queryParameters: {
          'lastSyncTime': lastSync?.toIso8601String(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Merge Categories
        if (data['categories'] != null) {
          final cats = (data['categories'] as List).map((c) => CategoryHive(
            id: c['id'].toString(),
            nama: c['nama'],
            isDeleted: c['is_deleted'] ?? false,
          )).toList();
          await _localService.saveCategories(cats, clear: false);
        }

        // Merge Products
        if (data['products'] != null) {
          final prods = (data['products'] as List).map((p) => ProductHive(
            id: p['id'].toString(),
            nama: p['nama'],
            harga: p['harga'],
            hargaDasar: p['harga_dasar'] ?? 0,
            stok: p['stok'],
            minStok: p['min_stok'] ?? 0,
            image: p['image'],
            barcode: p['barcode'] ?? "",
            isJasa: p['is_jasa'] ?? false,
            kategoriId: p['kategori_id']?.toString() ?? "",
            isDeleted: p['is_deleted'] ?? false,
          )).toList();
          
          await _localService.saveProducts(prods, clear: false);
        }

        // Merge Purchases
        if (data['purchases'] != null) {
          final purhs = (data['purchases'] as List).map((p) => PurchaseHive(
            id: p['id'].toString(),
            tanggal: DateTime.parse(p['tanggal']),
            supplier: p['supplier'] ?? "",
            totalBiaya: p['total_biaya'] ?? 0,
            keterangan: p['keterangan'] ?? "",
            items: (p['PurchaseItems'] as List? ?? []).map((i) => PurchaseItemHive(
              productId: i['product_id'].toString(),
              productName: i['Product']?['nama'] ?? "Produk",
              jumlah: i['jumlah'],
              hargaBeli: i['harga_beli'],
            )).toList(),
            isSynced: true,
          )).toList();
          await _localService.savePurchases(purhs, clear: false);
        }

        // Update Last Sync Time
        if (data['serverTime'] != null) {
          await _localService.setLastSyncTime(DateTime.parse(data['serverTime']));
        }
      }
    } catch (e) {
      print("Delta Sync Error: $e");
      rethrow;
    }
  }

  /// 2. PROCESS QUEUE (Outbound)
  /// Sends pending local actions to the server.
  Future<void> processSyncQueue() async {
    final queue = _localService.getQueue();
    if (queue.isEmpty) return;

    final token = await _authService.getToken();
    if (token == null) return;

    for (var item in queue) {
      try {
        Response response;
        if (item.entity == 'TRANSACTION' && item.action == 'CREATE') {
          response = await _dio.post(
            '/transactions',
            data: item.data,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          if (response.statusCode == 201 || response.statusCode == 200) {
            await _localService.removeFromQueue(item.id);
          }
        } else if (item.entity == 'CATEGORY') {
          if (item.action == 'CREATE') {
            response = await _dio.post(
              '/products/categories',
              data: item.data,
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            );
          } else if (item.action == 'UPDATE') {
            final id = item.data['id'];
            response = await _dio.put(
              '/products/categories/$id',
              data: item.data,
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            );
          } else if (item.action == 'DELETE') {
            final id = item.data['id'];
            response = await _dio.delete(
              '/products/categories/$id',
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            );
          } else {
            continue;
          }

          if (response.statusCode == 200 || response.statusCode == 201) {
            await _localService.removeFromQueue(item.id);
          }
        } else if (item.entity == 'PRODUCT') {
          if (item.action == 'CREATE') {
            response = await _dio.post(
              '/products',
              data: item.data,
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            );
          } else if (item.action == 'UPDATE') {
            final id = item.data['id'];
            response = await _dio.put(
              '/products/$id',
              data: item.data,
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            );
          } else if (item.action == 'DELETE') {
            final id = item.data['id'];
            response = await _dio.delete(
              '/products/$id',
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            );
          } else {
            continue;
          }

          if (response.statusCode == 200 || response.statusCode == 201) {
            await _localService.removeFromQueue(item.id);
          }
        } else if (item.entity == 'PURCHASE' && item.action == 'CREATE') {
          response = await _dio.post(
            '/purchases',
            data: item.data,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          if (response.statusCode == 201 || response.statusCode == 200) {
            await _localService.removeFromQueue(item.id);
          }
        }
      } catch (e) {
        print("Failed to sync item ${item.id}: $e");
      }
    }
  }
}
