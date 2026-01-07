import 'package:flutter/material.dart';
import '../../core/dummy_data.dart';

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  final TextEditingController searchController = TextEditingController();

  String selectedPelanggan =
      DummyData.pelanggan.first['nama'] as String;

  final List<Map<String, dynamic>> keranjang = [];

  void tambahKeKeranjang(Map<String, dynamic> barang) {
    final index = keranjang.indexWhere((e) => e['id'] == barang['id']);
    if (index >= 0) {
      keranjang[index]['qty']++;
    } else {
      keranjang.add({
        'id': barang['id'],
        'nama': barang['nama'],
        'harga': barang['harga'],
        'qty': 1,
      });
    }
    setState(() {});
  }

  int get totalBayar {
    int total = 0;
    for (var item in keranjang) {
      total += (item['harga'] as int) * (item['qty'] as int);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final hasilCari = DummyData.barang.where((b) {
      return b['nama']
          .toString()
          .toLowerCase()
          .contains(searchController.text.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Penjualan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Barcode',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scan barcode (belum aktif)'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ======================
          // PILIH PELANGGAN
          // ======================
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: selectedPelanggan,
              items: DummyData.pelanggan
                  .map<DropdownMenuItem<String>>(
                    (p) => DropdownMenuItem<String>(
                      value: p['nama'] as String,
                      child: Text(p['nama'] as String),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => selectedPelanggan = v);
                }
              },
              decoration: const InputDecoration(
                labelText: 'Pelanggan',
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ),

          // ======================
          // SEARCH BARANG
          // ======================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Cari barang / jasa',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // ======================
          // DAFTAR BARANG
          // ======================
          Expanded(
            child: ListView(
              children: hasilCari.map((b) {
                return ListTile(
                  title: Text(b['nama']),
                  subtitle: Text('Stok: ${b['stok']}'),
                  trailing: Text('Rp ${b['harga']}'),
                  onTap: () => tambahKeKeranjang(b),
                );
              }).toList(),
            ),
          ),

          const Divider(),

          // ======================
          // KERANJANG
          // ======================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keranjang',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...keranjang.map(
                  (k) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${k['nama']} x${k['qty']}'),
                      Text('Rp ${k['harga'] * k['qty']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rp $totalBayar',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: keranjang.isEmpty
                        ? null
                        : () {
                            DummyData.transaksi.add({
                              'id': DateTime.now().toString(),
                              'tanggal': DateTime.now(),
                              'pelanggan': selectedPelanggan,
                              'total': totalBayar,
                              'items': List.from(keranjang),
                            });

                            keranjang.clear();
                            setState(() {});

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Transaksi berhasil disimpan'),
                              ),
                            );
                          },
                    child: const Text('Simpan Transaksi'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
