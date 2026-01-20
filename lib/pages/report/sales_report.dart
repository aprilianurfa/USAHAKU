import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../services/transaction_service.dart';
import '../../models/product_model.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';

enum SortMode { terbanyak, tersedikit }

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  final ProductService _productService = ProductService();
  final TransactionService _transactionService = TransactionService();

  String keyword = '';
  SortMode sortMode = SortMode.terbanyak;
  
  List<Barang> _products = [];
  List<Transaksi> _transactions = [];
  Map<String, String> _categoryMap = {}; // ID -> Name
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final products = await _productService.getProducts();
      final categories = await _productService.getCategories();
      final report = await _transactionService.getSalesReport(); 
      
      if (mounted) {
        setState(() {
          _products = products;
          _transactions = report.transactions;
          _categoryMap = {for (var c in categories) c.id: c.nama};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    }
  }

  // Optimized approach: Calculate map of sold counts once
  Map<String, int> _calculateSolds() {
    Map<String, int> soldMap = {};
    for (var trx in _transactions) {
      for (var item in trx.items) {
        // Use barangId as it is defined in TransaksiItem model
        String key = item.barangId.isNotEmpty ? item.barangId : item.namaBarang;
        soldMap[key] = (soldMap[key] ?? 0) + item.qty;
      }
    }
    return soldMap;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ================= PREPARE DATA =================
    final soldMap = _calculateSolds();

    final List<Map<String, dynamic>> data = _products.map((p) {
      int sold = soldMap[p.id] ?? 0;
      if (sold == 0) sold = soldMap[p.nama] ?? 0;

      return {
        'id': p.id,
        'nama': p.nama,
        'kategori': _categoryMap[p.kategoriId] ?? 'Umum', 
        'terjual': sold,
        'stok': p.stok,
      };
    }).toList();

    // ================= SEARCH =================
    final filtered = data.where((b) {
      return b['nama']
          .toString()
          .toLowerCase()
          .contains(keyword.toLowerCase());
    }).toList();

    // ================= SORT =================
    filtered.sort((a, b) => sortMode == SortMode.terbanyak
        ? b['terjual'].compareTo(a['terjual'])
        : a['terjual'].compareTo(b['terjual']));

    final int maxTerjual =
        filtered.isEmpty ? 0 : filtered.first['terjual'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan per Barang'),
      ),
      body: Column(
        children: [
          // ================= FILTER BOX =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // SEARCH
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari barang...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => keyword = v),
                ),
                const SizedBox(height: 10),

                // SORT
                DropdownButtonFormField<SortMode>(
                  value: sortMode,
                  items: const [
                    DropdownMenuItem(
                      value: SortMode.terbanyak,
                      child: Text('Penjualan Terbanyak'),
                    ),
                    DropdownMenuItem(
                      value: SortMode.tersedikit,
                      child: Text('Penjualan Tersedikit'),
                    ),
                  ],
                  onChanged: (v) => setState(() => sortMode = v!),
                  decoration: const InputDecoration(
                    labelText: 'Urutkan',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ================= LIST =================
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Data tidak ditemukan'),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final b = filtered[index];
                      final terjual = b['terjual'];

                      final isTerlaris =
                          terjual > 0 && terjual == maxTerjual;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.12),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.blue,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                b['nama'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isTerlaris)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Terlaris',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          'Kategori: ${b['kategori']}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              terjual.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Text(
                              'Terjual',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
