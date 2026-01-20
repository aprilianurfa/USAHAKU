import 'package:flutter/material.dart';
import '../../core/dummy_data.dart';

class LaporanPembelianPage extends StatelessWidget {
  const LaporanPembelianPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Pembelian')),
      body: ListView(
        children: DummyData.pembelian.map(
          (p) => ListTile(
            title: Text(p['supplier']),
            subtitle: Text(p['tanggal'].toString()),
            trailing: Text('Rp ${p['total']}'),
          ),
        ).toList(),
      ),
    );
  }
}
