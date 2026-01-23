import '../models/transaction_model.dart';
import '../models/transaction_item_model.dart';
import '../models/transaction_hive.dart';
import '../services/transaction_service.dart';
import '../services/local_storage_service.dart';

class TransactionRepository {
  final TransactionService _service = TransactionService();
  final LocalStorageService _local = LocalStorageService();

  Future<List<Transaksi>> getAllTransactions({DateTime? startDate, DateTime? endDate, String? namaPelanggan}) async {
    // 1. Fetch from API (Remote)
    List<Transaksi> remoteTxs = [];
    bool remoteSuccess = false;
    try {
      remoteTxs = await _service.getTransactions(
        startDate: startDate, 
        endDate: endDate, 
        namaPelanggan: namaPelanggan
      );
      remoteSuccess = true;
    } catch (e) {
      print("Remote fetch failed: $e. Falling back to local only.");
    }

    // 2. Fetch from Local Hive
    // We fetch ALL local transactions if remote failed, 
    // OR just the UNSYNCED ones if remote succeeded.
    final localHiveTxs = _local.getLocalTransactions();
    
    final List<Transaksi> localToInclude = localHiveTxs
        .where((t) {
            // If remote succeeded, only include what hasn't been sent yet.
            // If remote failed, include EVERYTHING we have locally.
            if (remoteSuccess) {
              return !t.isSynced;
            }
            return true;
        })
        .map((t) => _mapHiveToTransaksi(t))
        .where((t) {
            // Apply Filters locally
            bool dateMatch = true;
            if (startDate != null && endDate != null) {
               // Normalizing end date to end of day is handled by the caller, 
               // but we do a safe check here.
               dateMatch = t.tanggal.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
                          t.tanggal.isBefore(endDate.add(const Duration(days: 1)));
            }
            bool customerMatch = true;
            if (namaPelanggan != null && namaPelanggan != 'Semua') {
               customerMatch = t.namaPelanggan.toLowerCase().contains(namaPelanggan.toLowerCase());
            }
            return dateMatch && customerMatch;
        })
        .toList();

    // 3. Merge & Deduplicate
    // Use a Map to deduplicate by ID if necessary (remote might have just finished syncing)
    final Map<String, Transaksi> dedupMap = {};
    
    for (var tx in remoteTxs) {
      dedupMap[tx.id] = tx;
    }
    for (var tx in localToInclude) {
      dedupMap[tx.id] = tx;
    }

    final combined = dedupMap.values.toList();
    combined.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    
    return combined;
  }

  Transaksi _mapHiveToTransaksi(TransactionHive h) {
    return Transaksi(
      id: h.id,
      tanggal: h.tanggal,
      pelangganId: h.pelangganId ?? 'GUEST',
      namaPelanggan: h.namaPelanggan ?? 'Umum',
      totalBayar: h.totalBayar,
      bayar: h.bayar,
      kembalian: h.kembalian,
      items: h.items.map((i) => TransaksiItem(
        barangId: i.productId,
        namaBarang: i.namaBarang,
        harga: i.harga,
        qty: i.qty,
      )).toList(),
    );
  }
}
