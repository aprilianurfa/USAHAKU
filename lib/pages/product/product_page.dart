import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme.dart';
import '../../providers/product_provider.dart';
import '../../models/product_hive.dart';
import 'package:usahaku_main/core/app_shell.dart';
import 'package:usahaku_main/core/view_metrics.dart';
import '../../config/constants.dart';
import 'product_form_page.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductProvider>().loadProducts();
        _searchController.text = context.read<ProductProvider>().searchQuery;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _executeSearch(String query) {
    context.read<ProductProvider>().searchProducts(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // MANDATORY: Lock viewport
      resizeToAvoidBottomInset: false,
      appBar: const _ProductAppBar(),
      body: Column(
        children: [
          _ProductHeader(
            controller: _searchController,
            onSubmitted: _executeSearch,
          ),
          const _CategoryFilterSection(),
          const Expanded(
            child: _ProductListSection(),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const _AddProductFAB(),
    );
  }
}

class _ProductAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProductAppBar();

  @override
  Widget build(BuildContext context) {
    final lowStockCount = context.select<ProductProvider, int>((p) => p.lowStockCount);
    
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.defaultGradient)),
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => AppShell.of(context).toggleSidebar(),
      ),
      title: const Text('Manajemen Barang', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        _NotificationIcon(count: lowStockCount),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _NotificationIcon extends StatelessWidget {
  final int count;
  const _NotificationIcon({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {
            if (count > 0) {
              final lowStockItems = context.read<ProductProvider>().products.where((b) => b.stok <= b.minStok).toList();
              _showLowStockAlert(context, lowStockItems);
            }
          },
        ),
        if (count > 0)
          Positioned(
            right: 8, top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
            ),
          )
      ],
    );
  }

  void _showLowStockAlert(BuildContext context, List<ProductHive> items) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Peringatan Stok Menipis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 10),
            ...items.take(5).map((e) => ListTile(
              title: Text(e.nama),
              trailing: Text("${e.stok} sisa", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            )),
            if (items.length > 5) const Text("...dan lainnya"),
          ],
        ),
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  const _ProductHeader({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    final count = context.select<ProductProvider, int>((p) => p.filteredProducts.length);
    
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.defaultGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          RepaintBoundary(
            child: TextField(
              controller: controller,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: "Cari nama barang...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                suffixIcon: ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    return value.text.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear), 
                          onPressed: () {
                            controller.clear();
                            onSubmitted('');
                          })
                      : const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                "Total Produk: $count",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterSection extends StatelessWidget {
  const _CategoryFilterSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          final categories = provider.categories;
          final selectedId = provider.selectedCategoryId;
          
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _CategoryChip(id: "All", label: "Semua", selectedId: selectedId),
              ...categories.map((cat) => _CategoryChip(id: cat.id, label: cat.nama, selectedId: selectedId)),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String id;
  final String label;
  final String selectedId;
  const _CategoryChip({required this.id, required this.label, required this.selectedId});

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => context.read<ProductProvider>().setCategory(id),
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isSelected ? BorderSide.none : const BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
}

class _ProductListSection extends StatelessWidget {
  const _ProductListSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final products = provider.filteredProducts;
        final bool isLoading = provider.isLoading;
        final bool isOwner = provider.userRole == 'owner';

        if (isLoading && products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (products.isEmpty) {
          return const Center(child: Text("Barang tidak ditemukan"));
        }

        return RepaintBoundary(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) => _ProductCard(
              item: products[index], 
              isOwner: isOwner
            ),
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductHive item;
  final bool isOwner;
  const _ProductCard({required this.item, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final bool isLow = item.stok <= item.minStok;
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductFormPage(barang: item.toBarang())),
        ),
        borderRadius: BorderRadius.circular(15),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _ProductImage(id: item.id, imagePath: item.image),
          title: Text(item.nama, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatter.format(item.harga), style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              _StockBadge(stok: item.stok, isLow: isLow),
            ],
          ),
          trailing: isOwner ? const Icon(Icons.edit, size: 20, color: Colors.grey) : null,
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String id;
  final String? imagePath;
  const _ProductImage({required this.id, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: id,
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade100,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imagePath != null && imagePath!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: '${AppConstants.imageBaseUrl}$imagePath',
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                errorWidget: (_, __, ___) => const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryColor, size: 30),
              )
            : const Center(child: Icon(Icons.inventory_2_rounded, color: AppTheme.primaryColor, size: 30)),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stok;
  final bool isLow;
  const _StockBadge({required this.stok, required this.isLow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isLow ? Colors.red : Colors.green,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text("Stok: $stok", style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}

class _AddProductFAB extends StatelessWidget {
  const _AddProductFAB();

  @override
  Widget build(BuildContext context) {
    final bool isOwner = context.select<ProductProvider, bool>((p) => p.userRole == 'owner');
    if (!isOwner) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.defaultGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
            ]
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductFormPage()),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 10),
                  Text("TAMBAH BARANG BARU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
