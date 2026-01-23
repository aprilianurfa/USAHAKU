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
      
      // Check for duplicate name
      final provider = context.read<ProductProvider>();
      if (provider.isDuplicateName(namaController.text, excludeId: isEdit ? widget.barang!.id : null)) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Nama barang sudah digunakan, mohon gunakan nama lain.'),
               backgroundColor: Colors.red,
             )
           );
        }
        return;
      }
      
      final productHive = ProductHive(
        id: newId,
        nama: namaController.text,
        kategoriId: selectedKategoriId!,
        harga: int.tryParse(hargaController.text) ?? 0,
        hargaDasar: int.tryParse(hargaDasarController.text) ?? 0,
        stok: int.tryParse(stokController.text) ?? 0,
        minStok: int.tryParse(minStokController.text) ?? 5,
        barcode: barcodeController.text,
        image: widget.barang?.image,
        isDeleted: false,
      );

      await context.read<ProductProvider>().saveLocalProduct(
        productHive, 
        imageBytes: _imageBytes, 
        imageFilename: _imageFilename
      );
      
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
                   // Image Picker
                   GestureDetector(
                     onTap: _pickImage,
                     child: Container(
                       height: 150,
                       width: 150,
                       decoration: BoxDecoration(
                         color: Colors.grey[200],
                         borderRadius: BorderRadius.circular(15),
                         border: Border.all(color: Colors.grey[400]!),
                         image: _imageBytes != null 
                           ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                           : (widget.barang?.image != null 
                               ? DecorationImage(
                                   image: NetworkImage('${AppConstants.imageBaseUrl}${widget.barang!.image}'), 
                                   fit: BoxFit.cover
                                 )
                               : null
                             ),
                       ),
                       child: _imageBytes == null && widget.barang?.image == null
                           ? const Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                 Text('Tambah Foto', style: TextStyle(color: Colors.grey)),
                               ],
                             )
                           : null,
                     ),
                   ),
                   const SizedBox(height: 20),

                  _buildTextField(controller: namaController, label: 'Nama Barang', icon: Icons.shopping_bag),
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(child: _buildTextField(controller: hargaController, label: 'Harga Jual', icon: Icons.monetization_on, keyboardType: TextInputType.number)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildTextField(controller: hargaDasarController, label: 'Harga Modal', icon: Icons.price_change, keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    // Safety check: ensure the value exists in the list
                    value: (categories.any((c) => c.id == selectedKategoriId)) ? selectedKategoriId : null,
                    decoration: InputDecoration(
                       labelText: 'Kategori',
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                       prefixIcon: const Icon(Icons.category)
                    ),
                    items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nama))).toList(),
                    onChanged: (v) => setState(() => selectedKategoriId = v),
                    validator: (v) => v == null ? 'Wajib dipilih' : null,
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(child: _buildTextField(controller: stokController, label: 'Stok Saat Ini', icon: Icons.inventory, keyboardType: TextInputType.number)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildTextField(controller: minStokController, label: 'Min. Stok (Alert)', icon: Icons.warning_amber, keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 15),

                  _buildTextField(
                    controller: barcodeController, 
                    label: 'Barcode / Kode Barang (Opsional)', 
                    icon: Icons.qr_code,
                    isRequired: false
                  ),
                  
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _showPreviewDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor, 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: const Text('SIMPAN BARANG', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (isEdit) ...[
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _deleteProduct, 
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: const Text('HAPUS BARANG')
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    TextInputType? keyboardType,
    bool isRequired = true
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => isRequired && (v == null || v.isEmpty) ? 'Wajib diisi' : null,
    );
  }
}