import 'package:flutter/material.dart';
import '../../core/dummy_data.dart';

class LaporanTransaksiPage extends StatelessWidget {
  const LaporanTransaksiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Transaksi')),
      body: ListView.builder(
        itemCount: DummyData.transaksi.length,
        itemBuilder: (context, index) {
          final t = DummyData.transaksi[index];
          return ListTile(
            title: Text(t['pelanggan']),
            subtitle: Text(t['tanggal'].toString()),
            trailing: Text('Rp ${t['total']}'),
          );
        },
      ),
    );
  }
}
