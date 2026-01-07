import 'package:flutter/material.dart';

class LaporanRingkasanPage extends StatelessWidget {
  const LaporanRingkasanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: ListView(
        children: const [
          _Menu('Ringkasan Penjualan', '/laporan-penjualan'),
          _Menu('Laporan Transaksi Penjualan', '/laporan-transaksi'),
          _Menu('Laporan Laba Rugi', '/laporan-laba-rugi'),
          _Menu('Laporan Arus Kas', '/laporan-arus-kas'),
          _Menu('Laporan Penjualan Barang', '/laporan-penjualan-barang'),
          _Menu('Laporan Pengunjung', '/laporan-pengunjung'),
          _Menu('Laporan Pembelian Barang', '/laporan-pembelian'),
          _Menu('Laporan Modal', '/laporan-modal'),
          _Menu('Laporan Biaya', '/laporan-biaya'),
        ],
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  final String title;
  final String route;

  const _Menu(this.title, this.route);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.insert_chart),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}
