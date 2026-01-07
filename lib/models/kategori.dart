class Barang {
  final String id;
  final String nama;
  final String kategoriId;
  final int harga;
  int stok;
  final String barcode;
  final bool isJasa;

  Barang({
    required this.id,
    required this.nama,
    required this.kategoriId,
    required this.harga,
    required this.stok,
    required this.barcode,
    this.isJasa = false,
  });

  factory Barang.fromMap(Map<String, dynamic> map) {
    return Barang(
      id: map['id'],
      nama: map['nama'],
      kategoriId: map['kategoriId'],
      harga: map['harga'],
      stok: map['stok'],
      barcode: map['barcode'],
      isJasa: map['isJasa'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'kategoriId': kategoriId,
      'harga': harga,
      'stok': stok,
      'barcode': barcode,
      'isJasa': isJasa,
    };
  }
}class Kategori {
  final String id;
  final String nama;

  Kategori({
    required this.id,
    required this.nama,
  });

  factory Kategori.fromMap(Map<String, dynamic> map) {
    return Kategori(
      id: map['id'],
      nama: map['nama'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
    };
  }
}

