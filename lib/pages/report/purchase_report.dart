import 'package:flutter/material.dart';
import '../../core/dummy_data.dart';

class LaporanPembelianPage extends StatelessWidget {
  const LaporanPembelianPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pembelian = DummyData.pembelian;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Pembelian'),
      ),
      body: ListView.builder(
        itemCount: pembelian.length,
        itemBuilder: (context, index) {
          final p = pembelian[index];

          return ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: Text(p['supplier'] ?? '-'),
            subtitle: Text(
              p['tanggal']?.toString() ?? '-',
            ),
            trailing: Text(
              'Rp ${p['total']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}
