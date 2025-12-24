import 'package:flutter/material.dart';
import 'home_page.dart';
import 'settings_page.dart';

class TambahPegawaiPage extends StatelessWidget {
  const TambahPegawaiPage({super.key});

  static const Color primaryBlue = Color(0xFF4DA3FF);
  static const Color accentBlue = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Tambah Pegawai",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryBlue,
      ),
      drawer: _buildDrawer(context),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field("Nama Pegawai"),
          _field("Email"),
          _field("No. Telepon"),

          /// ROLE
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: "Role",
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: "Admin", child: Text("Admin")),
              DropdownMenuItem(value: "Kasir", child: Text("Kasir")),
            ],
            onChanged: (value) {},
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                // TODO: simpan pegawai
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentBlue,
              ),
              child: const Text(
                "Simpan Pegawai",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= FORM FIELD =================
  Widget _field(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
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
