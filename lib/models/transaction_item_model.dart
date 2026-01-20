class TransaksiItem {
  final String barangId;
  final String namaBarang;
  final int harga;
  int qty;

  TransaksiItem({
    required this.barangId,
    required this.namaBarang,
    required this.harga,
    required this.qty,
  });

  int get subtotal => harga * qty;

  factory TransaksiItem.fromMap(Map<String, dynamic> map) {
    return TransaksiItem(
      barangId: (map['barangId'] ?? map['product_id'] ?? '').toString(),
      namaBarang: map['namaBarang'] ?? map['nama_barang'] ?? 'Unknown',
      harga: map['harga'] ?? 0,
      qty: map['qty'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barangId': barangId,
      'namaBarang': namaBarang,
      'harga': harga,
      'qty': qty,
      'subtotal': subtotal,
    };
  }
}
