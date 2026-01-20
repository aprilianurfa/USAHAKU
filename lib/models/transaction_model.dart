import 'transaction_item_model.dart';

class Transaksi {
  final String id;
  final DateTime tanggal;
  final String pelangganId;
  final String namaPelanggan;
  final List<TransaksiItem> items;
  final int totalBayar;
  final int bayar;
  final int kembalian;

  Transaksi({
    required this.id,
    required this.tanggal,
    required this.pelangganId,
    required this.namaPelanggan,
    required this.items,
    required this.totalBayar,
    required this.bayar,
    required this.kembalian,
  });

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'].toString(),
      tanggal: DateTime.parse(map['tanggal']),
      pelangganId: map['pelanggan_id'] ?? map['pelangganId'] ?? 'GUEST',
      namaPelanggan: map['nama_pelanggan'] ?? map['namaPelanggan'] ?? 'Umum',
      items: (map['items'] as List?)
              ?.map((e) => TransaksiItem.fromMap(e))
              .toList() ?? [],
      totalBayar: map['total_bayar'] ?? map['totalBayar'] ?? 0,
      bayar: map['bayar'] ?? 0,
      kembalian: map['kembalian'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tanggal': tanggal.toIso8601String(),
      'pelanggan_id': pelangganId,
      'nama_pelanggan': namaPelanggan,
      'items': items.map((e) => e.toMap()).toList(),
      'total_bayar': totalBayar,
      'bayar': bayar,
      'kembalian': kembalian,
    };
  }
}
