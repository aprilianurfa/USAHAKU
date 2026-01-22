import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/report_service.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_drawer.dart';

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
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("Pusat Laporan", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.defaultGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // _buildHeader() removed
          // Visual spacer to maintain curved look if needed, or just let body start
          Container(
             width: double.infinity,
             height: 20, 
             decoration: const BoxDecoration(
               gradient: AppTheme.defaultGradient,
               borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
             ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
                           '/report-sales'
                         ),
                         _buildReportCard(
                           context, 
                           "Riwayat Transaksi", 
                           Icons.history_edu_rounded, 
                           Colors.purple, 
                           '/transaction-history'
                         ),
                         _buildReportCard(
                           context, 
                           "Laporan Laba Rugi", 
                           Icons.pie_chart_rounded, 
                           Colors.green, 
                           '/report-profit-loss'
                         ),

                         _buildReportCard(
                           context, 
                           "Produk Terlaris", 
                           Icons.star_rounded, 
                           Colors.amber.shade700, 
                           '/report-product-sales'
                         ),
                         _buildReportCard(
                           context, 
                           "Analisa Pengunjung", 
                           Icons.people_alt_rounded, 
                           Colors.teal, 
                           '/report-visitor'
                         ),
                         _buildReportCard(
                           context, 
                           "Laporan Pembelian", 
                           Icons.shopping_bag_rounded, 
                           Colors.indigo, 
                           '/report-purchase'
                         ),
                         _buildReportCard(
                           context, 
                           "Laporan Modal", 
                           Icons.account_balance_rounded, 
                           Colors.blueGrey, 
                           '/report-capital'
                         ),
                         _buildReportCard(
                           context, 
                           "Laporan Shift", 
                           Icons.access_time_filled_rounded, 
                           Colors.deepPurple, 
                           '/report-shift'
                         ),
                      ],
                    )
                  ],
                ),
          ),
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
