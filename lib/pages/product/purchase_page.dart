import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/product_model.dart';
import '../../models/purchase_item_model.dart';
import '../../services/product_service.dart';
import 'package:usahaku_main/core/app_shell.dart';
import 'package:usahaku_main/core/view_metrics.dart';
import '../../providers/purchase_provider.dart';
import '../../models/purchase_hive.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final ProductService _productService = ProductService();
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

  @override
  void dispose() {
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getProducts();
      if (mounted) setState(() => _availableProducts = products);
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  int get _totalBiaya => _cart.fold(0, (sum, item) => sum + (item.jumlah * item.hargaBeli));

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih barang terlebih dahulu')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembelian berhasil disimpan')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: false, // MANDATORY
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => AppShell.of(context).toggleSidebar(),
        ),
        title: const Text("Input Pembelian Barang", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.defaultGradient)),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _PurchaseSummaryHeader(itemCount: _cart.length, total: _totalBiaya),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 10),
                _PurchaseFormSection(supplierCtrl: _supplierController, notesCtrl: _notesController),
                const SizedBox(height: 20),
                _CartHeader(onAddPressed: _showProductPicker),
                const SizedBox(height: 10),
                if (_cart.isEmpty) const _EmptyCartPlaceholder()
                else RepaintBoundary(
                  child: Column(
                    children: _cart.asMap().entries.map((e) => _PurchaseItemRow(
                      key: ValueKey(e.value.productId),
                      item: e.value,
                      onDelete: () => setState(() => _cart.removeAt(e.key)),
                      onUpdate: (newItem) => setState(() => _cart[e.key] = newItem),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _SavePurchaseFAB(isLoading: _isLoading, onSave: _savePurchase),
    );
  }

  void _showProductPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ProductPickerSheet(
        products: _availableProducts,
        onSelected: (p) => setState(() => _addProductToCart(p)),
      ),
    );
  }
}

class _PurchaseSummaryHeader extends StatelessWidget {
  final int itemCount;
  final int total;
  const _PurchaseSummaryHeader({required this.itemCount, required this.total});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity, height: 50, 
          decoration: const BoxDecoration(
            gradient: AppTheme.defaultGradient,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Pembelian", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.receipt_long_rounded, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 5),
                      Text("$itemCount Item", style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                    ])
                  ],
                ),
                Text(fmt.format(total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PurchaseFormSection extends StatelessWidget {
  final TextEditingController supplierCtrl;
  final TextEditingController notesCtrl;
  const _PurchaseFormSection({required this.supplierCtrl, required this.notesCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          TextField(
            controller: supplierCtrl,
            decoration: InputDecoration(labelText: "Nama Supplier", prefixIcon: const Icon(Icons.business_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: notesCtrl,
            decoration: InputDecoration(labelText: "Keterangan", prefixIcon: const Icon(Icons.note_alt_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  final VoidCallback onAddPressed;
  const _CartHeader({required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Daftar Barang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton.icon(
          onPressed: onAddPressed,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text("Pilih Barang"),
          style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
        ),
      ],
    );
  }
}

class _EmptyCartPlaceholder extends StatelessWidget {
  const _EmptyCartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        Icon(Icons.shopping_basket_outlined, size: 50, color: Colors.grey.shade400),
        const SizedBox(height: 10),
        Text("Belum ada barang dipilih", style: TextStyle(color: Colors.grey.shade600)),
      ]),
    );
  }
}

class _PurchaseItemRow extends StatefulWidget {
  final PembelianItem item;
  final VoidCallback onDelete;
  final ValueChanged<PembelianItem> onUpdate;
  const _PurchaseItemRow({super.key, required this.item, required this.onDelete, required this.onUpdate});

  @override
  State<_PurchaseItemRow> createState() => _PurchaseItemRowState();
}

class _PurchaseItemRowState extends State<_PurchaseItemRow> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: widget.item.jumlah.toString());
    _priceCtrl = TextEditingController(text: widget.item.hargaBeli.toString());
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Text(widget.item.productName ?? "Produk", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _ItemInputField(label: "Qty", controller: _qtyCtrl, onSubmitted: (v) => _update())),
                  const SizedBox(width: 15),
                  Expanded(flex: 2, child: _ItemInputField(label: "Harga Beli", controller: _priceCtrl, prefix: "Rp ", onSubmitted: (v) => _update())),
                ]),
              ],
            ),
          ),
          IconButton(onPressed: widget.onDelete, icon: const Icon(Icons.delete_outline, color: Colors.red)),
        ],
      ),
    );
  }

  void _update() {
    widget.onUpdate(PembelianItem(
      productId: widget.item.productId,
      productName: widget.item.productName,
      jumlah: int.tryParse(_qtyCtrl.text) ?? widget.item.jumlah,
      hargaBeli: int.tryParse(_priceCtrl.text) ?? widget.item.hargaBeli,
    ));
  }
}

class _ItemInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? prefix;
  final ValueChanged<String> onSubmitted;
  const _ItemInputField({required this.label, required this.controller, this.prefix, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          height: 40, padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(border: InputBorder.none, prefixText: prefix, isDense: true),
          ),
        ),
      ],
    );
  }
}

class _SavePurchaseFAB extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSave;
  const _SavePurchaseFAB({required this.isLoading, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity, height: 55,
        child: FloatingActionButton.extended(
          backgroundColor: AppTheme.primaryColor, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          label: isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("SIMPAN PEMBELIAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          onPressed: isLoading ? null : onSave,
        ),
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  final List<Barang> products;
  final ValueChanged<Barang> onSelected;
  const _ProductPickerSheet({required this.products, required this.onSelected});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _search = "";
  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((p) => p.nama.toLowerCase().contains(_search.toLowerCase())).toList();
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        const Text("Pilih Barang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(hintText: "Cari produk...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: filtered.isEmpty ? const Center(child: Text("Produk tidak ditemukan"))
          : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, i) => ListTile(
                leading: const CircleAvatar(backgroundColor: AppTheme.primaryColor, child: Icon(Icons.inventory_2_outlined, color: Colors.white, size: 20)),
                title: Text(filtered[i].nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Stok: ${filtered[i].stok}"),
                onTap: () {
                  widget.onSelected(filtered[i]);
                  Navigator.pop(context);
                },
              ),
            ),
        ),
      ]),
    );
  }
}
