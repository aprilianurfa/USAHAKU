import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/product_model.dart';
import '../../models/category_hive.dart';
import '../../models/product_hive.dart';
import '../../providers/product_provider.dart';
import '../../config/constants.dart';

class ProductFormPage extends StatefulWidget {
  final Barang? barang;
  const ProductFormPage({super.key, this.barang});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController namaController;
  late TextEditingController hargaController;
  late TextEditingController hargaDasarController;
  late TextEditingController stokController;
  late TextEditingController minStokController;
  late TextEditingController barcodeController;
  
  Uint8List? _imageBytes;
  String? _imageFilename;
  String? selectedKategoriId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final b = widget.barang;
    namaController = TextEditingController(text: b?.nama);
    hargaController = TextEditingController(text: b?.harga.toString());
    hargaDasarController = TextEditingController(text: b?.hargaDasar.toString());
    stokController = TextEditingController(text: b?.stok.toString());
    minStokController = TextEditingController(text: b?.minStok.toString());
    barcodeController = TextEditingController(text: b?.barcode);
    
    selectedKategoriId = b?.kategoriId;
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageFilename = pickedFile.name;
      });
    }
  }

  Future<void> _showPreviewDialog() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedKategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kategori')));
      return;
    }

    final categories = context.read<ProductProvider>().categories;
    final categoryName = categories.firstWhere((c) => c.id == selectedKategoriId, orElse: () => CategoryHive(id: '', nama: 'Unknown')).nama;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simpan Barang?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             _previewItem('Nama', namaController.text),
             _previewItem('Kategori', categoryName),
             _previewItem('Harga', 'Rp ${hargaController.text}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveProduct();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _previewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    setState(() => _isLoading = true);
    try {
      final isEdit = widget.barang != null;
      final newId = isEdit ? widget.barang!.id : 'LOC-P-${DateTime.now().millisecondsSinceEpoch}';
      
      final productHive = ProductHive(
        id: newId,
        nama: namaController.text,
        kategoriId: selectedKategoriId!,
        harga: int.parse(hargaController.text),
        hargaDasar: int.tryParse(hargaDasarController.text) ?? 0,
        stok: int.tryParse(stokController.text) ?? 0,
        minStok: int.tryParse(minStokController.text) ?? 5,
        barcode: barcodeController.text,
        image: widget.barang?.image,
        isDeleted: false,
      );

      await context.read<ProductProvider>().saveLocalProduct(productHive);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tersimpan secara lokal & sedang sinkronisasi')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Barang?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      await context.read<ProductProvider>().deleteLocalProduct(widget.barang!.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barang dihapus')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductProvider>().categories;
    final isEdit = widget.barang != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Barang' : 'Tambah Barang'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(controller: namaController, label: 'Nama Barang', icon: Icons.shopping_bag),
                  const SizedBox(height: 15),
                   _buildTextField(controller: hargaController, label: 'Harga Jual', icon: Icons.money, keyboardType: TextInputType.number),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedKategoriId,
                    decoration: InputDecoration(
                       labelText: 'Kategori',
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nama))).toList(),
                    onChanged: (v) => setState(() => selectedKategoriId = v),
                    validator: (v) => v == null ? 'Wajib dipilih' : null,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(controller: stokController, label: 'Stok', icon: Icons.inventory, keyboardType: TextInputType.number),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _showPreviewDialog,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                      child: const Text('SIMPAN'),
                    ),
                  ),
                  if (isEdit) ...[
                    const SizedBox(height: 10),
                    TextButton(onPressed: _deleteProduct, child: const Text('Hapus Barang', style: TextStyle(color: Colors.red))),
                  ]
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
    );
  }
}