class Pembelian {
  final String id;
  final DateTime tanggal;
  final String supplier;
  final int total;
  final String keterangan;

  Pembelian({
    required this.id,
    required this.tanggal,
    required this.supplier,
    required this.total,
    required this.keterangan,
  });

  factory Pembelian.fromMap(Map<String, dynamic> map) {
    return Pembelian(
      id: map['id'],
      tanggal: DateTime.parse(map['tanggal']),
      supplier: map['supplier'],
      total: map['total'],
      keterangan: map['keterangan'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tanggal': tanggal.toIso8601String(),
      'supplier': supplier,
      'total': total,
      'keterangan': keterangan,
    };
  }
}
