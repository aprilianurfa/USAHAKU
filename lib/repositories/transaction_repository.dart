import '../models/transaction_model.dart';
import '../models/transaction_item_model.dart';
import '../models/transaction_hive.dart';
import '../services/transaction_service.dart';
import '../services/local_storage_service.dart';
import 'sync_repository.dart';

class TransactionRepository {
  final TransactionService _service = TransactionService();
  final LocalStorageService _local = LocalStorageService();

  final SyncRepository _syncRepo = SyncRepository();

  /// Get transactions from Local Storage (Instant, Offline-first)
  Future<List<Transaksi>> getAllTransactions({DateTime? startDate, DateTime? endDate, String? namaPelanggan}) async {
    // 1. Fetch from Local Hive (Single Source of Truth)
    final localHiveTxs = _local.getLocalTransactions();
    
    final List<Transaksi> filteredTxs = localHiveTxs
        .map((t) => _mapHiveToTransaksi(t))
        .where((t) {
            // Apply Filters locally
            bool dateMatch = true;
            if (startDate != null && endDate != null) {
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

    // 2. Sort by Date Descending
    filteredTxs.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    
    return filteredTxs;
  }

  /// Trigger a background sync to update local data
  Future<void> sync() async {
    await _syncRepo.performDeltaSync(); // Pull new remotely
    await _syncRepo.processSyncQueue(); // Push local changes
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
