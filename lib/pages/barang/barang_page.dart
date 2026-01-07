import 'package:flutter/material.dart';
import '../../core/dummy_data.dart';
import '../../widgets/app_drawer.dart';
import 'form_barang_page.dart'; // ✅ TAMBAHKAN IMPORT

class BarangPage extends StatefulWidget {
  const BarangPage({super.key});

  @override
  State<BarangPage> createState() => _BarangPageState();
}

class _BarangPageState extends State<BarangPage> {
  final List<Map<String, dynamic>> barang = DummyData.barang;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Manajemen Barang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FormBarangPage(), // ✅ HAPUS const
                ),
              );
              setState(() {});
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: barang.length,
        itemBuilder: (context, index) {
          final item = barang[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(item['nama']),
              subtitle: Text(
                'Stok: ${item['stok']} • ${item['kategori']}',
              ),
              trailing: Text(
                'Rp ${item['harga']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}
