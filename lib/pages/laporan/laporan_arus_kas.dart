import 'package:flutter/material.dart';

class LaporanArusKasPage extends StatelessWidget {
  const LaporanArusKasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // ✅ HAPUS const DI SINI
      appBar: AppBar(
        title: const Text('Laporan Arus Kas'),
      ),
      body: const Center(
        child: Text('Arus kas masuk & keluar'),
      ),
    );
  }
}
