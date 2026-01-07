class Laporan {
  final int totalPenjualan;
  final int totalPembelian;
  final int labaBersih;
  final int modal;
  final int biaya;
  final int jumlahTransaksi;
  final int jumlahPengunjung;

  Laporan({
    required this.totalPenjualan,
    required this.totalPembelian,
    required this.labaBersih,
    required this.modal,
    required this.biaya,
    required this.jumlahTransaksi,
    required this.jumlahPengunjung,
  });

  factory Laporan.fromMap(Map<String, dynamic> map) {
    return Laporan(
      totalPenjualan: map['totalPenjualan'],
      totalPembelian: map['totalPembelian'],
      labaBersih: map['labaBersih'],
      modal: map['modal'],
      biaya: map['biaya'],
      jumlahTransaksi: map['jumlahTransaksi'],
      jumlahPengunjung: map['jumlahPengunjung'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalPenjualan': totalPenjualan,
      'totalPembelian': totalPembelian,
      'labaBersih': labaBersih,
      'modal': modal,
      'biaya': biaya,
      'jumlahTransaksi': jumlahTransaksi,
      'jumlahPengunjung': jumlahPengunjung,
    };
  }
}
