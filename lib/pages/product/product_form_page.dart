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
import '../../core/widgets/keyboard_spacer.dart';

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
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
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
      if (!mounted) return;
      final provider = context.read<ProductProvider>();
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      
      setState(() => _isLoading = true);
      await provider.deleteLocalProduct(widget.barang!.id);
      
      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(const SnackBar(content: Text('Barang dihapus')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.barang != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Barang' : 'Tambah Barang'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // Advanced Optimization: Disable default resize logic to prevent full-body rebuilds
      resizeToAvoidBottomInset: false,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(), // Close keyboard on outside tap
            // Performance Optimization: Isolate the build context of the form to avoid full page repaints during keyboard animations
            child: RepaintBoundary(
              child: _ProductFormContent(
                formKey: _formKey,
                imageBytes: _imageBytes,
                barang: widget.barang,
                namaController: namaController,
                hargaController: hargaController,
                hargaDasarController: hargaDasarController,
                stokController: stokController,
                minStokController: minStokController,
                barcodeController: barcodeController,
                selectedKategoriId: selectedKategoriId,
                onPickImage: _pickImage,
                onKategoriChanged: (val) => setState(() => selectedKategoriId = val),
                onSave: _showPreviewDialog,
                onDelete: isEdit ? _deleteProduct : null,
              ),
            ),
          ),
    );
  }
}

class _ProductFormContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final Uint8List? imageBytes;
  final Barang? barang;
  final TextEditingController namaController;
  final TextEditingController hargaController;
  final TextEditingController hargaDasarController;
  final TextEditingController stokController;
  final TextEditingController minStokController;
  final TextEditingController barcodeController;
  final String? selectedKategoriId;
  final VoidCallback onPickImage;
  final ValueChanged<String?> onKategoriChanged;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  const _ProductFormContent({
    required this.formKey,
    required this.imageBytes,
    required this.barang,
    required this.namaController,
    required this.hargaController,
    required this.hargaDasarController,
    required this.stokController,
    required this.minStokController,
    required this.barcodeController,
    required this.selectedKategoriId,
    required this.onPickImage,
    required this.onKategoriChanged,
    required this.onSave,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(), // Better for forms
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ImagePickerSection(
              imageProvider: _getImageProvider(),
              showPlaceholder: _showPlaceholder(),
              onPickImage: onPickImage,
            ),
            const SizedBox(height: 25),
            _BasicInfoSection(namaController: namaController),
            const SizedBox(height: 15),
            _PricingSection(hargaController: hargaController, hargaDasarController: hargaDasarController),
            const SizedBox(height: 15),
            _CategorySection(selectedKategoriId: selectedKategoriId, onKategoriChanged: onKategoriChanged),
            const SizedBox(height: 15),
            _InventorySection(stokController: stokController, minStokController: minStokController),
            const SizedBox(height: 15),
            _CustomTextField(
              controller: barcodeController, 
              label: 'Barcode (Opsional)', 
              icon: Icons.qr_code,
              isRequired: false
            ),
            const SizedBox(height: 30),
            _ActionButtons(onSave: onSave, onDelete: onDelete),
            // Performance Optimization: Manual keyboard padding to avoid full rebuilds
            const KeyboardSpacer(),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getImageProvider() {
    if (imageBytes != null) return MemoryImage(imageBytes!);
    if (barang?.image != null && barang!.image!.isNotEmpty) {
      return NetworkImage('${AppConstants.imageBaseUrl}${barang!.image}');
    }
    return null;
  }

  bool _showPlaceholder() {
    return imageBytes == null && (barang?.image == null || barang!.image!.isEmpty);
  }
}

class _ImagePickerSection extends StatelessWidget {
  final ImageProvider? imageProvider;
  final bool showPlaceholder;
  final VoidCallback onPickImage;

  const _ImagePickerSection({
    required this.imageProvider,
    required this.showPlaceholder,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPickImage,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[400]!),
              image: imageProvider != null 
                ? DecorationImage(
                    image: imageProvider!, 
                    fit: BoxFit.cover
                  )
                : null,
            ),
            child: showPlaceholder 
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                      SizedBox(height: 5),
                      Text('Tambah Foto', style: TextStyle(color: Colors.grey)),
                    ],
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _BasicInfoSection extends StatelessWidget {
  final TextEditingController namaController;
  const _BasicInfoSection({required this.namaController});

  @override
  Widget build(BuildContext context) {
    return _CustomTextField(
      controller: namaController, 
      label: 'Nama Barang', 
      icon: Icons.shopping_bag
    );
  }
}

class _PricingSection extends StatelessWidget {
  final TextEditingController hargaController;
  final TextEditingController hargaDasarController;
  const _PricingSection({required this.hargaController, required this.hargaDasarController});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _CustomTextField(controller: hargaController, label: 'Harga Jual', icon: Icons.monetization_on, keyboardType: TextInputType.number)),
        const SizedBox(width: 15),
        Expanded(child: _CustomTextField(controller: hargaDasarController, label: 'Harga Modal', icon: Icons.price_change, keyboardType: TextInputType.number)),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String? selectedKategoriId;
  final ValueChanged<String?> onKategoriChanged;
  const _CategorySection({required this.selectedKategoriId, required this.onKategoriChanged});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductProvider>().categories;
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: (categories.any((c) => c.id == selectedKategoriId)) ? selectedKategoriId : null,
      decoration: InputDecoration(
         labelText: 'Kategori',
         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
         prefixIcon: const Icon(Icons.category),
         contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
      items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nama, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onKategoriChanged,
      validator: (v) => v == null ? 'Wajib dipilih' : null,
    );
  }
}

class _InventorySection extends StatelessWidget {
  final TextEditingController stokController;
  final TextEditingController minStokController;
  const _InventorySection({required this.stokController, required this.minStokController});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _CustomTextField(controller: stokController, label: 'Stok Saat Ini', icon: Icons.inventory, keyboardType: TextInputType.number)),
        const SizedBox(width: 15),
        Expanded(child: _CustomTextField(controller: minStokController, label: 'Min. Stok', icon: Icons.warning_amber, keyboardType: TextInputType.number)),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback? onDelete;
  const _ActionButtons({required this.onSave, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 2,
            ),
            child: const Text('SIMPAN BARANG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        if (onDelete != null) ...[
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton(
              onPressed: onDelete, 
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              child: const Text('HAPUS BARANG')
            ),
          ),
        ]
      ],
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool isRequired;

  const _CustomTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    // Performance: Wrap in RepaintBoundary to isolate focus animations
    return RepaintBoundary(
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (v) => isRequired && (v == null || v.isEmpty) ? 'Wajib diisi' : null,
      ),
    );
  }
}
