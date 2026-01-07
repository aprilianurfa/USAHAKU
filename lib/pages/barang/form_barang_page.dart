import 'package:flutter/material.dart';
import '../../core/dummy_data.dart';

class FormBarangPage extends StatefulWidget {
  // ❌ HAPUS const
  FormBarangPage({super.key});

  @override
  State<FormBarangPage> createState() => _FormBarangPageState();
}

class _FormBarangPageState extends State<FormBarangPage> {
  final _formKey = GlobalKey<FormState>();

  final namaController = TextEditingController();
  final hargaController = TextEditingController();
  final stokController = TextEditingController();
  final barcodeController = TextEditingController();

  String selectedKategori = DummyData.kategori.first['nama'] as String;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Barang')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama Barang'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              // ✅ FIX GENERIC DROPDOWN
              DropdownButtonFormField<String>(
                value: selectedKategori,
                items: DummyData.kategori
                    .map<DropdownMenuItem<String>>(
                      (k) => DropdownMenuItem<String>(
                        value: k['nama'] as String,
                        child: Text(k['nama']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedKategori = v!),
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: hargaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: stokController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stok'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: barcodeController,
                decoration: const InputDecoration(labelText: 'Barcode'),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    DummyData.barang.add({
                      'id': DateTime.now().toString(),
                      'nama': namaController.text,
                      'kategori': selectedKategori,
                      'harga': int.parse(hargaController.text),
                      'stok': int.tryParse(stokController.text) ?? 0,
                      'barcode': barcodeController.text,
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Simpan Barang'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
