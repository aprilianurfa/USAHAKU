import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/report_service.dart';
import 'package:usahaku_main/core/app_shell.dart';
import 'package:usahaku_main/core/view_metrics.dart';

class SummaryReportPage extends StatefulWidget {
  const SummaryReportPage({super.key});

  @override
  State<SummaryReportPage> createState() => _SummaryReportPageState();
}

class _SummaryReportPageState extends State<SummaryReportPage> {
  final ReportService _reportService = ReportService();
  Map<String, dynamic> _summaryData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    final data = await _reportService.getSummary();
    if (mounted) setState(() { _summaryData = data; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: false, // MANDATORY
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => AppShell.of(context).toggleSidebar(),
        ),
        title: const Text("Pusat Laporan", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0, backgroundColor: Colors.transparent, foregroundColor: Colors.white,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.defaultGradient)),
      ),
      body: Column(
        children: [
          const _ReportHeaderSpacer(),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator())
                : _ReportContent(data: _summaryData),
          ),
        ],
      ),
    );
  }
}

class _ReportHeaderSpacer extends StatelessWidget {
  const _ReportHeaderSpacer();
  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity, height: 20, decoration: const BoxDecoration(gradient: AppTheme.defaultGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))));
  }
}

class _ReportContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReportContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return RepaintBoundary(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        children: [
          _HighlightCard(salesToday: fmt.format(data['salesToday'] ?? 0), trxCount: data['trxCountToday'] ?? 0),
          const SizedBox(height: 30),
          const Text("Menu Laporan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 15),
          const _ReportMenuGrid(),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String salesToday;
  final int trxCount;
  const _HighlightCard({required this.salesToday, required this.trxCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))]
      ),
      child: Column(children: [
        const Text("Penjualan Hari Ini", style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 10),
        Text(salesToday, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _StatRow(icon: Icons.receipt_long, label: "$trxCount Transaksi"),
          Container(height: 20, width: 1, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 15)),
          const _StatRow(icon: Icons.trending_up, label: "Profit: Aktif"),
        ])
      ]),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatRow({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 5), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))]);
  }
}

class _ReportMenuGrid extends StatelessWidget {
  const _ReportMenuGrid();
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.3,
      children: [
        _ReportCard(title: "Laporan Penjualan", icon: Icons.bar_chart_rounded, color: Colors.blue, route: '/report-sales'),
        _ReportCard(title: "Riwayat Transaksi", icon: Icons.history_edu_rounded, color: Colors.purple, route: '/transaction-history'),
        _ReportCard(title: "Laporan Laba Rugi", icon: Icons.pie_chart_rounded, color: Colors.green, route: '/report-profit-loss'),
        _ReportCard(title: "Produk Terlaris", icon: Icons.star_rounded, color: Colors.amber.shade700, route: '/report-product-sales'),
        _ReportCard(title: "Analisa Pengunjung", icon: Icons.people_alt_rounded, color: Colors.teal, route: '/report-visitor'),
        _ReportCard(title: "Laporan Pembelian", icon: Icons.shopping_bag_rounded, color: Colors.indigo, route: '/report-purchase'),
        _ReportCard(title: "Laporan Modal", icon: Icons.account_balance_rounded, color: Colors.blueGrey, route: '/report-capital'),
        _ReportCard(title: "Laporan Shift", icon: Icons.access_time_filled_rounded, color: Colors.deepPurple, route: '/report-shift'),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  const _ReportCard({required this.title, required this.icon, required this.color, required this.route});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
        ]),
      ),
    );
  }
}
