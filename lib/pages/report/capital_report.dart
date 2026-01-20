import 'package:flutter/material.dart';

class LaporanModalPage extends StatelessWidget {
  const LaporanModalPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ===== DATA DUMMY =====
    final int totalModal = 25000000;
    final List<Map<String, dynamic>> riwayatModal = [
      {
        'tanggal': '20 Jan 2026',
        'keterangan': 'Penambahan modal awal',
        'jumlah': 15000000,
        'tipe': 'masuk',
      },
      {
        'tanggal': '18 Jan 2026',
        'keterangan': 'Pembelian peralatan',
        'jumlah': 3000000,
        'tipe': 'keluar',
      },
      {
        'tanggal': '15 Jan 2026',
        'keterangan': 'Penambahan modal',
        'jumlah': 8000000,
        'tipe': 'masuk',
      },
      {
        'tanggal': '12 Jan 2026',
        'keterangan': 'Renovasi toko',
        'jumlah': 5000000,
        'tipe': 'keluar',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Modal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== RINGKASAN MODAL =====
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.account_balance, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Modal Usaha',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp $totalModal',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===== RIWAYAT MODAL =====
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Riwayat Perubahan Modal',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: riwayatModal.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final data = riwayatModal[index];
                final bool isMasuk = data['tipe'] == 'masuk';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isMasuk
                        ? Colors.green.withOpacity(0.15)
                        : Colors.red.withOpacity(0.15),
                    child: Icon(
                      isMasuk ? Icons.add : Icons.remove,
                      color: isMasuk ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(data['keterangan']),
                  subtitle: Text(data['tanggal']),
                  trailing: Text(
                    (isMasuk ? '+ ' : '- ') + 'Rp ${data['jumlah']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isMasuk ? Colors.green : Colors.red,
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
