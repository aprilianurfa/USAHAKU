import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CashFlowReportPage extends StatelessWidget {
  const CashFlowReportPage({super.key});

  String formatRupiah(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    // ===== DATA DUMMY =====
    final kasMasuk = 25000000;
    final kasKeluar = 18000000;
    final saldoKas = kasMasuk - kasKeluar;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Arus Kas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== RINGKASAN =====
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    title: 'Kas Masuk',
                    value: formatRupiah(kasMasuk),
                    color: Colors.green,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    title: 'Kas Keluar',
                    value: formatRupiah(kasKeluar),
                    color: Colors.redAccent,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _summaryCard(
              title: 'Saldo Kas',
              value: formatRupiah(saldoKas),
              color: Colors.blue,
              icon: Icons.account_balance_wallet_rounded,
            ),

            const SizedBox(height: 24),

            // ===== DETAIL =====
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Detail Arus Kas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final isMasuk = index.isEven;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        (isMasuk ? Colors.green : Colors.red).withOpacity(0.12),
                    child: Icon(
                      isMasuk
                          ? Icons.call_received_rounded
                          : Icons.call_made_rounded,
                      color: isMasuk ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                    isMasuk ? 'Penjualan' : 'Biaya Operasional',
                  ),
                  subtitle: const Text('20 Jan 2026'),
                  trailing: Text(
                    formatRupiah(isMasuk ? 3500000 : 1200000),
                    style: TextStyle(
                      color: isMasuk ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= CARD =================
  Widget _summaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
