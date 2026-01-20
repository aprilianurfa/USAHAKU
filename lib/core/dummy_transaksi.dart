import '../models/transaksi.dart';
import '../models/transaksi_item.dart';

class DummyTransaksi {
  static List<Transaksi> data = [
    Transaksi(
      id: 'TRX001',
      tanggal: DateTime(2026, 1, 15),
      pelangganId: 'P001',
      namaPelanggan: 'Andi',
      items: [
        TransaksiItem(
          barangId: 'B001',
          namaBarang: 'Kopi',
          harga: 15000,
          qty: 10,
        ),
      ],
      totalBayar: 150000,
      bayar: 200000,
      kembalian: 50000,
    ),

    Transaksi(
      id: 'TRX002',
      tanggal: DateTime(2026, 1, 16),
      pelangganId: 'P002',
      namaPelanggan: 'Budi',
      items: [
        TransaksiItem(
          barangId: 'B002',
          namaBarang: 'Teh',
          harga: 11000,
          qty: 20,
        ),
      ],
      totalBayar: 220000,
      bayar: 250000,
      kembalian: 30000,
    ),

    Transaksi(
      id: 'TRX003',
      tanggal: DateTime(2026, 1, 17),
      pelangganId: 'P003',
      namaPelanggan: 'Siti',
      items: [
        TransaksiItem(
          barangId: 'B003',
          namaBarang: 'Gula',
          harga: 18000,
          qty: 10,
        ),
      ],
      totalBayar: 180000,
      bayar: 200000,
      kembalian: 20000,
    ),

    Transaksi(
      id: 'TRX004',
      tanggal: DateTime(2026, 1, 18),
      pelangganId: 'P004',
      namaPelanggan: 'Rina',
      items: [
        TransaksiItem(
          barangId: 'B004',
          namaBarang: 'Susu',
          harga: 27500,
          qty: 10,
        ),
      ],
      totalBayar: 275000,
      bayar: 300000,
      kembalian: 25000,
    ),

    Transaksi(
      id: 'TRX005',
      tanggal: DateTime(2026, 1, 19),
      pelangganId: 'P005',
      namaPelanggan: 'Dewi',
      items: [
        TransaksiItem(
          barangId: 'B005',
          namaBarang: 'Roti',
          harga: 16000,
          qty: 20,
        ),
      ],
      totalBayar: 320000,
      bayar: 350000,
      kembalian: 30000,
    ),

    Transaksi(
      id: 'TRX006',
      tanggal: DateTime(2026, 1, 20),
      pelangganId: 'P006',
      namaPelanggan: 'Agus',
      items: [
        TransaksiItem(
          barangId: 'B006',
          namaBarang: 'Mie',
          harga: 40000,
          qty: 10,
        ),
      ],
      totalBayar: 400000,
      bayar: 450000,
      kembalian: 50000,
    ),
  ];
}
