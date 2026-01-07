class Pelanggan {
  final String id;
  final String nama;
  final String noHp;

  Pelanggan({
    required this.id,
    required this.nama,
    required this.noHp,
  });

  factory Pelanggan.fromMap(Map<String, dynamic> map) {
    return Pelanggan(
      id: map['id'],
      nama: map['nama'],
      noHp: map['noHp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'noHp': noHp,
    };
  }
}
