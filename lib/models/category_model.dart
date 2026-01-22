class Kategori {
  final String id;
  final String nama;
  final bool isDeleted;

  Kategori({
    required this.id,
    required this.nama,
    this.isDeleted = false,
  });

  factory Kategori.fromMap(Map<String, dynamic> map) {
    return Kategori(
      id: map['id'].toString(),
      nama: map['nama'],
      isDeleted: map['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'is_deleted': isDeleted,
    };
  }
}

