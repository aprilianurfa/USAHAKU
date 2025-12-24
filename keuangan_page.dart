import 'package:flutter/material.dart';
import 'home_page.dart';
import 'settings_page.dart';

class KeuanganPage extends StatelessWidget {
  const KeuanganPage({super.key});

  static const Color primaryBlue = Color(0xFF4DA3FF);
  static const Color accentBlue = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Keuangan",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryBlue,
      ),
      drawer: _buildDrawer(context),
      body: ListView(
        children: [
          _menu(Icons.show_chart, "Laporan Laba Rugi"),
          _divider(),
          _menu(Icons.account_balance, "Laporan Arus Keuangan"),
          _divider(),
          _menu(Icons.money_off, "Laporan Biaya"),
          _divider(),
          _menu(Icons.savings, "Laporan Modal"),
        ],
      ),
    );
  }

  /// ================= MENU ITEM =================
  Widget _menu(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: accentBlue),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: arahkan ke halaman detail laporan
      },
    );
  }

  Widget _divider() => const Divider(height: 1);

  /// ================= DRAWER =================
  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: primaryBlue),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 36, color: primaryBlue),
            ),
            accountName: const Text(
              "Dilandarrr",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            accountEmail: const Text("Owner"),
          ),

          ListTile(
            leading: const Icon(Icons.home, color: accentBlue),
            title: const Text("Home"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            },
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
