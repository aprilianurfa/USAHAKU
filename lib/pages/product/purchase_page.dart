import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/product_model.dart';
import '../../models/purchase_model.dart';
import '../../models/purchase_item_model.dart';
import '../../services/product_service.dart';
import '../../services/purchase_service.dart';

class PembelianPage extends StatefulWidget {
  const PembelianPage({super.key});

  @override
  State<PembelianPage> createState() => _PembelianPageState();
}

class _PembelianPageState extends State<PembelianPage> {
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
      final pembelian = Pembelian(
        id: "", // Server will generate
        tanggal: DateTime.now(),
        supplier: _supplierController.text.trim(),
        totalBiaya: _totalBiaya,
        keterangan: _notesController.text.trim(),
        items: _cart,
      );

      final result = await _purchaseService.createPurchase(pembelian);
      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pembelian berhasil disimpan. Stok diperbarui.')),
          );
          Navigator.pop(context, true);
        }
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
      body: Column(
        children: [
          _buildHeader(),
          _buildTotalSummary(), // Fixed at top
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 16),
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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 20 + MediaQuery.of(context).padding.top, 10, 20),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context), 
                  icon: const Icon(Icons.arrow_back, color: Colors.white)
                ),
              ),
              const Expanded(
                child: Text(
                  "Input Pembelian Barang",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ],
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      transform: Matrix4.translationValues(0, -15, 0), // Floating effect
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        // Use a very subtle border instead of shadow for flat design
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Total Pembelian", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(
            currencyFormatter.format(_totalBiaya), 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)
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
