import 'package:flutter/material.dart';

// AUTH
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';

// DASHBOARD
import '../pages/dashboard/dashboard_page.dart';
import '../pages/profile/profile_page.dart';

// BARANG & PEMBELIAN
import '../pages/product/product_page.dart';
import '../pages/product/category_page.dart';
import '../pages/product/purchase_page.dart';

// TRANSAKSI
import '../pages/transaction/transaction_page.dart';
import '../pages/transaction/transaction_history_page.dart';
import '../pages/transaction/printer_page.dart';
import '../pages/report/product_sales_report.dart';
import '../pages/report/transaction_report.dart';
import '../pages/report/cash_flow_report.dart';
import '../pages/report/expense_report.dart';
// LAPORAN
import '../pages/report/summary_report.dart';
import '../pages/report/sales_report.dart';
import '../pages/report/profit_loss_report.dart';
import '../pages/report/purchase_report.dart';
import '../pages/report/capital_report.dart';
import '../pages/report/visitor_report.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    // AUTH
    '/login': (context) => const LoginPage(),
    '/register': (context) => const RegisterPage(),

    // DASHBOARD - HAPUS 'const' DI SINI
    '/dashboard': (context) => DashboardPage(),
    '/profile': (context) => const ProfilePage(),

    // BARANG & STOK
    '/product': (context) => const BarangPage(),
    '/category': (context) => const KategoriPage(),
    '/purchase': (context) => const PembelianPage(),

    // TRANSAKSI
    '/transaction': (context) => const TransaksiPage(),
    '/transaction-history': (context) => const RiwayatTransaksiPage(),
    // Di dalam AppRoutes.routes
    '/printer-setting': (context) => PrinterPage(),

    // LAPORAN
    '/report': (context) => const LaporanRingkasanPage(),
    '/sales-report': (context) => const LaporanPenjualanPage(),
    '/profit-loss-report': (context) => const LaporanLabaRugiPage(),
    '/purchase-report': (context) => const LaporanPembelianPage(),
    '/capital-report': (context) => const LaporanModalPage(),
    '/visitor-report': (context) => const LaporanPengunjungPage(),
    '/product-sales-report': (context) => const LaporanPenjualanBarangPage(),
    '/transaction-report': (context) => const LaporanTransaksiPage(),
    '/cash-flow-report': (context) => const LaporanArusKasPage(),
    '/expense-report': (context) => const LaporanBiayaPage(),
  };
}