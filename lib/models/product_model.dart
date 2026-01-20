class Barang {
  final String id;
  final String nama;
  final String kategoriId;
  final int harga;
  final int hargaDasar;
  int stok;
  int minStok;
  final String barcode;
  final bool isJasa;
  final String? image; // New
  final bool isDeleted;

  Barang({
    required this.id,
    required this.nama,
    required this.kategoriId,
    required this.harga,
    required this.hargaDasar,
    required this.stok,
    required this.minStok,
    required this.barcode,
    this.isJasa = false,
    this.image, // New
    this.isDeleted = false,
  });

  factory Barang.fromMap(Map<String, dynamic> map) {
    return Barang(
      id: map['id'].toString(),
      nama: map['nama'],
      kategoriId: (map['kategori_id'] ?? map['kategoriId'])?.toString() ?? '', 
      harga: map['harga'],
      hargaDasar: map['harga_dasar'] ?? 0,
      stok: map['stok'],
      minStok: map['min_stok'] ?? 5,
      barcode: map['barcode'],
      isJasa: map['is_jasa'] ?? map['isJasa'] ?? false,
      image: map['image'], 
      isDeleted: map['is_deleted'] ?? map['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'kategori_id': kategoriId, // Fixed key
      'harga': harga,
      'harga_dasar': hargaDasar,
      'stok': stok,
      'min_stok': minStok,
      'barcode': barcode,
      'is_jasa': isJasa, // Fixed key
      'image': image, 
      'is_deleted': isDeleted,
    };
  }
}
