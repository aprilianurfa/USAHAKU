class PembelianItem {
  final String? id;
  final String productId;
  final String? productName;
  final int jumlah;
  final int hargaBeli;

  PembelianItem({
    this.id,
    required this.productId,
    this.productName,
    required this.jumlah,
    required this.hargaBeli,
  });

  factory PembelianItem.fromMap(Map<String, dynamic> map) {
    return PembelianItem(
      id: map['id']?.toString(),
      productId: map['product_id'].toString(),
      productName: map['Product']?['nama'],
      jumlah: map['jumlah'],
      hargaBeli: map['harga_beli'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'jumlah': jumlah,
      'harga_beli': hargaBeli,
    };
  }
}
