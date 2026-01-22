import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/report_service.dart';
import '../../widgets/app_drawer.dart';

class ProfitLossReportPage extends StatefulWidget {
  const ProfitLossReportPage({Key? key}) : super(key: key);

  @override
  State<ProfitLossReportPage> createState() => _ProfitLossReportPageState();
}

class _ProfitLossReportPageState extends State<ProfitLossReportPage> {
  final ReportService _reportService = ReportService();
  
  bool _isLoading = true;
  String? _errorMessage;
  
  // Data
  double _totalRevenue = 0;
  double _totalCOGS = 0;
  double _grossProfit = 0;
  double _totalExpenses = 0;
  double _netProfit = 0;
  double _margin = 0;

  String _filterType = "Hari Ini"; // Harian, Mingguan, Bulanan, Tahunan, Custom
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _setFilterRange("Hari Ini"); // Default
  }

  void _setFilterRange(String type) {
    DateTime now = DateTime.now();
    DateTime start, end;

    switch (type) {
      case "Hari Ini":
        start = DateTime(now.year, now.month, now.day);
        end = now;
        break;
      case "Minggu Ini":
        // Find Monday
        DateTime monday = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(monday.year, monday.month, monday.day);
        end = now;
        break;
      case "Bulan Ini":
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0); // Last day
        break;
      case "Tahun Ini":
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31);
        break;
      default: // Custom
        start = _selectedDateRange.start;
        end = _selectedDateRange.end;
    }

    setState(() {
      _filterType = type;
      _selectedDateRange = DateTimeRange(start: start, end: end);
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _reportService.getProfitLossAnalysis(
        startDate: _selectedDateRange.start.toIso8601String(),
        endDate: _selectedDateRange.end.toIso8601String()
      );

      if (mounted) {
        setState(() {
          _totalRevenue = (data['totalRevenue'] ?? 0).toDouble();
          _totalCOGS = (data['totalCOGS'] ?? 0).toDouble();
          _grossProfit = (data['grossProfit'] ?? 0).toDouble();
          _totalExpenses = (data['totalExpenses'] ?? 0).toDouble();
          _netProfit = (data['netProfit'] ?? 0).toDouble();
          _margin = (data['margin'] ?? 0).toDouble();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat data.";
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }
  
  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.defaultGradient)),
        title: const Text("Laporan Laba Rugi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter
                      _buildFilterSection(),
                      const SizedBox(height: 20),

                      // Net Profit Card (Hero)
                      _buildNetProfitCard(),
                      const SizedBox(height: 20),

                      // Breakdown Cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive Grid: 2 columns if wide, 1 if narrow
                          if (constraints.maxWidth > 600) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildBreakdownList()),
                                const SizedBox(width: 20),
                                Expanded(child: _buildChartSection()),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                _buildBreakdownList(),
                                const SizedBox(height: 20),
                                _buildChartSection(),
                              ],
                            );
                          }
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      _buildInsightCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _filterType,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero
              ),
              items: ["Hari Ini", "Minggu Ini", "Bulan Ini", "Tahun Ini", "Custom"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (val) {
                if (val != null) _setFilterRange(val);
              },
            ),
          ),
          Container(width: 1, height: 24, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 8)),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: _selectedDateRange,
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        primaryColor: AppTheme.primaryColor,
                        colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
                      ),
                      child: child!,
                    );
                  }
                );
                if (picked != null) {
                  setState(() {
                    _filterType = "Custom";
                    _selectedDateRange = picked;
                  });
                  _fetchData();
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      _filterType == "Hari Ini" 
                          ? _formatDate(_selectedDateRange.start)
                          : "${_formatDate(_selectedDateRange.start)} - ${_formatDate(_selectedDateRange.end)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primaryColor),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNetProfitCard() {
    final bool isProfit = _netProfit >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit 
            ? [Colors.blue.shade800, Colors.blue.shade600]
            : [Colors.red.shade800, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isProfit ? Colors.blue : Colors.red).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8)
          )
        ]
      ),
      child: Column(
        children: [
          Text("Laba Bersih", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(_netProfit),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20)
            ),
            child: Text(
              "Margin Keuntungan: ${_margin.toStringAsFixed(1)}%",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBreakdownList() {
    return Column(
      children: [
        _buildItemCard("Pendapatan (Kotor)", _totalRevenue, Icons.monetization_on_rounded, Colors.green),
        _buildItemCard("Harga Pokok (HPP)", _totalCOGS, Icons.shopping_bag_outlined, Colors.orange), // HPP is expense-like but part of Gross Profit
        _buildItemCard("Laba Kotor", _grossProfit, Icons.pie_chart_outline, Colors.blue, isBold: true),
        _buildItemCard("Beban Operasional", _totalExpenses, Icons.money_off_csred_rounded, Colors.red),
      ],
    );
  }

  Widget _buildItemCard(String title, double value, IconData icon, Color color, {bool isBold = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          ),
          Text(
            _formatCurrency(value),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          )
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    // Determine Max Y for chart scaling
    final double maxY = [_totalRevenue, _totalCOGS + _totalExpenses, _netProfit].reduce((a, b) => a > b ? a : b);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const Text("Visualisasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
           const SizedBox(height: 20),
           SizedBox(
             height: 200,
             child: BarChart(
               BarChartData(
                 maxY: maxY == 0 ? 100 : maxY * 1.2,
                 barGroups: [
                   _makeBarGroup(0, _totalRevenue, Colors.green, "Jual"),
                   _makeBarGroup(1, _totalCOGS + _totalExpenses, Colors.red, "Biaya"),
                   _makeBarGroup(2, _netProfit, Colors.blue, "Laba"),
                 ],
                 titlesData: FlTitlesData(
                   leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                   topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                   rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                   bottomTitles: AxisTitles(
                     sideTitles: SideTitles(
                       showTitles: true,
                       getTitlesWidget: (val, meta) {
                         const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12);
                         switch (val.toInt()) {
                           case 0: return const Padding(padding: EdgeInsets.only(top: 8), child: Text("Income", style: style));
                           case 1: return const Padding(padding: EdgeInsets.only(top: 8), child: Text("Cost", style: style));
                           case 2: return const Padding(padding: EdgeInsets.only(top: 8), child: Text("Net", style: style));
                         }
                         return const SizedBox();
                       }
                     )
                   )
                 ),
                 gridData: FlGridData(show: false),
                 borderData: FlBorderData(show: false),
               )
             ),
           )
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color, String label) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y, color: color, width: 20, borderRadius: BorderRadius.circular(4))
      ]
    );
  }

  Widget _buildInsightCard() {
    final bool isHealthy = _margin > 20; // Example threshold
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHealthy ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHealthy ? Colors.green.shade200 : Colors.orange.shade200)
      ),
      child: Row(
        children: [
          Icon(isHealthy ? Icons.check_circle : Icons.warning_rounded, color: isHealthy ? Colors.green : Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHealthy ? "Kondisi Keuangan Sehat" : "Perlu Evaluasi Margin",
                  style: TextStyle(fontWeight: FontWeight.bold, color: isHealthy ? Colors.green.shade900 : Colors.orange.shade900),
                ),
                Text(
                  isHealthy ? "Margin keuntungan anda cukup baik." : "HPP terlalu tinggi dibanding penjualan.",
                  style: TextStyle(fontSize: 12, color: isHealthy ? Colors.green.shade800 : Colors.orange.shade800),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

}
