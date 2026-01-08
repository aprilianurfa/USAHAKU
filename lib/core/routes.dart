import 'package:flutter/material.dart';

// AUTH
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';

// DASHBOARD
import '../pages/dashboard/dashboard_page.dart';

// BARANG & PEMBELIAN
import '../pages/barang/barang_page.dart';
import '../pages/barang/kategori_page.dart';
import '../pages/barang/pembelian_page.dart';

// TRANSAKSI
import '../pages/transaksi/transaksi_page.dart';
import '../pages/transaksi/riwayat_transaksi_page.dart';
import '../pages/transaksi/printer_page.dart';
// LAPORAN
import '../pages/laporan/laporan_ringkasan.dart';
import '../pages/laporan/laporan_penjualan.dart';
import '../pages/laporan/laporan_laba_rugi.dart';
import '../pages/laporan/laporan_arus_kas.dart';
import '../pages/laporan/laporan_pembelian.dart';
import '../pages/laporan/laporan_modal.dart';
import '../pages/laporan/laporan_biaya.dart';
import '../pages/laporan/laporan_pengunjung.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    // AUTH
    '/login': (context) => const LoginPage(),
    '/register': (context) => const RegisterPage(),

    // DASHBOARD - HAPUS 'const' DI SINI
    '/dashboard': (context) => DashboardPage(),

    // BARANG & STOK
    '/barang': (context) => const BarangPage(),
    '/kategori': (context) => const KategoriPage(),
    '/pembelian': (context) => const PembelianPage(),

    // TRANSAKSI
    '/transaksi': (context) => const TransaksiPage(),
    '/riwayat-transaksi': (context) => const RiwayatTransaksiPage(),
    // Di dalam AppRoutes.routes
    '/printer-setting': (context) => PrinterPage(),

    // LAPORAN
    '/laporan': (context) => const LaporanRingkasanPage(),
    '/laporan-penjualan': (context) => const LaporanPenjualanPage(),
    '/laporan-laba-rugi': (context) => const LaporanLabaRugiPage(),
    '/laporan-arus-kas': (context) => const LaporanArusKasPage(),
    '/laporan-pembelian': (context) => const LaporanPembelianPage(),
    '/laporan-modal': (context) => const LaporanModalPage(),
    '/laporan-biaya': (context) => const LaporanBiayaPage(),
    '/laporan-pengunjung': (context) => const LaporanPengunjungPage(),
  };
}