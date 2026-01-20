import 'package:flutter/material.dart';

class LaporanModalPage extends StatelessWidget {
  const LaporanModalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // ✅ HAPUS const
      appBar: AppBar(
        title: const Text('Laporan Modal'),
      ),
      body: const Center(
        child: Text('Total modal usaha'),
      ),
    );
  }
}
