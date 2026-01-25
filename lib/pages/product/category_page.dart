import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/category_model.dart';
import '../../models/category_hive.dart';
import '../../providers/product_provider.dart';
import 'package:usahaku_main/core/app_shell.dart';
import 'package:usahaku_main/core/view_metrics.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final TextEditingController _kategoriController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProductProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _kategoriController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final text = _kategoriController.text.trim();
    if (text.isEmpty) return;

    final tempId = "LOC-CAT-${DateTime.now().millisecondsSinceEpoch}";
    final newCat = CategoryHive(id: tempId, nama: text);

    try {
      final provider = context.read<ProductProvider>();
      await provider.saveLocalCategory(newCat);
      await provider.addToSyncQueue(action: 'CREATE', entity: 'CATEGORY', data: newCat.toMap());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategori disimpan')));
      }
      _kategoriController.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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

    if (confirm != true || !mounted) return;

    try {
      final provider = context.read<ProductProvider>();
      await provider.deleteLocalCategory(id);
      await provider.addToSyncQueue(action: 'DELETE', entity: 'CATEGORY', data: {'id': id});

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategori dihapus')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showTambahKategori(BuildContext context, {Kategori? category}) {
    final isEdit = category != null;
    _kategoriController.text = isEdit ? category.nama : '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori'),
        content: TextField(
          controller: _kategoriController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nama kategori'),
          onSubmitted: (_) {
            if (isEdit) {
               _handleUpdate(category.id);
            } else {
               _addCategory();
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => isEdit ? _handleUpdate(category.id) : _addCategory(),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdate(String id) async {
    final text = _kategoriController.text.trim();
    if (text.isEmpty) return;
    
    Navigator.pop(context);
    try {
      final provider = context.read<ProductProvider>();
      final updatedCat = CategoryHive(id: id, nama: text);
      await provider.saveLocalCategory(updatedCat);
      await provider.addToSyncQueue(action: 'UPDATE', entity: 'CATEGORY', data: updatedCat.toMap());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategori diperbarui')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // MANDATORY: Lock viewport
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => AppShell.of(context).toggleSidebar(),
        ),
        title: const Text("Kategori Barang", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.defaultGradient)),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const _CategorySearchHeader(),
          const Expanded(child: _CategoryListSection()),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _AddCategoryFAB(onPressed: () => _showTambahKategori(context)),
    );
  }
}

class _CategorySearchHeader extends StatelessWidget {
  const _CategorySearchHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 20, left: 16, right: 16),
      decoration: const BoxDecoration(
        gradient: AppTheme.defaultGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: RepaintBoundary(
        child: TextField(
          onSubmitted: (val) => context.read<ProductProvider>().searchCategories(val),
          textInputAction: TextInputAction.search,
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
    );
  }
}

class _CategoryListSection extends StatelessWidget {
  const _CategoryListSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final list = provider.filteredCategories;

        if (provider.isLoading && provider.categories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (list.isEmpty) {
          return Center(child: Text(provider.searchCategoryQuery.isNotEmpty ? 'Kategori tidak ditemukan' : 'Belum ada kategori'));
        }
        
        return RepaintBoundary(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _CategoryCard(category: list[index]),
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryHive category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.category, color: AppTheme.primaryColor),
        ),
        title: Text(category.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () {
                final state = context.findAncestorStateOfType<_CategoryPageState>();
                state?._showTambahKategori(context, category: category.toKategori());
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () {
                final state = context.findAncestorStateOfType<_CategoryPageState>();
                state?._deleteCategory(category.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddCategoryFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: FloatingActionButton.extended(
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("TAMBAH KATEGORI BARU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
