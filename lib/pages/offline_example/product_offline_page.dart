import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../core/theme.dart';
import '../../models/product_hive.dart';

class ProductOfflinePage extends StatefulWidget {
  const ProductOfflinePage({super.key});

  @override
  State<ProductOfflinePage> createState() => _ProductOfflinePageState();
}

class _ProductOfflinePageState extends State<ProductOfflinePage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductProvider>().syncData(isLoadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Manajemen Barang (Optimized)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.defaultGradient)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white),
            onPressed: () => productProvider.loadProducts(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => productProvider.searchProducts(val),
              decoration: InputDecoration(
                hintText: "Cari barang...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Loading Indicator (Background Sync)
          if (productProvider.isLoading && !productProvider.hasMore)
            const LinearProgressIndicator(backgroundColor: Colors.transparent),

          // Product List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => productProvider.loadProducts(),
              child: productProvider.products.isEmpty && !productProvider.isLoading
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: productProvider.products.length + (productProvider.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == productProvider.products.length) {
                          return _buildLoader();
                        }
                        final product = productProvider.products[index];
                        return _buildProductCard(product);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildProductCard(ProductHive product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryColor),
        ),
        title: Text(product.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Stok: ${product.stok} | Rp ${product.harga}"),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text("Tidak ada data barang", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.read<ProductProvider>().syncData(),
            child: const Text("Tarik Data dari Server"),
          ),
        ],
      ),
    );
  }
}
