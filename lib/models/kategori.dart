class Kategori {
  final String id;
  final String nama;

  Kategori({
    required this.id,
    required this.nama,
  });

  factory Kategori.fromMap(Map<String, dynamic> map) {
    return Kategori(
      id: map['id'].toString(),
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

