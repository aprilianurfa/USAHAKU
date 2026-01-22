import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../config/constants.dart';
import '../../widgets/app_drawer.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../models/transaction_item_model.dart';
import '../../services/product_service.dart';
import '../../services/transaction_service.dart';
import '../../services/printer_service.dart';
import '../../services/auth_service.dart';
import '../../providers/product_provider.dart';
import '../../models/product_hive.dart';
import '../../models/transaction_hive.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  // Services
  final TransactionService _transactionService = TransactionService();
  final PrinterService _printerService = PrinterService();
  final AuthService _authService = AuthService();

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerController = TextEditingController(text: "Umum");

  // Data
  List<Kategori> _categories = [];
  List<String> _customerNames = [];
  final List<TransaksiItem> _cart = [];
  
  // State
  String _selectedCategoryId = 'All';
  String _shopName = "USAHAKU";
  String? _shopLogo;

  @override
  void initState() {
    super.initState();
    // Load products from Hive instantly + sync in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      _fetchSecondaryData();
    });
  }

  Future<void> _fetchSecondaryData() async {
    try {
      // These are relatively lightweight or already optimized
      final customers = await _transactionService.getCustomerNames();
      final profile = await _authService.getProfile();

      if (mounted) {
        setState(() {
          _customerNames = customers;
          if (profile != null && profile['Shop'] != null) {
            _shopName = profile['Shop']['nama_toko'] ?? "USAHAKU";
            _shopLogo = profile['Shop']['logo'];
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching secondary data: $e");
    }
  }

  // No manual _getFilteredProducts needed, we use provider directly


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
      final products = context.read<ProductProvider>().products;
      final product = products.firstWhere((p) => p.id == item.barangId, orElse: () => ProductHive(id: '', nama: '', kategoriId: '', harga: 0, hargaDasar: 0, stok: 9999, minStok: 0, barcode: ''));
      
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
                
                // Customer Name (Autocomplete)
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return _customerNames.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    _customerController.text = selection;
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    // Sync controllers
                    textEditingController.text = _customerController.text;
                    textEditingController.addListener(() {
                       _customerController.text = textEditingController.text;
                    });

                    return TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: "Nama Pelanggan",
                        hintText: "Ketik atau pilih pelanggan...",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        suffixIcon: PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (String value) {
                            textEditingController.text = value;
                            _customerController.text = value;
                          },
                          itemBuilder: (BuildContext context) {
                            return _customerNames.map((String choice) {
                              return PopupMenuItem<String>(
                                value: choice,
                                child: Text(choice),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    );
                  },
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
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: AppTheme.defaultGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                    ]
                  ),
                  child: ElevatedButton(
                    onPressed: (uangDiterima >= total) 
                         ? () => _processTransaction(total, uangDiterima, kembalian) 
                         : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("PROSES BAYAR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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

    // OPTIMISTIC UI: Save locally first
    String localId = "LOC-${DateTime.now().millisecondsSinceEpoch}";
    
    final transactionHive = TransactionHive(
      id: localId,
      tanggal: DateTime.now(),
      namaPelanggan: _customerController.text.isEmpty ? "Umum" : _customerController.text,
      totalBayar: total,
      bayar: bayar,
      kembalian: kembalian,
      items: _cart.map((item) => TransactionItemHive(
        productId: item.barangId,
        namaBarang: item.namaBarang,
        harga: item.harga,
        qty: item.qty,
        subtotal: item.subtotal,
      )).toList(),
      isSynced: false,
    );

    try {
      // 1. Save to local Hive
      await context.read<ProductProvider>().saveLocalTransaction(transactionHive);

      // 2. Add to Sync Queue
      context.read<ProductProvider>().addToSyncQueue(
        action: 'CREATE',
        entity: 'TRANSACTION',
        data: {
          'tanggal': transactionHive.tanggal.toIso8601String(),
          'nama_pelanggan': transactionHive.namaPelanggan,
          'total_bayar': transactionHive.totalBayar,
          'bayar': transactionHive.bayar,
          'kembalian': transactionHive.kembalian,
          'items': _cart.map((item) => item.toMap()).toList(),
        },
      );

      // 3. Show Success Instantly
      // Convert to legacy Transaksi model for dialog/print logic compatibility
      final legacyTx = Transaksi(
        id: localId,
        tanggal: transactionHive.tanggal,
        pelangganId: 'GUEST',
        namaPelanggan: transactionHive.namaPelanggan!,
        items: _cart,
        totalBayar: total,
        bayar: bayar,
        kembalian: kembalian,
      );

      _showSuccessDialog(total, bayar, kembalian, legacyTx);
      
      setState(() {
        _cart.clear();
        _customerController.text = "Umum";
      });
      
      // Update local stock optimistically if possible, or just refresh from local
      // (Refresh from local is safer)
      context.read<ProductProvider>().loadProducts(); 

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showSuccessDialog(int total, int bayar, int kembalian, Transaksi transaction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.green, size: 50),
              ),
              const SizedBox(height: 20),
              const Text(
                "Pembayaran Berhasil!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 25),
              
              // Receipt Details
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow("Total Tagihan", total, isBold: true),
                    const Divider(height: 20),
                    _buildReceiptRow("Uang Diterima", bayar),
                    const SizedBox(height: 8),
                    _buildReceiptRow("Kembalian", kembalian, isHighlight: true),
                  ],
                ),
              ),
              
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                         bool connected = await _printerService.isConnected;
                         if (connected) {
                           await _printerService.printReceipt(
                             transaction,
                             shopName: _shopName,
                             shopLogo: _shopLogo,
                           );
                         } else {
                           if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(
                                 content: Text("Printer belum terhubung. Silakan atur di menu Printer."),
                                 backgroundColor: Colors.orange,
                               ),
                             );
                           }
                         }
                      }, 
                      icon: const Icon(Icons.print_rounded),
                      label: const Text("Cetak"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text("Baru"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, int amount, {bool isBold = false, bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label, 
          style: TextStyle(
            color: Colors.grey.shade600, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal
          )
        ),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: isBold || isHighlight ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: isHighlight ? (amount >= 0 ? Colors.green : Colors.red) : Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
// Product filtered inside Consumer below

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Transaksi", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Kasir Aktif", style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
          )
        ],
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.defaultGradient,
          ),
        ),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.defaultGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => context.read<ProductProvider>().searchProducts(val),
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
                            context.read<ProductProvider>().searchProducts('');
                            setState(() {});
                          },
                        )
                      : null,
                  ),
                ),
              ),

              // CATEGORIES
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  children: [
                    _buildCategoryPill('All', 'Semua'),
                    ...productProvider.categories.map((c) => _buildCategoryPill(c.id, c.nama)),
                  ],
                ),
              ),

              // GRID PRODUCTS
              Expanded(
                child: Consumer<ProductProvider>(
                  builder: (ctx, prodProv, _) {
                    final allItems = prodProv.products;
                    // Pre-filter category here if not using provider search for it
                    final filtered = allItems.where((p) => 
                      _selectedCategoryId == 'All' || p.kategoriId == _selectedCategoryId
                    ).toList();

                    if (prodProv.isLoading && allItems.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (filtered.isEmpty) {
                      return const Center(child: Text("Tidak ada produk"));
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 120),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : (MediaQuery.of(context).size.width < 360 ? 2 : 3),
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _buildProductCard(filtered[i]),
                    );
                  }
                ),
              ),
            ],
          ),
          
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

  Widget _buildProductCard(dynamic product) {
    return GestureDetector(
      onTap: () {
         // Convert Hive model to internal format for cart if needed
         final barang = Barang(
           id: product.id.toString(),
           nama: product.nama,
           kategoriId: product.kategoriId.toString(),
           harga: product.harga,
           hargaDasar: product.hargaDasar,
           stok: product.stok,
           minStok: product.minStok,
           barcode: product.barcode,
           image: product.image,
         );
         _addToCart(barang);
      },
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
                ),
                child: product.image != null && product.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: CachedNetworkImage(
                        imageUrl: '${AppConstants.imageBaseUrl}${product.image}',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor.withOpacity(0.3))),
                        errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                        memCacheHeight: 200, // Optimize memory for thumbnails
                      ),
                    )
                  : Center(child: Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey.shade400)),
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
        margin: const EdgeInsets.only(bottom: 30, left: 5, right: 5), 
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
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.defaultGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]
              ),
              child: ElevatedButton(
                onPressed: _showCheckoutDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                ),
                child: const Row(
                  children: [
                     Text("Bayar", style: TextStyle(fontWeight: FontWeight.bold)),
                     SizedBox(width: 5),
                     Icon(Icons.arrow_forward, size: 16)
                  ],
                ),
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

  Widget _buildCategoryPill(String id, String label) {
    bool isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
