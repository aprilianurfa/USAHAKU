import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseReportPage extends StatelessWidget {
  const ExpenseReportPage({super.key});

  String formatRupiah(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    // DATA DUMMY (NANTI DARI DATABASE)
    final totalBiaya = 8750000;

    final List<Map<String, dynamic>> biayaList = [
      {
        'nama': 'Gaji Karyawan',
        'tanggal': '20 Jan 2026',
        'jumlah': 5000000,
        'icon': Icons.people_rounded,
      },
      {
        'nama': 'Listrik & Air',
        'tanggal': '18 Jan 2026',
        'jumlah': 1250000,
        'icon': Icons.flash_on_rounded,
      },
      {
        'nama': 'Internet',
        'tanggal': '15 Jan 2026',
        'jumlah': 750000,
        'icon': Icons.wifi_rounded,
      },
      {
        'nama': 'Perlengkapan Toko',
        'tanggal': '10 Jan 2026',
        'jumlah': 1750000,
        'icon': Icons.shopping_cart_rounded,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Biaya'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ================= TOTAL BIAYA =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.redAccent.withOpacity(0.15),
                    child: const Icon(
                      Icons.money_off_csred_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Biaya',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRupiah(totalBiaya),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= DETAIL BIAYA =================
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Detail Biaya',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: biayaList.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final biaya = biayaList[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Colors.redAccent.withOpacity(0.1),
                    child: Icon(
                      biaya['icon'],
                      color: Colors.redAccent,
                    ),
                  ),
                  title: Text(biaya['nama']),
                  subtitle: Text(biaya['tanggal']),
                  trailing: Text(
                    formatRupiah(biaya['jumlah']),
                    style: const TextStyle(
                      color: Colors.redAccent,
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
}
