import 'package:flutter/material.dart';
import 'home_page.dart';
import 'settings_page.dart';

class ManajemenBarangPage extends StatelessWidget {
  const ManajemenBarangPage({super.key});

  static const Color primaryBlue = Color(0xFF4DA3FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manajemen Barang"),
        backgroundColor: primaryBlue,
      ),
      drawer: _drawer(context),
      body: ListView(
        children: const [
          _Menu(icon: Icons.inventory, title: "Barang"),
          Divider(height: 1),
          _Menu(icon: Icons.category, title: "Kategori Barang"),
          Divider(height: 1),
          _Menu(icon: Icons.sync_alt, title: "Manajemen Stok"),
          Divider(height: 1),
          _Menu(icon: Icons.people, title: "Pelanggan"),
          Divider(height: 1),
          _Menu(icon: Icons.shopping_cart, title: "Pembelian Barang"),
        ],
      ),
    );
  }

  Drawer _drawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: primaryBlue),
            accountName: Text("Dilandarrr"),
            accountEmail: Text("Owner"),
            currentAccountPicture: CircleAvatar(child: Icon(Icons.person)),
          ),

          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Pengaturan"),
            onTap: () {
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
              onPressed: () {},
              child: const Text("Keluar"),
            ),
          )
        ],
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  final IconData icon;
  final String title;

  const _Menu({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
