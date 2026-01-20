import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../models/sales_report_model.dart';
import '../../services/transaction_service.dart';

class TransactionReportPage extends StatefulWidget {
  const TransactionReportPage({super.key});

  @override
  State<TransactionReportPage> createState() => _TransactionReportPageState();
}

class _TransactionReportPageState extends State<TransactionReportPage> {
  final TransactionService _transactionService = TransactionService();
  final NumberFormat _rupiah =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
      ),
      body: FutureBuilder<SalesReport>(
        future: _transactionService.getSalesReport(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Terjadi kesalahan: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Belum ada data laporan'),
            );
          }

          final report = snapshot.data!;
          final list = report.transactions;

          return Column(
            children: [
              // Summary Section
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Omset',
                        _rupiah.format(report.totalSales),
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Transaksi',
                        '${report.transactionCount}',
                        Icons.receipt,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Transaction List
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('Belum ada transaksi'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final t = list[index];
                          return ListTile(
                            leading: const Icon(Icons.receipt_long, color: Colors.blue),
                            title: Text(
                              t.namaPelanggan,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              DateFormat('dd MMM yyyy • HH:mm').format(t.tanggal),
                            ),
                            trailing: Text(
                              _rupiah.format(t.totalBayar),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
