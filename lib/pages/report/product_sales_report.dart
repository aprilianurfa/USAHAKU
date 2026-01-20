import 'package:flutter/material.dart';
import '../../core/dummy_data.dart';

class LaporanPenjualanBarangPage extends StatelessWidget {
  const LaporanPenjualanBarangPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Penjualan per Barang')),
      body: ListView(
        children: DummyData.barang.map(
          (b) => ListTile(
            title: Text(b['nama']),
            subtitle: Text('Kategori: ${b['kategori']}'),
            trailing: const Text('Terjual: 10'),
          ),
        ).toList(),
      ),
    );
  }
}
