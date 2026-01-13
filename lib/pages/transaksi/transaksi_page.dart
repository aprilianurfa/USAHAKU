import 'package:flutter/material.dart';
import '../../models/barang.dart';
import '../../models/transaksi.dart';
import '../../models/transaksi_item.dart';
import '../../services/product_service.dart';
import '../../services/transaction_service.dart';

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  final TextEditingController searchController = TextEditingController();
  final ProductService _productService = ProductService();
  final TransactionService _transactionService = TransactionService();

  // Used for customer name input instead of dropdown for now
  final TextEditingController pelangganController = TextEditingController();

  List<Barang> _allProducts = [];
  List<Barang> _filteredProducts = [];
  final List<TransaksiItem> keranjang = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    // Default guest
    pelangganController.text = "Umum";
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getProducts();
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat produk: $e')),
        );
      }
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _allProducts.where((b) {
        return b.nama.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void tambahKeKeranjang(Barang barang) {
    if (barang.stok <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok habis!')),
      );
      return;
    }

    final index = keranjang.indexWhere((e) => e.barangId == barang.id);
    if (index >= 0) {
       // Check if adding more exceeds stock
       if (keranjang[index].qty + 1 > barang.stok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stok tidak mencukupi!')),
          );
          return;
       }
       setState(() {
         keranjang[index].qty++;
       });
    } else {
      setState(() {
        keranjang.add(TransaksiItem(
          barangId: barang.id,
          namaBarang: barang.nama,
          harga: barang.harga,
          qty: 1,
        ));
      });
    }
  }

  int get totalBayar {
    int total = 0;
    for (var item in keranjang) {
      total += item.subtotal;
    }
    return total;
  }

  Future<void> _simpanTransaksi() async {
    if (keranjang.isEmpty) return;

    try {
      final transaksi = Transaksi(
        id: '', // Backend generetes ID
        tanggal: DateTime.now(),
        pelangganId: 'GUEST', // Or handle if we have real customers
        namaPelanggan: pelangganController.text,
        items: keranjang,
        totalBayar: totalBayar,
        bayar: totalBayar, // Implementing direct payment for now
        kembalian: 0,
      );

      final success = await _transactionService.createTransaction(transaksi);
      if (success) {
        setState(() {
          keranjang.clear();
          pelangganController.text = "Umum";
        });
        _loadProducts(); // Reload stock
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil disimpan')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan transaksi')),
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
      appBar: AppBar(
        title: const Text('Transaksi Penjualan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Barcode',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scan barcode (belum aktif)'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Produk',
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          // ======================
          // PILIH PELANGGAN
          // ======================
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: pelangganController,
              decoration: const InputDecoration(
                labelText: 'Nama Pelanggan',
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ),

          // ======================
          // SEARCH BARANG
          // ======================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Cari barang / jasa',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterProducts,
            ),
          ),

          // ======================
          // DAFTAR BARANG
          // ======================
          Expanded(
            child: ListView.builder(
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final b = _filteredProducts[index];
                return ListTile(
                  title: Text(b.nama),
                  subtitle: Text('Stok: ${b.stok}'),
                  trailing: Text('Rp ${b.harga}'),
                  onTap: () => tambahKeKeranjang(b),
                );
              },
            ),
          ),

          const Divider(),

          // ======================
          // KERANJANG
          // ======================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keranjang',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView(
                    shrinkWrap: true,
                    children: keranjang.map(
                      (k) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${k.namaBarang} x${k.qty}')),
                          Text('Rp ${k.subtotal}'),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.red),
                            onPressed: () {
                               setState(() {
                                 keranjang.remove(k);
                               });
                            },
                          )
                        ],
                      ),
                    ).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rp $totalBayar',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: keranjang.isEmpty ? null : _simpanTransaksi,
                    child: const Text('Simpan Transaksi'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
