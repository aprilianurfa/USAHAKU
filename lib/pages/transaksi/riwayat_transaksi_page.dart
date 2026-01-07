import 'package:flutter/material.dart';
import '../../core/dummy_data.dart';

class RiwayatTransaksiPage extends StatefulWidget {
  const RiwayatTransaksiPage({super.key});

  @override
  State<RiwayatTransaksiPage> createState() => _RiwayatTransaksiPageState();
}

class _RiwayatTransaksiPageState extends State<RiwayatTransaksiPage> {
  String selectedPelanggan = 'Semua';

  @override
  Widget build(BuildContext context) {
    final List<String> pelangganList = [
      'Semua',
      ...DummyData.pelanggan.map((p) => p['nama'] as String),
    ];

    final transaksiFiltered = selectedPelanggan == 'Semua'
        ? DummyData.transaksi
        : DummyData.transaksi
            .where((t) => t['pelanggan'] == selectedPelanggan)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: selectedPelanggan,
              items: pelangganList
                  .map<DropdownMenuItem<String>>(
                    (String p) => DropdownMenuItem<String>(
                      value: p,
                      child: Text(p),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => selectedPelanggan = v);
                }
              },
              decoration: const InputDecoration(
                labelText: 'Filter Pelanggan',
                prefixIcon: Icon(Icons.person_search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: transaksiFiltered.length,
              itemBuilder: (context, index) {
                final t = transaksiFiltered[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(t['pelanggan']),
                    subtitle: Text(t['tanggal'].toString()),
                    trailing: Text(
                      'Rp ${t['total']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
