import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../services/product_service.dart';
import '../../config/constants.dart';

class FormBarangPage extends StatefulWidget {
  final Barang? barang;
  const FormBarangPage({super.key, this.barang});

  @override
  State<FormBarangPage> createState() => _FormBarangPageState();
}

class _FormBarangPageState extends State<FormBarangPage> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController namaController;
  late TextEditingController hargaController;
  late TextEditingController hargaDasarController;
  late TextEditingController stokController;
  late TextEditingController minStokController;
  late TextEditingController barcodeController;
  
  Uint8List? _imageBytes;
  String? _imageFilename;

  List<Kategori> _categories = [];
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
    
    // Defer setting selectedKategoriId until categories are loaded to prevent assertion errors
    _loadCategories();
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

  Future<void> _loadCategories() async {
    try {
      final categories = await _productService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          
          if (widget.barang != null) {
            // Check if product's category exists in the fetched list
            final exists = _categories.any((c) => c.id == widget.barang!.kategoriId);
            if (exists) {
              selectedKategoriId = widget.barang!.kategoriId;
            } else {
              // If not found in list (e.g. deleted category), default to null.
              // This prevents duplicate value errors or assertion failures.
              selectedKategoriId = null;
            }
          } else {
            // New Product Mode: Default to first category if available
             if (_categories.isNotEmpty) {
               selectedKategoriId = _categories.first.id;
             }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat kategori: $e')),
        );
      }
    }
  }

  Future<void> _showPreviewDialog() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedKategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }

    final categoryName = _categories.firstWhere((c) => c.id == selectedKategoriId).nama;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Review Simpan Barang'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200],
                    image: _imageBytes != null
                        ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                        : (widget.barang?.image != null
                            ? DecorationImage(
                                image: NetworkImage('${AppConstants.imageBaseUrl}${widget.barang!.image}'),
                                fit: BoxFit.cover)
                            : null),
                  ),
                  child: (_imageBytes == null && widget.barang?.image == null)
                      ? const Icon(Icons.inventory_2, size: 50, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              _previewItem('Nama', namaController.text),
              _previewItem('Kategori', categoryName),
              _previewItem('Harga Jual', 'Rp ${hargaController.text}'),
              _previewItem('Stok', stokController.text),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveProduct();
            },
            child: const Text('Konfirmasi & Simpan'),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    setState(() => _isLoading = true);

    try {
      final isEdit = widget.barang != null;
      final productData = Barang(
        id: isEdit ? widget.barang!.id : '', 
        nama: namaController.text,
        kategoriId: selectedKategoriId!,
        harga: int.parse(hargaController.text),
        hargaDasar: int.tryParse(hargaDasarController.text) ?? 0,
        stok: int.tryParse(stokController.text) ?? 0,
        minStok: int.tryParse(minStokController.text) ?? 5,
        barcode: barcodeController.text,
        image: widget.barang?.image, 
      );

      bool success;
      if (isEdit) {
        success = await _productService.updateProduct(
          productData, 
          imageBytes: _imageBytes, 
          imageFilename: _imageFilename
        );
      } else {
        final result = await _productService.addProduct(
          productData, 
          imageBytes: _imageBytes, 
          imageFilename: _imageFilename
        );
        success = result != null;
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isEdit ? 'Barang berhasil diperbarui' : 'Barang berhasil disimpan')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan barang'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Barang?'),
        content: const Text('Produk akan dinonaktifkan dari daftar jual untuk menjaga integritas laporan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      )
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _productService.deleteProduct(widget.barang!.id);
        if (mounted) {
          Navigator.pop(context, true); // Pop form and indicate deletion
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barang berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus barang: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primaryColor;
    final isEdit = widget.barang != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(isEdit ? 'Edit Barang' : 'Tambah Barang Baru'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Kartu Form
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[400]!),
                                image: _imageBytes != null 
                                  ? DecorationImage(
                                      image: MemoryImage(_imageBytes!),
                                      fit: BoxFit.cover,
                                    ) 
                                  : (isEdit && widget.barang?.image != null) 
                                      ? DecorationImage(
                                          image: NetworkImage('${AppConstants.imageBaseUrl}${widget.barang!.image}'), // Show existing
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                              ),
                              child: (_imageBytes == null && (!isEdit || widget.barang?.image == null))
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey[600]),
                                      const SizedBox(height: 8),
                                      Text('Upload Foto Barang', style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  )
                                : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: namaController,
                            label: 'Nama Barang',
                            icon: Icons.shopping_bag_outlined,
                            validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: hargaDasarController, 
                                  label: 'Harga Dasar',
                                  icon: Icons.money_off,
                                  keyboardType: TextInputType.number,
                                  prefixText: 'Rp ',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: hargaController,
                                  label: 'Harga Jual',
                                  icon: Icons.payments_outlined,
                                  keyboardType: TextInputType.number,
                                  prefixText: 'Rp ',
                                  validator: (v) => v == null || v.isEmpty ? 'Harga wajib diisi' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _categories.isEmpty
                              ? const Center(child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ))
                              : DropdownButtonFormField<String>(
                                  value: selectedKategoriId,
                                  decoration: InputDecoration(
                                    labelText: 'Kategori',
                                    prefixIcon: const Icon(Icons.category_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: _categories.map((k) => DropdownMenuItem(value: k.id, child: Text(k.nama))).toList(),
                                  onChanged: (v) => setState(() => selectedKategoriId = v),
                                  validator: (v) => v == null ? 'Wajib dipilih' : null,
                                ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: stokController,
                                  label: 'Stok Awal',
                                  icon: Icons.inventory_2_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: minStokController,
                                  label: 'Min. Stok',
                                  icon: Icons.warning_amber_rounded,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: barcodeController,
                            label: 'Kode/Barcode',
                            icon: Icons.qr_code_scanner,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _showPreviewDialog,
                        child: Text(
                          isEdit ? 'PERBARUI DATA' : 'SIMPAN DATA BARANG',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    
                    if (isEdit) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _deleteProduct,
                          child: const Text(
                            'HAPUS BARANG',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // Helper widget untuk input yang konsisten
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        prefixText: prefixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}