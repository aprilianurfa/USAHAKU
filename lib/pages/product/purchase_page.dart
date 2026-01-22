import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/product_model.dart';
import '../../models/purchase_model.dart';
import '../../models/purchase_item_model.dart';
import '../../services/product_service.dart';
import '../../services/purchase_service.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/purchase_provider.dart';
import '../../models/purchase_hive.dart';
import 'package:provider/provider.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final ProductService _productService = ProductService();
  final PurchaseService _purchaseService = PurchaseService();
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<Barang> _availableProducts = [];
  final List<PembelianItem> _cart = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getProducts();
      setState(() {
        _availableProducts = products;
      });
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  int get _totalBiaya {
    return _cart.fold(0, (sum, item) => sum + (item.jumlah * item.hargaBeli));
  }

  void _addProductToCart(Barang product) {
    setState(() {
      int index = _cart.indexWhere((item) => item.productId == product.id);
      if (index >= 0) {
        _cart[index] = PembelianItem(
          productId: _cart[index].productId,
          productName: _cart[index].productName,
          jumlah: _cart[index].jumlah + 1,
          hargaBeli: _cart[index].hargaBeli,
        );
      } else {
        _cart.add(PembelianItem(
          productId: product.id,
          productName: product.nama,
          jumlah: 1,
          hargaBeli: product.hargaDasar,
        ));
      }
    });
  }

  Future<void> _savePurchase() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih barang terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final purchaseHive = PurchaseHive(
        id: "LP-${DateTime.now().millisecondsSinceEpoch}",
        tanggal: DateTime.now(),
        supplier: _supplierController.text.trim(),
        totalBiaya: _totalBiaya,
        keterangan: _notesController.text.trim(),
        items: _cart.map((i) => PurchaseItemHive(
          productId: i.productId,
          productName: i.productName ?? "",
          jumlah: i.jumlah,
          hargaBeli: i.hargaBeli,
        )).toList(),
      );

      await context.read<PurchaseProvider>().saveLocalPurchase(purchaseHive);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembelian berhasil disimpan secara lokal dan akan disinkronkan.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("Input Pembelian Barang", style: TextStyle(fontWeight: FontWeight.bold)),
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
          // Stack for Header Extension and Floating Card
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Blue background extension
              Container(
                width: double.infinity,
                height: 50, 
                decoration: const BoxDecoration(
                  gradient: AppTheme.defaultGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),
              // Floating Card
              Padding(
                padding: const EdgeInsets.only(top: 10), // Small gap from top
                child: _buildTotalSummary(),
              ),
            ],
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 10), // Space after card (card height is included in flow but needs visual spacing)
                _buildForm(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Daftar Barang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _showProductPicker,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Pilih Barang"),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_cart.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 50, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text("Belum ada barang dipilih", style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                else
                  ..._cart.asMap().entries.map((entry) => _buildCartItem(entry.key, entry.value)),
                const SizedBox(height: 100), // Space for FAB
              ],
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
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            label: _isLoading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("SIMPAN PEMBELIAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            onPressed: _isLoading ? null : _savePurchase,
          ),
        ),
      ),
    );
  }



  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          TextField(
            controller: _supplierController,
            decoration: InputDecoration(
              labelText: "Nama Supplier",
              prefixIcon: const Icon(Icons.business_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: "Keterangan / Catatan",
              prefixIcon: const Icon(Icons.note_alt_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(int index, PembelianItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName ?? "Produk", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Jumlah", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(border: InputBorder.none),
                              onChanged: (v) {
                                int? val = int.tryParse(v);
                                if (val != null) {
                                  setState(() {
                                    _cart[index] = PembelianItem(
                                      productId: item.productId,
                                      productName: item.productName,
                                      jumlah: val,
                                      hargaBeli: item.hargaBeli,
                                    );
                                  });
                                }
                              },
                              controller: TextEditingController(text: item.jumlah.toString())..selection = TextSelection.fromPosition(TextPosition(offset: item.jumlah.toString().length)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Harga Beli", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(border: InputBorder.none, prefixText: "Rp "),
                              onChanged: (v) {
                                int? val = int.tryParse(v);
                                if (val != null) {
                                  setState(() {
                                    _cart[index] = PembelianItem(
                                      productId: item.productId,
                                      productName: item.productName,
                                      jumlah: item.jumlah,
                                      hargaBeli: val,
                                    );
                                  });
                                }
                              },
                              controller: TextEditingController(text: item.hargaBeli.toString())..selection = TextSelection.fromPosition(TextPosition(offset: item.hargaBeli.toString().length)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(onPressed: () => setState(() => _cart.removeAt(index)), icon: const Icon(Icons.delete_outline, color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildTotalSummary() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      // transform removed, handled by parent Stack
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.15), // Deep blue shadow
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Pembelian",
                style: TextStyle(
                  fontSize: 14, 
                  color: Colors.grey, 
                  fontWeight: FontWeight.w600
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 5),
                  Text(
                    "${_cart.length} Item",
                    style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            ],
          ),
          Text(
            currencyFormatter.format(_totalBiaya), 
            style: const TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.w800, 
              color: AppTheme.primaryColor
            )
          ),
        ],
      ),
    );
  }

  void _showProductPicker() {
    String search = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = _availableProducts.where((p) => p.nama.toLowerCase().contains(search.toLowerCase())).toList();
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text("Pilih Barang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                TextField(
                  onChanged: (v) => setModalState(() => search = v),
                  decoration: InputDecoration(
                    hintText: "Cari produk...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text("Produk tidak ditemukan"))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final p = filtered[index];
                            return ListTile(
                              leading: const CircleAvatar(backgroundColor: AppTheme.primaryColor, child: Icon(Icons.inventory_2_outlined, color: Colors.white, size: 20)),
                              title: Text(p.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Stok saat ini: ${p.stok}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                                onPressed: () {
                                  _addProductToCart(p);
                                  Navigator.pop(context);
                                },
                              ),
                              onTap: () {
                                _addProductToCart(p);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
