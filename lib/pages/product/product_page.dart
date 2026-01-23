import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/product_provider.dart';
import '../../models/product_hive.dart';
import '../../widgets/app_drawer.dart';
import '../../config/constants.dart';
import 'product_form_page.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final allProducts = productProvider.products;
    final categories = productProvider.categories;
    
    // Combine provider search with category filter
    final filteredProducts = allProducts.where((p) {
      final matchesCategory = _selectedCategoryId == null || p.kategoriId == _selectedCategoryId;
      return matchesCategory;
    }).toList();

    int lowStockCount = allProducts.where((b) => b.stok <= b.minStok).length;
    final String userRole = context.watch<ProductProvider>().userRole;
    final bool isOwner = userRole == 'owner';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.defaultGradient,
          ),
        ),
        foregroundColor: Colors.white,
        title: const Text('Manajemen Barang', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              productProvider.performSync();
              if (productProvider.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(productProvider.error!)));
              }
            },
            icon: Icon(
              productProvider.isLoading ? Icons.sync : (productProvider.error != null ? Icons.warning_amber_rounded : Icons.refresh),
              color: productProvider.error != null ? Colors.orangeAccent : Colors.white,
            ),
            tooltip: productProvider.error ?? 'Refresh Data',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  if (lowStockCount > 0) {
                     _showLowStockAlert(context, allProducts.where((b) => b.stok <= b.minStok).toList());
                  }
                },
              ),
              if (lowStockCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$lowStockCount', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                  ),
                )
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header & Search Bar
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.defaultGradient,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => productProvider.searchProducts(v),
                  decoration: InputDecoration(
                    hintText: "Cari nama barang...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "Total Produk: ${allProducts.length}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (productProvider.pendingSyncCount > 0)
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                         decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                         child: Text("Pending: ${productProvider.pendingSyncCount}", style: const TextStyle(color: Colors.white, fontSize: 10)),
                       )
                  ],
                ),
              ],
            ),
          ),
          
          // Filter Kategori (Horizontal List)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip(null, "Semua"),
                ...categories.map((cat) => _buildCategoryChip(cat.id, cat.nama)),
              ],
            ),
          ),

          // List Barang
          Expanded(
            child: productProvider.isLoading && allProducts.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : filteredProducts.isEmpty 
                ? const Center(child: Text("Barang tidak ditemukan"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final item = filteredProducts[index];
                      return _buildProductCard(item, AppTheme.primaryColor, isOwner);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: !isOwner ? null : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.defaultGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
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
                    Text(
                      "TAMBAH BARANG BARU",
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductHive item, Color primaryColor, bool isOwner) {
    bool isLow = item.stok <= item.minStok;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductFormPage(barang: item.toBarang()),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Hero(
            tag: item.id,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.image != null && item.image!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: '${AppConstants.imageBaseUrl}${item.image}',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      errorWidget: (context, url, error) => Icon(Icons.inventory_2_rounded, color: primaryColor.withOpacity(0.5), size: 30),
                    )
                  : Center(child: Icon(Icons.inventory_2_rounded, color: primaryColor.withOpacity(0.5), size: 30)),
              ),
            ),
          ),
          title: Text(item.nama, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(currencyFormatter.format(item.harga), style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLow ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text("Stok: ${item.stok}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
          trailing: isOwner ? const Icon(Icons.edit, size: 20, color: Colors.grey) : null,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String? id, String label) {
    bool isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _selectedCategoryId = id;
          });
        },
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

  void _showLowStockAlert(BuildContext context, List<ProductHive> items) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Peringatan Stok Menipis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 10),
            ...items.map((e) => ListTile(
              title: Text(e.nama),
              trailing: Text("${e.stok} sisa", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            )),
          ],
        ),
      ),
    );
  }
}