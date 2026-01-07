import 'package:flutter/material.dart';
import '../../core/dummy_data.dart';
import '../../widgets/summary_card.dart';

class LaporanLabaRugiPage extends StatelessWidget {
  const LaporanLabaRugiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = DummyData.laporanRingkasan;

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Laba Rugi')),
      body: Column(
        children: [
          SummaryCard(
            title: 'Total Penjualan',
            value: data['penjualanHariIni'],
            icon: Icons.arrow_upward,
          ),
          SummaryCard(
            title: 'Laba Bersih',
            value: data['labaBersih'],
            icon: Icons.trending_up,
          ),
        ],
      ),
    );
  }
}
