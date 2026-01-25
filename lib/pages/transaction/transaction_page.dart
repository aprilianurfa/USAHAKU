import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme.dart';
import '../../config/constants.dart';
import '../../models/transaction_model.dart';
import '../../models/transaction_item_model.dart';
import '../../models/transaction_hive.dart';
import '../../models/product_hive.dart';
import '../../services/transaction_service.dart';
import '../../services/printer_service.dart';
import '../../providers/product_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/input_draft_provider.dart';
import '../../core/view_metrics.dart';
import '../../core/app_shell.dart';
import 'checkout_sheet.dart';
import 'widgets/transaction_search_bar.dart';
import 'widgets/category_selector.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final TransactionService _transactionService = TransactionService();
  final PrinterService _printerService = PrinterService();
  List<String> _customerNames = [];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductProvider>().loadProducts();
        _fetchSecondaryData();
      }
    });
  }

  Future<void> _fetchSecondaryData() async {
    try {
      final customers = await _transactionService.getCustomerNames();
      if (mounted) {
        setState(() {
          _customerNames = customers;
        });
      }
    } catch (e) {
      debugPrint("Error fetching secondary data: $e");
    }
  }
  void _showCheckoutDialog() {
    final txProv = context.read<TransactionProvider>();
    if (txProv.cart.isEmpty) return;

    final draftProv = context.read<InputDraftProvider>();
    final prodProv = context.read<ProductProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: txProv),
          ChangeNotifierProvider.value(value: draftProv),
          ChangeNotifierProvider.value(value: prodProv),
        ],
        child: CheckoutSheet(
          total: txProv.totalPrice,
          customerNames: _customerNames,
          initialCustomer: draftProv.customerName,
          onProcess: (total, bayar, kembalian, customerName) {
             draftProv.setCustomerName(customerName);
             _processTransaction(total, bayar, kembalian);
          },
        ),
      ),
    );
  }

  Future<void> _processTransaction(int total, int bayar, int kembalian) async {
    Navigator.pop(context);
    final txProv = context.read<TransactionProvider>();
    final draftProv = context.read<InputDraftProvider>();
    final prodProv = context.read<ProductProvider>();

    String localId = "LOC-${DateTime.now().millisecondsSinceEpoch}";
    
    final transactionHive = TransactionHive(
      id: localId,
      tanggal: DateTime.now(),
      namaPelanggan: draftProv.customerName,
      totalBayar: total,
      bayar: bayar,
      kembalian: kembalian,
      items: txProv.cart.map((item) => TransactionItemHive(
        productId: item.barangId,
        namaBarang: item.namaBarang,
        harga: item.harga,
        qty: item.qty,
        subtotal: item.subtotal,
      )).toList(),
      isSynced: false,
    );

    try {
      await prodProv.saveLocalTransaction(transactionHive);

      if (!mounted) return;

      prodProv.addToSyncQueue(
        action: 'CREATE',
        entity: 'TRANSACTION',
        data: {
          'id': transactionHive.id,
          'tanggal': transactionHive.tanggal.toIso8601String(),
          'nama_pelanggan': transactionHive.namaPelanggan,
          'total_bayar': transactionHive.totalBayar,
          'bayar': transactionHive.bayar,
          'kembalian': transactionHive.kembalian,
          'items': txProv.cart.map((item) => item.toMap()).toList(),
        },
      );

      final legacyTx = Transaksi(
        id: localId,
        tanggal: transactionHive.tanggal,
        pelangganId: 'GUEST',
        namaPelanggan: transactionHive.namaPelanggan!,
        items: List.from(txProv.cart),
        totalBayar: total,
        bayar: bayar,
        kembalian: kembalian,
      );

      _showSuccessDialog(total, bayar, kembalian, legacyTx);
      
      txProv.clearCart();
      draftProv.resetDraft();

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showSuccessDialog(int total, int bayar, int kembalian, Transaksi transaction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SuccessDialog(total: total, bayar: bayar, kembalian: kembalian, transaction: transaction, printerService: _printerService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        resizeToAvoidBottomInset: false, 
        appBar: const _TransactionAppBar(),
        body: const _MainContent(),
        bottomNavigationBar: const _BottomCartSection(),
      ),
    );
  }
}

class _TransactionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _TransactionAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => AppShell.of(context).toggleSidebar(),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Transaksi", style: TextStyle(fontWeight: FontWeight.bold)),
          Text("Kasir Aktif", style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
        ],
      ),
      actions: [
        Selector<ProductProvider, bool>(
          selector: (_, p) => p.isSyncing,
          builder: (ctx, isSyncing, _) {
            if (isSyncing) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: const SizedBox(
                  width: 20, height: 20, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2, strokeCap: StrokeCap.round)
                ),
              );
            }
            return IconButton(
              icon: const Icon(Icons.sync_rounded, color: Colors.white),
              onPressed: () => context.read<ProductProvider>().syncData(),
            );
          }
        ),
        const _AppBarActionIcon(),
      ],
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.defaultGradient)),
      elevation: 0,
      foregroundColor: Colors.white,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppBarActionIcon extends StatelessWidget {
  const _AppBarActionIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
      child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
    );
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        RepaintBoundary(
          child: _SearchBarLayer(),
        ),
        _CategoryLayer(),
        Expanded(
          child: _ProductGridSection(),
        ),
      ],
    );
  }
}

class _SearchBarLayer extends StatelessWidget {
  const _SearchBarLayer();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.defaultGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      child: const TransactionSearchBar(),
    );
  }
}

class _CategoryLayer extends StatelessWidget {
  const _CategoryLayer();
  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(child: CategorySelector());
  }
}



class _ProductGridSection extends StatelessWidget {
  const _ProductGridSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount = width > 600 ? 5 : (width < 360 ? 2 : 3);

        return Selector<ProductProvider, int>(
          selector: (_, p) => p.dataVersion,
          builder: (context, _, __) {
            // Re-read inside builder is safe and faster than large list equality checks in Selector
            final filtered = context.read<ProductProvider>().filteredProducts;
            if (filtered.isEmpty) return const Center(child: Text("Produk tidak ditemukan", style: TextStyle(color: Colors.grey)));

            return RepaintBoundary(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(15, 10, 15, 120),
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => _ProductCard(product: filtered[i]),
              ),
            );
          },
        );
      }
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductHive product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            context.read<TransactionProvider>().addToCart(product.toBarang());
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
                  child: product.image != null && product.image!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: '${AppConstants.imageBaseUrl}${product.image}',
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor.withValues(alpha: 0.3))),
                        errorWidget: (ctx, url, error) => const Icon(Icons.error_outline),
                        memCacheHeight: 200,
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
                    Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(product.harga), 
                         style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text("Stok: ${product.stok}", style: TextStyle(fontSize: 10, color: product.stok < 5 ? Colors.red : Colors.grey)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomCartSection extends StatelessWidget {
  const _BottomCartSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, txProv, _) {
        if (txProv.cart.isEmpty) return const SizedBox.shrink();
        
        // Use a Wrapper for padding if needed, but bottomNavigationBar
        // is safer for high-performance keyboard handling.
        return const _CartSummaryBar();
      }
    );
  }
}

class _CartSummaryBar extends StatelessWidget {
  const _CartSummaryBar();

  @override
  Widget build(BuildContext context) {
    final txProv = context.watch<TransactionProvider>();
    
    return Container(
      // Margin adjusted for bottomNavigationBar placement
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 15), 
      decoration: BoxDecoration(
        color: const Color(0xFF1E2633),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))]
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: () => _showCartDetail(context),
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                  child: Text("${txProv.totalItems}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Total Tagihan", style: TextStyle(color: Colors.white60, fontSize: 10)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(txProv.totalPrice), 
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const _PayButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCartDetail(BuildContext context) {
    final txProv = context.read<TransactionProvider>();
    final prodProv = context.read<ProductProvider>();

    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: txProv),
          ChangeNotifierProvider.value(value: prodProv),
        ],
        child: const _CartDetailSheet(),
      ),
    );
  }
}

class _PayButton extends StatelessWidget {
  const _PayButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.defaultGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 5)]
      ),
      child: ElevatedButton(
        onPressed: () {
          final state = context.findAncestorStateOfType<_TransactionPageState>();
          state?._showCheckoutDialog();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
        ),
        child: const Row(
          children: [
              Text("Bayar", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 5),
              Icon(Icons.arrow_forward, size: 16),
          ],
        ),
      ),
    );
  }
}



class _CartDetailSheet extends StatelessWidget {
  const _CartDetailSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: getViewportScreenHeight(context) * 0.6,
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
                  context.read<TransactionProvider>().clearCart();
                  Navigator.pop(context);
                }, 
                child: const Text("Hapus Semua", style: TextStyle(color: Colors.red))
              )
            ],
          ),
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (ctx, txProv, _) {
                return ListView.separated(
                  itemCount: txProv.cart.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final item = txProv.cart[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.namaBarang, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.harga)),
                      trailing: _QtySelector(index: i, item: item),
                    );
                  },
                );
              }
            ),
          )
        ],
      ),
    );
  }
}

class _QtySelector extends StatelessWidget {
  final int index;
  final TransaksiItem item;
  const _QtySelector({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
          onPressed: () => context.read<TransactionProvider>().updateQty(index, -1, 9999), 
        ),
        Text("${item.qty}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
          onPressed: () {
             context.read<TransactionProvider>().updateQty(index, 1, 9999);
          },
        ),
      ],
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final int total;
  final int bayar;
  final int kembalian;
  final Transaksi transaction;
  final PrinterService printerService;

  const _SuccessDialog({required this.total, required this.bayar, required this.kembalian, required this.transaction, required this.printerService});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.green, size: 50)),
            const SizedBox(height: 20),
            const Text("Pembayaran Berhasil!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(height: 8),
            Text(DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 25),
            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text("Total Tagihan", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text(fmt.format(total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                  const Divider(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text("Uang Diterima", style: TextStyle(color: Colors.grey)),
                    Text(fmt.format(bayar), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text("Kembalian", style: TextStyle(color: Colors.grey)),
                    Text(fmt.format(kembalian), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kembalian >= 0 ? Colors.green : Colors.red)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => printerService.printReceipt(transaction),
                    icon: const Icon(Icons.print_rounded), label: const Text("Cetak"),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18), label: const Text("Baru"),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
