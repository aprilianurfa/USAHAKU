import 'package:flutter/material.dart';
import '../../models/kategori.dart';
import '../../services/product_service.dart';

class KategoriPage extends StatefulWidget {
  const KategoriPage({super.key});

  @override
  State<KategoriPage> createState() => _KategoriPageState();
}

class _KategoriPageState extends State<KategoriPage> {
  final _formKey = GlobalKey<FormState>();
  final kategoriController = TextEditingController();
  final ProductService _productService = ProductService();

  late Future<List<Kategori>> _futureCategories;

  @override
  void initState() {
    super.initState();
    _refreshCategories();
  }

  void _refreshCategories() {
    setState(() {
      _futureCategories = _productService.getCategories();
    });
  }

  Future<void> _addCategory() async {
    if (kategoriController.text.isEmpty) return;

    try {
      final result = await _productService.addCategory(kategoriController.text);
      if (result != null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kategori berhasil disimpan')),
          );
        }
        kategoriController.clear();
        _refreshCategories();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan kategori')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteCategory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: const Text('Menghapus kategori mungkin mempengaruhi barang yang terhubung.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Hapus')
          ),
        ],
      )
    );

    if (confirm != true) return;

    try {
       final success = await _productService.deleteCategory(id);
        if (success) {
        _refreshCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kategori dihapus')),
          );
        }
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus kategori')),
          );
        }
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategori Barang')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTambahKategori(context),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Kategori>>(
        future: _futureCategories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada kategori'));
          }

          final list = snapshot.data!;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final cat = list[index];
              return ListTile(
                leading: const Icon(Icons.category),
                title: Text(cat.nama),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => _deleteCategory(cat.id),
                ),
              );
            },
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
            onPressed: _addCategory,
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
