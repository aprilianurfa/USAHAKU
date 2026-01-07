import 'package:flutter/material.dart';
import '../../core/dummy_data.dart';
import '../../widgets/summary_card.dart';

class LaporanPenjualanPage extends StatelessWidget {
  const LaporanPenjualanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = DummyData.laporanRingkasan;

    return Scaffold(
      appBar: AppBar(title: const Text('Ringkasan Penjualan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SummaryCard(
              title: 'Total Penjualan',
              value: data['penjualanHariIni'],
              icon: Icons.payments,
            ),
            SummaryCard(
              title: 'Jumlah Transaksi',
              value: data['jumlahTransaksi'],
              icon: Icons.receipt,
            ),
          ],
        ),
      ),
    );
  }
}
