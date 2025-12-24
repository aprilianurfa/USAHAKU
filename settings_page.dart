import 'package:flutter/material.dart';
import 'home_page.dart';
import 'profile_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const Color primaryBlue = Color(0xFF4DA3FF);
  static const Color accentBlue = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text(
          "Pengaturan",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      drawer: _buildDrawer(context),
      body: ListView(
        children: [
          /// PROFIL
          _menuItem(
            icon: Icons.person,
            title: "Profil",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfilePage(),
                ),
              );
            },
          ),
          const Divider(height: 1),

          /// DATABASE
          _menuItem(
            icon: Icons.storage,
            title: "Database",
            onTap: () {},
          ),
          const Divider(height: 1),

          /// PRINTER
          _menuItem(
            icon: Icons.print,
            title: "Printer & Struk",
            onTap: () {},
          ),
          const Divider(height: 1),

          /// RESET
          _menuItem(
            icon: Icons.delete_forever,
            title: "Reset Semua Data",
            color: Colors.red,
            onTap: () {
              _confirmReset(context);
            },
          ),
        ],
      ),
    );
  }

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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            },
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              onPressed: () {
                // TODO: logout logic
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

  /// ================= MENU ITEM =================
  Widget _menuItem({
    required IconData icon,
    required String title,
    Color color = Colors.black,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  /// ================= RESET CONFIRM =================
  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset Semua Data"),
        content: const Text(
          "Semua data akan dihapus dan tidak dapat dikembalikan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              // TODO: reset data
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }
}
