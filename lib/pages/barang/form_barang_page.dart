import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/barang.dart';
import '../../models/kategori.dart';
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
  
  File? _imageFile;

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
      setState(() {
        _imageFile = File(pickedFile.path);
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

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedKategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }

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
        image: widget.barang?.image, // Keep old image path if not updated
      );

      if (isEdit) {
        await _productService.updateProduct(productData, imagePath: _imageFile?.path);
      } else {
        await _productService.addProduct(productData, imagePath: _imageFile?.path);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Barang berhasil diperbarui' : 'Barang berhasil disimpan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ${widget.barang != null ? 'memperbarui' : 'menyimpan'} barang: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                                image: _imageFile != null 
                                  ? DecorationImage(
                                      image: FileImage(_imageFile!),
                                      fit: BoxFit.cover,
                                    ) 
                                  : (isEdit && widget.barang?.image != null) 
                                      ? DecorationImage(
                                          image: NetworkImage('${AppConstants.imageBaseUrl}${widget.barang!.image}'), // Show existing
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                              ),
                              child: (_imageFile == null && (!isEdit || widget.barang?.image == null))
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
                    const SizedBox(height: 32),
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
                        onPressed: _saveProduct,
                        child: const Text(
                          'SIMPAN DATA BARANG',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
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