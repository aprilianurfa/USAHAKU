import 'purchase_item_model.dart';

class Pembelian {
  final String id;
  final DateTime tanggal;
  final String supplier;
  final int totalBiaya;
  final String keterangan;
  final List<PembelianItem> items;

  Pembelian({
    required this.id,
    required this.tanggal,
    required this.supplier,
    required this.totalBiaya,
    required this.keterangan,
    this.items = const [],
  });

  factory Pembelian.fromMap(Map<String, dynamic> map) {
    var itemsList = (map['PurchaseItems'] as List?) ?? [];
    
    return Pembelian(
      id: map['id'].toString(),
      tanggal: DateTime.parse(map['tanggal']),
      supplier: map['supplier'] ?? "",
      totalBiaya: map['total_biaya'] ?? 0,
      keterangan: map['keterangan'] ?? "",
      items: itemsList.map((i) => PembelianItem.fromMap(i)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'supplier': supplier,
      'total_biaya': totalBiaya,
      'keterangan': keterangan,
      'items': items.map((i) => i.toMap()).toList(),
    };
  }
}
