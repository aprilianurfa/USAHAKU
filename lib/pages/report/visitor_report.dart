import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VisitorReportPage extends StatelessWidget {
  const VisitorReportPage({super.key});

  // ❗ Locale dihapus agar tidak error
  String formatTanggal(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    // ===== DATA DUMMY =====
    final int totalPengunjung = 328;
    final List<Map<String, dynamic>> pengunjungHarian = [
      {'tanggal': DateTime(2026, 1, 20), 'jumlah': 45},
      {'tanggal': DateTime(2026, 1, 19), 'jumlah': 52},
      {'tanggal': DateTime(2026, 1, 18), 'jumlah': 38},
      {'tanggal': DateTime(2026, 1, 17), 'jumlah': 61},
      {'tanggal': DateTime(2026, 1, 16), 'jumlah': 44},
      {'tanggal': DateTime(2026, 1, 15), 'jumlah': 88},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Pengunjung'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== RINGKASAN =====
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.people_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Pengunjung',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalPengunjung Orang',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===== DETAIL =====
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pengunjung Harian',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pengunjungHarian.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final data = pengunjungHarian[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.15),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Colors.blue,
                      size: 18,
                    ),
                  ),
                  title: Text(formatTanggal(data['tanggal'])),
                  trailing: Text(
                    '${data['jumlah']} orang',
                    style: const TextStyle(
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
