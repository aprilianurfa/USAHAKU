import 'package:flutter/material.dart';
import '../../core/dummy_data.dart';

class PembelianPage extends StatefulWidget {
  const PembelianPage({super.key});

  @override
  State<PembelianPage> createState() => _PembelianPageState();
}

class _PembelianPageState extends State<PembelianPage> {
  final supplierController = TextEditingController();
  final totalController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembelian Barang')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: supplierController,
              decoration: const InputDecoration(labelText: 'Nama Supplier'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: totalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total Pembelian'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                DummyData.pembelian.add({
                  'id': DateTime.now().toString(),
                  'tanggal': DateTime.now(),
                  'supplier': supplierController.text,
                  'total': int.tryParse(totalController.text) ?? 0,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pembelian berhasil disimpan')),
                );

                supplierController.clear();
                totalController.clear();
              },
              child: const Text('Simpan Pembelian'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const Text(
              'Riwayat Pembelian',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...DummyData.pembelian.map(
              (p) => ListTile(
                title: Text(p['supplier']),
                subtitle: Text(p['tanggal'].toString()),
                trailing: Text('Rp ${p['total']}'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
