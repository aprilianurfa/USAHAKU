import 'package:flutter/material.dart';
import '../../core/dummy_data.dart';

enum SortMode { terbanyak, tersedikit }

class LaporanPenjualanBarangPage extends StatefulWidget {
  const LaporanPenjualanBarangPage({super.key});

  @override
  State<LaporanPenjualanBarangPage> createState() =>
      _LaporanPenjualanBarangPageState();
}

class _LaporanPenjualanBarangPageState
    extends State<LaporanPenjualanBarangPage> {
  String keyword = '';
  SortMode sortMode = SortMode.terbanyak;

  /// ================= HITUNG TOTAL TERJUAL PER BARANG =================
  int totalTerjual(String namaBarang) {
    int total = 0;
    for (var trx in DummyData.transaksi) {
      for (var item in trx['items']) {
        if (item['nama'] == namaBarang) {
          total += item['qty'] as int;
        }
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    // ================= DATA BARANG + TERJUAL =================
    final List<Map<String, dynamic>> data = DummyData.barang.map((b) {
      final terjual = totalTerjual(b['nama']);
      return {
        ...b,
        'terjual': terjual,
      };
    }).toList();

    // ================= SEARCH =================
    final filtered = data.where((b) {
      return b['nama']
          .toString()
          .toLowerCase()
          .contains(keyword.toLowerCase());
    }).toList();

    // ================= SORT =================
    filtered.sort((a, b) => sortMode == SortMode.terbanyak
        ? b['terjual'].compareTo(a['terjual'])
        : a['terjual'].compareTo(b['terjual']));

    final int maxTerjual =
        filtered.isEmpty ? 0 : filtered.first['terjual'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan per Barang'),
      ),
      body: Column(
        children: [
          // ================= FILTER BOX =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // SEARCH
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari barang...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => keyword = v),
                ),
                const SizedBox(height: 10),

                // SORT
                DropdownButtonFormField<SortMode>(
                  value: sortMode,
                  items: const [
                    DropdownMenuItem(
                      value: SortMode.terbanyak,
                      child: Text('Penjualan Terbanyak'),
                    ),
                    DropdownMenuItem(
                      value: SortMode.tersedikit,
                      child: Text('Penjualan Tersedikit'),
                    ),
                  ],
                  onChanged: (v) => setState(() => sortMode = v!),
                  decoration: const InputDecoration(
                    labelText: 'Urutkan',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ================= LIST =================
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Data tidak ditemukan'),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final b = filtered[index];
                      final terjual = b['terjual'];

                      final isTerlaris =
                          terjual > 0 && terjual == maxTerjual;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.12),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.blue,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                b['nama'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isTerlaris)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Terlaris',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          'Kategori: ${b['kategori']}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              terjual.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Text(
                              'Terjual',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
