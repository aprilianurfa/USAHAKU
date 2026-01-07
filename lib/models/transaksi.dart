import 'transaksi_item.dart';

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
      id: map['id'],
      tanggal: DateTime.parse(map['tanggal']),
      pelangganId: map['pelangganId'],
      namaPelanggan: map['namaPelanggan'],
      items: (map['items'] as List)
          .map((e) => TransaksiItem.fromMap(e))
          .toList(),
      totalBayar: map['totalBayar'],
      bayar: map['bayar'],
      kembalian: map['kembalian'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tanggal': tanggal.toIso8601String(),
      'pelangganId': pelangganId,
      'namaPelanggan': namaPelanggan,
      'items': items.map((e) => e.toMap()).toList(),
      'totalBayar': totalBayar,
      'bayar': bayar,
      'kembalian': kembalian,
    };
  }
}
