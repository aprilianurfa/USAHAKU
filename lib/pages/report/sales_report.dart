import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../widgets/summary_card.dart';

class LaporanPenjualanPage extends StatefulWidget {
  const LaporanPenjualanPage({super.key});

  @override
  State<LaporanPenjualanPage> createState() => _LaporanPenjualanPageState();
}

class _LaporanPenjualanPageState extends State<LaporanPenjualanPage> {
  final TransactionService _transactionService = TransactionService();
  late Future<List<Transaksi>> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _transactionService.getTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ringkasan Penjualan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Transaksi>>(
          future: _futureData,
          builder: (context, snapshot) {
             if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
             }
             
             int totalPenjualan = 0;
             int jumlahTransaksi = 0;

             if (snapshot.hasData) {
               jumlahTransaksi = snapshot.data!.length;
               for (var t in snapshot.data!) {
                 totalPenjualan += t.totalBayar;
               }
             }

             return Column(
              children: [
                SummaryCard(
                  title: 'Total Penjualan',
                  value: 'Rp $totalPenjualan', 
                  icon: Icons.payments,
                ),
                SummaryCard(
                  title: 'Jumlah Transaksi',
                  value: '$jumlahTransaksi',
                  icon: Icons.receipt,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
