import 'package:flutter/material.dart';
import 'settings_page.dart';
import 'manajemen_barang_page.dart';
import 'transaksi_page.dart';
import 'laporan_page.dart';
import 'keuangan_page.dart';
import 'tambah_pegawai_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color primaryBlue = Color(0xFF4DA3FF);
  static const Color accentBlue = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "USAHAKU",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryBlue,
      ),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.store, size: 40, color: primaryBlue),
                  SizedBox(width: 12),
                  Text(
                    "Kasir Pintar UMKM",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// GRID MENU
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _menuItem(
                    context,
                    Icons.inventory,
                    "Manajemen Barang",
                    const ManajemenBarangPage(),
                  ),
                  _menuItem(
                    context,
                    Icons.point_of_sale,
                    "Transaksi Penjualan",
                    const TransaksiPage(),
                  ),
                  _menuItem(
                    context,
                    Icons.bar_chart,
                    "Laporan",
                    const LaporanPage(),
                  ),
                  _menuItem(
                    context,
                    Icons.account_balance_wallet,
                    "Keuangan",
                    const KeuanganPage(),
                  ),
                  _menuItem(
                    context,
                    Icons.group_add,
                    "Tambah Pegawai",
                    const TambahPegawaiPage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= MENU GRID ITEM =================
  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget page,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: accentBlue),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= DRAWER =================
  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: primaryBlue),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 36, color: primaryBlue),
            ),
            accountName: Text(
              "Dilandarrr",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            accountEmail: Text("Owner"),
          ),

          ListTile(
            leading: const Icon(Icons.settings, color: accentBlue),
            title: const Text("Pengaturan"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              onPressed: () {
                // TODO: logout
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: accentBlue),
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text(
                "Keluar",
                style: TextStyle(color: accentBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
