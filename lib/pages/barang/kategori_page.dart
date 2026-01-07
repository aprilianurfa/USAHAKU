import 'package:flutter/material.dart';
import '../../core/dummy_data.dart';

class KategoriPage extends StatefulWidget {
  const KategoriPage({super.key});

  @override
  State<KategoriPage> createState() => _KategoriPageState();
}

class _KategoriPageState extends State<KategoriPage> {
  final kategoriController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategori Barang')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTambahKategori(context),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: DummyData.kategori.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.category),
            title: Text(DummyData.kategori[index]['nama']),
          );
        },
      ),
    );
  }

  void _showTambahKategori(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Kategori'),
        content: TextField(
          controller: kategoriController,
          decoration: const InputDecoration(hintText: 'Nama kategori'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              DummyData.kategori.add({
                'id': DateTime.now().toString(),
                'nama': kategoriController.text,
              });
              kategoriController.clear();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
