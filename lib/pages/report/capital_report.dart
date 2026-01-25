import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/report_service.dart';
import '../../core/theme.dart';
import 'package:usahaku_main/core/app_shell.dart';

class CapitalReportPage extends StatefulWidget {
  const CapitalReportPage({super.key});

  @override
  State<CapitalReportPage> createState() => _CapitalReportPageState();
}

class _CapitalReportPageState extends State<CapitalReportPage> {
  final ReportService _reportService = ReportService();
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => AppShell.of(context).toggleSidebar(),
        ),
        title: const Text("Analisa Modal & Aset", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.defaultGradient,
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reportService.getInventoryAnalysis(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data ?? {};
          final int totalCost = data['totalCostValue'] ?? 0;
          final int totalSales = data['totalSalesValue'] ?? 0;
          final int potentialProfit = data['potentialProfit'] ?? 0;
          final int totalProducts = data['totalProducts'] ?? 0;
          final int totalStock = data['totalStock'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                     children: [
                       const Icon(Icons.info_outline, color: Colors.blue),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Text(
                           "Perhitungan berdasarkan $totalProducts produk ($totalStock items) yang tersedia di stok saat ini.",
                           style: const TextStyle(color: Colors.blue),
                         ),
                       )
                     ],
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Modal Dasar (Cost)
                _buildCard(
                  title: "Total Nilai Aset (Modal)",
                  value: currencyFormatter.format(totalCost),
                  subtitle: "Estimasi biaya pembelian semua stok saat ini",
                  color: Colors.orange,
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 16),

                // 2. Harga Jual (Revenue)
                _buildCard(
                   title: "Potensi Omset (Harga Jual)",
                   value: currencyFormatter.format(totalSales),
                   subtitle: "Nilai semua stok jika terjual habis",
                   color: Colors.green,
                   icon: Icons.storefront_outlined,
                 ),
                 const SizedBox(height: 16),

                 // 3. Margin (Profit)
                 _buildCard(
                   title: "Potensi Keuntungan",
                   value: currencyFormatter.format(potentialProfit),
                   subtitle: "Selisih Harga Jual dan Modal Dasar",
                   color: AppTheme.primaryColor,
                   icon: Icons.trending_up,
                   isHighlight: true,
                 ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isHighlight ? Border.all(color: color.withOpacity(0.5), width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
             subtitle,
             style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
