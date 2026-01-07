import 'package:flutter/material.dart';

class LaporanPengunjungPage extends StatelessWidget {
  const LaporanPengunjungPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // ✅ HAPUS const
      appBar: AppBar(
        title: const Text('Laporan Pengunjung'),
      ),
      body: const Center(
        child: Text('Jumlah pengunjung harian'),
      ),
    );
  }
}
