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
      barangId: map['barangId'],
      namaBarang: map['namaBarang'],
      harga: map['harga'],
      qty: map['qty'],
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
