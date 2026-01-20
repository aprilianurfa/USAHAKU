import 'package:flutter/material.dart';

class LaporanBiayaPage extends StatelessWidget {
  const LaporanBiayaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // ✅ HAPUS const
      appBar: AppBar(
        title: const Text('Laporan Biaya'),
      ),
      body: const Center(
        child: Text('Biaya operasional'),
      ),
    );
  }
}
