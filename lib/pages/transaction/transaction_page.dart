import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart'; // Ensure this exists
import '../../models/transaction_model.dart';
import '../../models/transaction_item_model.dart';
import '../../services/product_service.dart';
import '../../services/transaction_service.dart';
import '../../config/constants.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  // Services
  final ProductService _productService = ProductService();
  final TransactionService _transactionService = TransactionService();

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerController = TextEditingController(text: "Umum");

  // Data
  List<Barang> _allProducts = [];
  List<Barang> _filteredProducts = [];
  List<Kategori> _categories = [];
  final List<TransaksiItem> _cart = [];
  
  // State
  String _selectedCategoryId = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productService.getProducts();
      final categories = await _productService.getCategories();
      
      if (mounted) {
        setState(() {
          _allProducts = products;
          _categories = categories;
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat data: $e")));
      }
    }
  }

  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        bool matchesCategory = _selectedCategoryId == 'All' || p.kategoriId == _selectedCategoryId;
        bool matchesSearch = p.nama.toLowerCase().contains(query);
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _addToCart(Barang product) {
    if (product.stok <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stok Habis!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      return;
    }

    setState(() {
      final index = _cart.indexWhere((item) => item.barangId == product.id);
      if (index != -1) {
        if (_cart[index].qty < product.stok) {
          _cart[index].qty++;
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stok tidak mencukupi")));
        }
      } else {
        _cart.add(TransaksiItem(
          barangId: product.id,
          namaBarang: product.nama,
          harga: product.harga,
          qty: 1,
        ));
      }
    });
  }

  void _updateQty(int index, int delta) {
    setState(() {
      final item = _cart[index];
      // Find original product to check stock
      final product = _allProducts.firstWhere((p) => p.id == item.barangId, orElse: () => Barang(id: '', nama: '', kategoriId: '', harga: 0, hargaDasar: 0, stok: 9999, minStok: 0, barcode: ''));
      
      if (delta > 0 && item.qty >= product.stok) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mencapai batas stok")));
         return;
      }

      item.qty += delta;
      if (item.qty <= 0) {
        _cart.removeAt(index);
      }
    });
  }

  int get _totalPrice => _cart.fold(0, (sum, item) => sum + item.subtotal);

  String _formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  void _showCheckoutDialog() {
    if (_cart.isEmpty) return;
    
    int total = _totalPrice;
    int uangDiterima = 0;
    int kembalian = 0;
    TextEditingController payController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          
          void calculateChange() {
            String clean = payController.text.replaceAll(RegExp(r'[^0-9]'), '');
            uangDiterima = int.tryParse(clean) ?? 0;
            kembalian = uangDiterima - total;
            setModalState(() {});
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Pembayaran", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                // Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Tagihan", style: TextStyle(fontSize: 16)),
                    Text(_formatCurrency(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  ],
                ),
                const Divider(height: 30),
                
                // Customer Name
                TextField(
                  controller: _customerController,
                  decoration: InputDecoration(
                    labelText: "Nama Pelanggan",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  ),
                ),
                const SizedBox(height: 15),

                // Payment Input
                TextField(
                  controller: payController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  onChanged: (val) => calculateChange(),
                  decoration: InputDecoration(
                    labelText: "Uang Diterima (Cash)",
                    prefixText: "Rp ",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.green, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                
                // Quick Money Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [20000, 50000, 100000, total].map((amount) {
                       return Padding(
                         padding: const EdgeInsets.only(right: 8.0),
                         child: ActionChip(
                           label: Text(amount == total ? "Uang Pas" : _formatCurrency(amount)),
                           backgroundColor: Colors.grey.shade100,
                           onPressed: () {
                             payController.text = amount.toString();
                             calculateChange();
                           },
                         ),
                       );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: kembalian >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Kembalian", style: TextStyle(fontWeight: FontWeight.bold, color: kembalian >= 0 ? Colors.green.shade800 : Colors.red.shade800)),
                      Text(_formatCurrency(kembalian), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kembalian >= 0 ? Colors.green.shade800 : Colors.red.shade800)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: (uangDiterima >= total) 
                         ? () => _processTransaction(total, uangDiterima, kembalian) 
                         : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("PROSES BAYAR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  Future<void> _processTransaction(int total, int bayar, int kembalian) async {
    // Close dialog first
    Navigator.pop(context);

    // Show loading
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final transaction = Transaksi(
        id: '',
        tanggal: DateTime.now(),
        pelangganId: 'GUEST', 
        namaPelanggan: _customerController.text.isEmpty ? "Umum" : _customerController.text,
        items: _cart,
        totalBayar: total,
        bayar: bayar,
        kembalian: kembalian,
      );

      final success = await _transactionService.createTransaction(transaction);
      
      // Close loading
      Navigator.pop(context);

      if (success) {
        // Show Success & Print Option
        _showSuccessDialog(total, bayar, kembalian);
        setState(() {
          _cart.clear();
          _customerController.text = "Umum";
        });
        _fetchData(); // Refresh stock
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaksi Gagal Disimpan!")));
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showSuccessDialog(int total, int bayar, int kembalian) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text("Pembayaran Berhasil"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Text("Total: ${_formatCurrency(total)}"),
             Text("Kembalian: ${_formatCurrency(kembalian)}"),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
               // TODO: Integrasi Printer Bluetooth
               Navigator.pop(ctx);
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Print belum terhubung")));
            }, 
            child: const Text("Cetak Struk")
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text("Transaksi Baru"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          Column(
            children: [
              // HEADER
              _buildHeader(),

              // CATEGORIES
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  children: [
                    _buildCategoryPill('All', 'Semua'),
                    ..._categories.map((c) => _buildCategoryPill(c.id, c.nama)),
                  ],
                ),
              ),

              // GRID PRODUCTS
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator()) 
                  : _filteredProducts.isEmpty
                    ? const Center(child: Text("Tidak ada produk"))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(15, 0, 15, 100), // Space for bottom cart
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : (MediaQuery.of(context).size.width < 360 ? 2 : 3),
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (ctx, i) => _buildProductCard(_filteredProducts[i]),
                      ),
              ),
            ],
          ),
          
          // BOTTOM CART PANEL (Floating)
          if (_cart.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildBottomCart(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 25),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
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
                   icon: const Icon(Icons.arrow_back, color: Colors.white), 
                   onPressed: () => Navigator.pop(context)
                 ),
               ),
               const SizedBox(width: 15),
               const Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text("Transaksi", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                     Text("Kasir Aktif", style: TextStyle(fontSize: 12, color: Colors.white70)),
                   ],
                 ),
               ),
               Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: Colors.white.withOpacity(0.2),
                   shape: BoxShape.circle,
                 ),
                 child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
               )
             ],
           ),
           const SizedBox(height: 20),
           TextField(
             controller: _searchController,
             onChanged: (val) => _filterProducts(),
             style: const TextStyle(color: Colors.black87),
             decoration: InputDecoration(
               hintText: "Cari produk...",
               hintStyle: TextStyle(color: Colors.grey.shade500),
               prefixIcon: Icon(Icons.search, size: 24, color: Colors.indigo.shade300),
               filled: true,
               fillColor: Colors.white,
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
               contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
               suffixIcon: _searchController.text.isNotEmpty 
                 ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _filterProducts();
                    },
                   )
                 : null,
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String id, String label) {
    bool isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          setState(() {
            _selectedCategoryId = id;
            _filterProducts();
          });
        },
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
        backgroundColor: Colors.white,
        side: isSelected ? BorderSide.none : const BorderSide(color: Colors.black12),
      ),
    );
  }

  Widget _buildProductCard(Barang product) {
    return GestureDetector(
      onTap: () => _addToCart(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  image: product.image != null && product.image!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage('${AppConstants.imageBaseUrl}${product.image}'), 
                          fit: BoxFit.cover,
                          onError: (e, s) {}, // Handle error gracefully usually relies on builder but for DecorationImage we might see blank or need advanced Image widget.
                        ) 
                      : null
                ),
                child: product.image == null || product.image!.isEmpty
                  ? Center(child: Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey.shade400)) 
                  : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(_formatCurrency(product.harga), style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text("Stok: ${product.stok}", style: TextStyle(fontSize: 10, color: product.stok < 5 ? Colors.red : Colors.grey)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCart() {
    return GestureDetector(
      onTap: () {
        // Expand cart detail (Modal Bottom Sheet)
        _showCartDetail();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2633),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
          ]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              child: Text("${_cart.fold(0, (sum, i) => sum + i.qty)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Total", style: TextStyle(color: Colors.white60, fontSize: 10)),
                Text(_formatCurrency(_totalPrice), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _showCheckoutDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              ),
              child: const Row(
                children: [
                   Text("Bayar"),
                   SizedBox(width: 5),
                   Icon(Icons.arrow_forward, size: 16)
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showCartDetail() {
     showModalBottomSheet(
       context: context, 
       backgroundColor: Colors.white,
       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
       builder: (ctx) {
         return StatefulBuilder(
           builder: (context, setModalState) {
             return Container(
               padding: const EdgeInsets.all(20),
               height: MediaQuery.of(context).size.height * 0.6,
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Center(child: Container(width: 40, height: 4, color: Colors.grey.shade300)),
                   const SizedBox(height: 20),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        const Text("Detail Pesanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                           onPressed: () {
                             setState(() => _cart.clear());
                             Navigator.pop(context);
                           }, 
                           child: const Text("Hapus Semua", style: TextStyle(color: Colors.red))
                        )
                     ],
                   ),
                   Expanded(
                     child: ListView.separated(
                       itemCount: _cart.length,
                       separatorBuilder: (_, __) => const Divider(),
                       itemBuilder: (ctx, i) {
                         final item = _cart[i];
                         return ListTile(
                           contentPadding: EdgeInsets.zero,
                           title: Text(item.namaBarang, style: const TextStyle(fontWeight: FontWeight.bold)),
                           subtitle: Text(_formatCurrency(item.harga)),
                           trailing: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               IconButton(
                                 icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                                 onPressed: () {
                                   _updateQty(i, -1);
                                   setModalState((){});
                                 },
                               ),
                               Text("${item.qty}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                               IconButton(
                                 icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                                 onPressed: () {
                                   _updateQty(i, 1);
                                   setModalState((){});
                                 },
                               ),
                             ],
                           ),
                         );
                       },
                     ),
                   )
                 ],
               ),
             );
           }
         );
       }
     );
  }
}
