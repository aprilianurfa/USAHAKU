import 'package:flutter/material.dart';
import '../../core/dummy_data.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/menu_card.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/section_title.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ringkasan = DummyData.laporanRingkasan;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Dashboard Usahaku'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =========================
          // RINGKASAN HARI INI
          // =========================
          const SectionTitle(title: 'Ringkasan Hari Ini'),
          SummaryCard(
            title: 'Penjualan Hari Ini',
            value: ringkasan['penjualanHariIni'],
            icon: Icons.payments,
          ),
          SummaryCard(
            title: 'Laba Bersih',
            value: ringkasan['labaBersih'],
            icon: Icons.trending_up,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'Jumlah Transaksi',
                  value: ringkasan['jumlahTransaksi'],
                  icon: Icons.receipt_long,
                ),
              ),
              Expanded(
                child: SummaryCard(
                  title: 'Stok Menipis',
                  value: ringkasan['stokMenipis'],
                  icon: Icons.warning_amber,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // =========================
          // MENU UTAMA
          // =========================
          const SectionTitle(title: 'Menu Utama'),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: const [
              MenuCard(
                title: 'Manajemen Barang',
                icon: Icons.inventory,
                route: '/barang',
              ),
              MenuCard(
                title: 'Kategori Barang',
                icon: Icons.category,
                route: '/kategori',
              ),
              MenuCard(
                title: 'Pembelian Barang',
                icon: Icons.shopping_cart,
                route: '/pembelian',
              ),
              MenuCard(
                title: 'Transaksi',
                icon: Icons.point_of_sale,
                route: '/transaksi',
              ),
              MenuCard(
                title: 'Riwayat Transaksi',
                icon: Icons.receipt,
                route: '/riwayat-transaksi',
              ),
              MenuCard(
                title: 'Laporan',
                icon: Icons.bar_chart,
                route: '/laporan',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // =========================
          // INFO USAHA
          // =========================
          const SectionTitle(title: 'Informasi Usaha'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.store, color: Color(0xFF0A3D62)),
              title: const Text(
                'Usahaku POS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Aplikasi Kasir Pintar untuk UMKM'),
            ),
          ),
        ],
      ),
    );
  }
}
