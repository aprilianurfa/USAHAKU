import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/category_model.dart';
import '../../models/category_hive.dart';
import '../../services/product_service.dart';
import '../../providers/product_provider.dart';
import '../../widgets/app_drawer.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final kategoriController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadCategories();
    });
  }

  Future<void> _addCategory() async {
    if (kategoriController.text.isEmpty) return;

    final tempId = "LOC-CAT-${DateTime.now().millisecondsSinceEpoch}";
    final newCat = CategoryHive(
      id: tempId,
      nama: kategoriController.text,
    );

    try {
      // 1. Save Locally
      await context.read<ProductProvider>().saveLocalCategory(newCat);
      
      // 2. Queue for Sync
      await context.read<ProductProvider>().addToSyncQueue(
        action: 'CREATE',
        entity: 'CATEGORY',
        data: newCat.toMap(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori disimpan secara lokal (antrean sinkronisasi)')),
        );
      }
      kategoriController.clear();
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
      // 1. Delete Locally
      await context.read<ProductProvider>().deleteLocalCategory(id);
      
      // 2. Queue for Sync
      await context.read<ProductProvider>().addToSyncQueue(
        action: 'DELETE',
        entity: 'CATEGORY',
        data: {'id': id},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori dihapus (antrean sinkronisasi)')),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,

      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("Kategori Barang", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.defaultGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ======================
          // CUSTOM HEADER
          // ======================
          // Search Bar Section (Modified from Header)
          Container(
            padding: const EdgeInsets.only(top: 10, bottom: 20, left: 16, right: 16),
            decoration: const BoxDecoration(
              gradient: AppTheme.defaultGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: TextField(
              onChanged: (val) {
                setState(() {
                   _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: "Cari kategori...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),

          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.categories.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                } else if (provider.error != null && provider.categories.isEmpty) {
                  return Center(child: Text('Error: ${provider.error}'));
                } else if (provider.categories.isEmpty) {
                  return const Center(child: Text('Belum ada kategori'));
                }

                final list = provider.categories
                  .map((c) => c.toKategori())
                  .where((cat) {
                    return cat.nama.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                if (list.isEmpty) {
                   return const Center(child: Text('Kategori tidak ditemukan'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final cat = list[index];
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.category, color: AppTheme.primaryColor),
                        ),
                        title: Text(cat.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _showTambahKategori(context, category: cat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey),
                              onPressed: () => _deleteCategory(cat.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: FloatingActionButton.extended(
            backgroundColor: AppTheme.primaryColor,
            elevation: 0, // Flat design
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              "TAMBAH KATEGORI BARU",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            onPressed: () => _showTambahKategori(context),
          ),
        ),
      ),
    );
  }

  void _showTambahKategori(BuildContext context, {Kategori? category}) {
    final isEdit = category != null;
    if (isEdit) {
      kategoriController.text = category.nama;
    } else {
      kategoriController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori'),
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
            onPressed: () async {
              if (kategoriController.text.isEmpty) return;
              
              if (isEdit) {
                Navigator.pop(context);
                try {
                  final updatedCat = CategoryHive(
                    id: category.id,
                    nama: kategoriController.text,
                  );

                  // 1. Update Locally
                  await context.read<ProductProvider>().saveLocalCategory(updatedCat);
                  
                  // 2. Queue for Sync
                  await context.read<ProductProvider>().addToSyncQueue(
                    action: 'UPDATE',
                    entity: 'CATEGORY',
                    data: updatedCat.toMap(),
                  );

                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategori diperbarui secara lokal')));
                } catch (e) {
                   if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              } else {
                _addCategory(); 
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
