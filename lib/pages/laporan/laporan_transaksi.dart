import 'package:flutter/material.dart';
import '../../models/transaksi.dart';
import '../../services/transaction_service.dart';

class LaporanTransaksiPage extends StatefulWidget {
  const LaporanTransaksiPage({super.key});

  @override
  State<LaporanTransaksiPage> createState() => _LaporanTransaksiPageState();
}

class _LaporanTransaksiPageState extends State<LaporanTransaksiPage> {
  final TransactionService _transactionService = TransactionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Transaksi')),
      body: FutureBuilder<List<Transaksi>>(
        future: _transactionService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada transaksi'));
          }

          final list = snapshot.data!;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final t = list[index];
              return ListTile(
                title: Text(t.namaPelanggan),
                subtitle: Text(t.tanggal.toString()),
                trailing: Text('Rp ${t.totalBayar}'),
              );
            },
          );
        },
      ),
    );
  }
}
