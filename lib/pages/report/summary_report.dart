import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/report_service.dart';
import 'package:intl/intl.dart';

class LaporanRingkasanPage extends StatefulWidget {
  const LaporanRingkasanPage({super.key});

  @override
  State<LaporanRingkasanPage> createState() => _LaporanRingkasanPageState();
}

class _LaporanRingkasanPageState extends State<LaporanRingkasanPage> {
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
    if (mounted) {
      setState(() {
        _summaryData = data;
        _isLoading = false;
      });
    }
  }

  String _formatRupiah(num? amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pusat Laporan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // HEADER CARD
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                  ]
                ),
                child: Column(
                  children: [
                    const Text("Penjualan Hari Ini", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 10),
                    Text(
                      _formatRupiah(_summaryData['salesToday']),
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatItem(Icons.receipt_long, "${_summaryData['trxCountToday']} Transaksi"),
                        Container(height: 20, width: 1, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 15)),
                        _buildStatItem(Icons.trending_up, "Profit: ask owner"),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),
              
              // MENU GRID
              const Text("Menu Laporan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 15),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.3,
                children: [
                   _buildReportCard(
                     context, 
                     "Laporan Penjualan", 
                     Icons.bar_chart_rounded, 
                     Colors.blue, 
                     '/sales-report'
                   ),
                   _buildReportCard(
                     context, 
                     "Riwayat Transaksi", 
                     Icons.history_edu_rounded, 
                     Colors.purple, 
                     '/transaction-report'
                   ),
                   _buildReportCard(
                     context, 
                     "Laporan Laba Rugi", 
                     Icons.pie_chart_rounded, 
                     Colors.green, 
                     '/profit-loss-report'
                   ),
                   _buildReportCard(
                     context, 
                     "Arus Kas", 
                     Icons.account_balance_wallet_rounded, 
                     Colors.orange, 
                     '/cash-flow-report'
                   ),
                   _buildReportCard(
                     context, 
                     "Produk Terlaris", 
                     Icons.star_rounded, 
                     Colors.amber.shade700, 
                     '/product-sales-report'
                   ),
                   _buildReportCard(
                     context, 
                     "Analisa Pengunjung", 
                     Icons.people_alt_rounded, 
                     Colors.teal, 
                     '/visitor-report'
                   ),
                ],
              )
            ],
          ),
    );
  }

  Widget _buildStatItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildReportCard(BuildContext context, String title, IconData icon, Color color, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
             BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
          ],
        ),
      ),
    );
  }
}
