import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../services/product_service.dart';
import '../../widgets/app_drawer.dart';
import '../../config/constants.dart';
import 'product_form_page.dart';
import 'package:intl/intl.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final ProductService _productService = ProductService();
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
  
  List<Barang> _allBarang = [];
  List<Barang> _filteredBarang = [];
  List<Kategori> _categories = [];
  
  String _searchQuery = "";
  String? _selectedCategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      print('Loading data...');
      final results = await Future.wait([
        _productService.getProducts(),
        _productService.getCategories(),
      ]);
      print('Data loaded. Products: ${(results[0] as List).length}, Categories: ${(results[1] as List).length}');
      
      if (mounted) {
        setState(() {
          _allBarang = results[0] as List<Barang>;
          _categories = results[1] as List<Kategori>;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _loadData: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilter() {
    setState(() {
      print('Applying filter. Selected Category: $_selectedCategoryId');
      _filteredBarang = _allBarang.where((item) {
        final matchesSearch = item.nama.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategoryId == null || item.kategoriId == _selectedCategoryId;
        
        // Debug filtering
        if (_selectedCategoryId != null && item.kategoriId != _selectedCategoryId) {
           print('Filtered out: ${item.nama} (CatID: ${item.kategoriId}) vs Selected: $_selectedCategoryId');
        }
        
        return matchesSearch && matchesCategory;
      }).toList();
      print('Filtered count: ${_filteredBarang.length}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primaryColor;
    int lowStockCount = _allBarang.where((b) => b.stok <= b.minStok).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Manajemen Barang', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Notifikasi Stok Menipis
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  if (lowStockCount > 0) {
                    _showLowStockAlert(context, _allBarang.where((b) => b.stok <= b.minStok).toList());
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
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) {
                    _searchQuery = v;
                    _applyFilter();
                  },
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
                      "Total Produk: ${_allBarang.length}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    if (_allBarang.length != _filteredBarang.length) ...[
                      const Spacer(),
                      Text(
                        "Ditampilkan: ${_filteredBarang.length}",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
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
                ..._categories.map((cat) => _buildCategoryChip(cat.id, cat.nama)),
              ],
            ),
          ),

          // List Barang
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredBarang.isEmpty 
                ? const Center(child: Text("Barang tidak ditemukan"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredBarang.length,
                    itemBuilder: (context, index) {
                      final item = _filteredBarang[index];
                      return _buildProductCard(item, primaryColor);
                    },
                  ),
          ),
        ],
      ),
     // Letakkan ini di dalam Scaffold
  floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
  floatingActionButton: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0), // Margin kiri-kanan
    child: SizedBox(
      width: double.infinity, // Membuat lebar penuh mengikuti padding
      height: 55, // Tinggi tombol agar terlihat kokoh
      child: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0, // Flat design
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Sudut membulat selaras tema
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "TAMBAH BARANG BARU",
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductFormPage()),
        ).then((_) => _loadData()),
      ),
    ),
  ),
  );
  }

  Widget _buildProductCard(Barang item, Color primaryColor) {
    bool isLow = item.stok <= item.minStok;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductFormPage(barang: item),
            ),
          ).then((result) { if (result == true) _loadData(); });
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
                image: item.image != null && item.image!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage('${AppConstants.imageBaseUrl}${item.image}'), 
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        // Fallback logic handled by child
                      },
                    )
                  : null,
              ),
              child: item.image == null || item.image!.isEmpty
                ? Center(child: Icon(Icons.inventory_2_rounded, color: primaryColor.withOpacity(0.5), size: 30))
                : null,
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
          trailing: const Icon(Icons.edit, size: 20), // Changed icon to indicate edit
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
          // Always select validation. If 'Semua' (null), allow.
          setState(() {
            _selectedCategoryId = id;
            _applyFilter();
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

  void _showLowStockAlert(BuildContext context, List<Barang> items) {
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