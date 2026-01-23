import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import '../models/product_hive.dart';
import '../models/category_hive.dart';
import '../models/transaction_hive.dart';
import '../models/purchase_hive.dart';
import '../models/sync_queue.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../config/constants.dart';
import '../core/api_client.dart';

class SyncRepository {
  final Dio _dio = ApiClient().dio;
  final LocalStorageService _localService = LocalStorageService();
  final AuthService _authService = AuthService();

  SyncRepository();

  /// 1. DELTA SYNC (Inbound)
  Future<void> performDeltaSync() async {
    try {
      final lastSync = _localService.getLastSyncTime();
      final lastShopId = _localService.getLastSyncedShopId();
      final currentShopId = await _authService.getShopId();

      final bool isShopChanged = lastShopId != null && currentShopId != null && lastShopId != currentShopId;
      final bool isFirstSync = lastSync == null || isShopChanged;

      final response = await _dio.get(
        '/sync',
        queryParameters: {
          'lastSyncTime': isFirstSync ? null : lastSync.toIso8601String(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 304) {
        final data = response.data;
        if (data == null) return;
        
        // Merge Categories
        if (data['categories'] != null) {
          final cats = (data['categories'] as List).map((c) => CategoryHive(
            id: c['id'].toString(),
            nama: c['nama'],
            isDeleted: c['is_deleted'] ?? false,
          )).toList();
          await _localService.saveCategories(cats, clear: isFirstSync);
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
          await _localService.saveProducts(prods, clear: isFirstSync);
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
          await _localService.savePurchases(purhs, clear: isFirstSync);
        }
        
        // Merge Transactions
        if (data['transactions'] != null) {
          final txs = (data['transactions'] as List).map((t) => TransactionHive(
            id: t['id'].toString(),
            tanggal: DateTime.parse(t['tanggal']),
            namaPelanggan: t['nama_pelanggan'] ?? "Umum",
            totalBayar: t['total_bayar'] ?? 0,
            bayar: t['bayar'] ?? 0,
            kembalian: t['kembalian'] ?? 0,
            items: (t['TransactionItems'] as List? ?? []).map((i) => TransactionItemHive(
              productId: i['product_id']?.toString() ?? "",
              namaBarang: i['nama_barang'] ?? "Barang",
              harga: i['harga'] ?? 0,
              qty: i['qty'] ?? 0,
              subtotal: i['subtotal'] ?? 0,
            )).toList(),
            isSynced: true,
          )).toList();
          await _localService.saveTransactions(txs, clear: isFirstSync);
        }

        if (data['serverTime'] != null) {
          await _localService.setLastSyncTime(DateTime.parse(data['serverTime']));
        }
        if (currentShopId != null) {
          await _localService.setLastSyncedShopId(currentShopId);
        }
      }
    } catch (e) {
      print("[SyncRepo] Delta Sync Error: $e");
      rethrow;
    }
  }

  /// 2. PROCESS QUEUE (Outbound)
  Future<void> processSyncQueue() async {
    final queue = _localService.getQueue();
    if (queue.isEmpty) return;

    for (var item in queue) {
      try {
        Response response;
        if (item.entity == 'TRANSACTION' && item.action == 'CREATE') {
          final Map<String, dynamic> txData = Map<String, dynamic>.from(item.data);
          // ... Existing ID swapping logic for items ...
          final List<dynamic> itemsList = List<dynamic>.from(txData['items'] ?? []);
          for (var i = 0; i < itemsList.length; i++) {
            final String bId = itemsList[i]['barangId']?.toString() ?? "";
            if (bId.startsWith('LOC-P-')) {
               final p = await _localService.getProduct(bId);
               if (p != null && !p.id.startsWith('LOC-P-')) itemsList[i]['barangId'] = p.id;
            }
          }
          txData['items'] = itemsList;
          response = await _dio.post('/transactions', data: txData);

          // HANDLE RESPONSE (ID SWAP)
          if (response.statusCode == 200 || response.statusCode == 201) {
             final t = response.data['transaction'] ?? response.data; // Check structure
             if (t != null && t['id'] != null) {
                final newTx = TransactionHive(
                  id: t['id'].toString(),
                  tanggal: DateTime.parse(t['tanggal']),
                  namaPelanggan: t['nama_pelanggan'] ?? "Umum",
                  totalBayar: t['total_bayar'] ?? 0,
                  bayar: t['bayar'] ?? 0,
                  kembalian: t['kembalian'] ?? 0,
                  items: (t['TransactionItems'] as List? ?? []).map((i) => TransactionItemHive(
                    productId: i['product_id']?.toString() ?? "",
                    namaBarang: i['nama_barang'] ?? "Barang",
                    harga: i['harga'] ?? 0,
                    qty: i['qty'] ?? 0,
                    subtotal: i['subtotal'] ?? 0,
                  )).toList(),
                  isSynced: true,
                );
                await _localService.saveTransaction(newTx);
                if (item.data['id']?.toString().startsWith('LOC-') ?? false) {
                   await _localService.deleteTransactionFromDisk(item.data['id']);
                }
             }
          }

        } else if (item.entity == 'CATEGORY') {
          if (item.action == 'CREATE') {
            response = await _dio.post('/products/categories', data: item.data);
            
            // HANDLE RESPONSE (ID SWAP)
            if (response.statusCode == 200 || response.statusCode == 201) {
               final c = response.data;
               if (c != null && c['id'] != null) {
                  final newCat = CategoryHive(
                    id: c['id'].toString(),
                    nama: c['nama'],
                    isDeleted: c['is_deleted'] ?? false,
                  );
                  await _localService.saveCategory(newCat);
                  if (item.data['id']?.toString().startsWith('LOC-') ?? false) {
                     await _localService.deleteCategoryFromDisk(item.data['id']);
                  }
               }
            }
          } else if (item.action == 'UPDATE') {
            response = await _dio.put('/products/categories/${item.data['id']}', data: item.data);
          } else if (item.action == 'DELETE') {
            response = await _dio.delete('/products/categories/${item.data['id']}');
          } else {
            continue;
          }
        } else if (item.entity == 'PRODUCT') {
          dynamic requestData = item.data;
          if (item.data.containsKey('imageBytes') && item.data['imageBytes'] != null) {
            final formData = FormData();
            item.data.forEach((key, value) {
              if (key != 'imageBytes' && key != 'imageFilename') {
                formData.fields.add(MapEntry(key, value.toString()));
              }
            });
            final imageBytes = item.data['imageBytes'] as Uint8List;
            final filename = item.data['imageFilename'] as String? ?? 'image.jpg';
            formData.files.add(MapEntry('image', MultipartFile.fromBytes(imageBytes, filename: filename, contentType: MediaType('image', 'jpeg'))));
            requestData = formData;
          }

          if (item.action == 'CREATE') {
            response = await _dio.post('/products', data: requestData);
          } else if (item.action == 'UPDATE') {
            response = await _dio.put('/products/${item.data['id']}', data: requestData);
          } else if (item.action == 'DELETE') {
            response = await _dio.delete('/products/${item.data['id']}');
          } else {
            continue;
          }

          if ((response.statusCode == 200 || response.statusCode == 201) && item.action == 'CREATE') {
             try {
               final p = response.data;
               final newProduct = ProductHive(
                 id: p['id'].toString(),
                 nama: p['nama'],
                 harga: p['harga'] ?? 0,
                 hargaDasar: p['harga_dasar'] ?? 0,
                 stok: p['stok'] ?? 0,
                 minStok: p['min_stok'] ?? 0,
                 image: p['image'],
                 barcode: p['barcode'] ?? "",
                 isJasa: p['is_jasa'] ?? false,
                 kategoriId: p['kategori_id']?.toString() ?? "",
                 isDeleted: p['is_deleted'] ?? false,
               );
               await _localService.saveProduct(newProduct);
               if (item.data['id']?.toString().startsWith('LOC-') ?? false) {
                  await _localService.deleteProductFromDisk(item.data['id']);
               }
             } catch (e) { print("Error swapping IDs: $e"); }
          }
        } else if (item.entity == 'PURCHASE' && item.action == 'CREATE') {
          response = await _dio.post('/purchases', data: item.data);
        } else {
          continue;
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          await _localService.removeFromQueue(item.id);
        }
      } catch (e) {
        if (e is DioException) {
          print("[SyncRepo] Item ${item.id} failed: ${e.response?.statusCode} ${e.response?.data}");
        } else {
          print("[SyncRepo] Item ${item.id} failed: $e");
        }
        // Don't rethrow here to allow other items to attempt sync
      }
    }
  }
}
