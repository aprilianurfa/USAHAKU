import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/report_service.dart';
import 'package:usahaku_main/core/app_shell.dart';

class ProfitLossReportPage extends StatefulWidget {
  const ProfitLossReportPage({super.key});

  @override
  State<ProfitLossReportPage> createState() => _ProfitLossReportPageState();
}

class _ProfitLossReportPageState extends State<ProfitLossReportPage> {
  final ReportService _reportService = ReportService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, double> _data = {};
  String _filterType = "Hari Ini";
  DateTimeRange _selectedDateRange = DateTimeRange(start: DateTime.now(), end: DateTime.now());

  @override
  void initState() {
    super.initState();
    _setFilterRange("Hari Ini");
  }

  void _setFilterRange(String type) {
    DateTime now = DateTime.now();
    DateTime start, end;
    switch (type) {
      case "Hari Ini": start = DateTime(now.year, now.month, now.day); end = now; break;
      case "Minggu Ini": start = now.subtract(Duration(days: now.weekday - 1)); end = now; break;
      case "Bulan Ini": start = DateTime(now.year, now.month, 1); end = DateTime(now.year, now.month + 1, 0); break;
      case "Tahun Ini": start = DateTime(now.year, 1, 1); end = DateTime(now.year, 12, 31); break;
      default: start = _selectedDateRange.start; end = _selectedDateRange.end;
    }
    setState(() { _filterType = type; _selectedDateRange = DateTimeRange(start: start, end: end); });
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _reportService.getProfitLossAnalysis(startDate: _selectedDateRange.start.toIso8601String(), endDate: _selectedDateRange.end.toIso8601String());
      if (mounted) {
        setState(() {
          _data = {
            'totalRevenue': (res['totalRevenue'] ?? 0).toDouble(),
            'totalCOGS': (res['totalCOGS'] ?? 0).toDouble(),
            'grossProfit': (res['grossProfit'] ?? 0).toDouble(),
            'totalExpenses': (res['totalExpenses'] ?? 0).toDouble(),
            'netProfit': (res['netProfit'] ?? 0).toDouble(),
            'margin': (res['margin'] ?? 0).toDouble(),
          };
          _isLoading = false;
        });
      }
    } catch (_) { if (mounted) setState(() { _errorMessage = "Gagal memuat data."; _isLoading = false; }); }
  }

  Widget _buildFilterSection() {
    return _ReportFilterBar(
      type: _filterType,
      range: _selectedDateRange,
      onFilterChanged: _setFilterRange,
      onRangePicked: (p) {
        setState(() {
          _filterType = "Custom";
          _selectedDateRange = p;
        });
        _fetchData();
      },
    );
  }

  Widget _buildReportContent() {
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    return _ProfitLossContent(data: _data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => AppShell.of(context).toggleSidebar(),
        ),
        title: const Text("Laba Rugi", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.defaultGradient)),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildReportContent(),
          ),
        ],
      ),
    );
  }
}

class _ReportFilterBar extends StatelessWidget {
  final String type;
  final DateTimeRange range;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<DateTimeRange> onRangePicked;
  const _ReportFilterBar({required this.type, required this.range, required this.onFilterChanged, required this.onRangePicked});

  @override
  Widget build(BuildContext context) {
    String label = type == "Hari Ini" ? DateFormat('dd MMM yyyy').format(range.start) : "${DateFormat('dd MMM').format(range.start)} - ${DateFormat('dd MMM').format(range.end)}";
    return Container(
      padding: const EdgeInsets.all(16), color: Colors.white,
      child: Row(children: [
        Expanded(child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: type, isDense: true, items: ["Hari Ini", "Minggu Ini", "Bulan Ini", "Tahun Ini", "Custom"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(), onChanged: (v) { if (v != null) onFilterChanged(v); }))),
        const VerticalDivider(),
        InkWell(
          onTap: () async {
            final p = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDateRange: range);
            if (p != null) onRangePicked(p);
          },
          child: Row(children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(width: 8), const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor)]),
        )
      ]),
    );
  }
}

class _ProfitLossContent extends StatelessWidget {
  final Map<String, double> data;
  const _ProfitLossContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NetProfitHero(netProfit: data['netProfit'] ?? 0, margin: data['margin'] ?? 0),
          const SizedBox(height: 20),
          _BreakdownSection(data: data),
          const SizedBox(height: 20),
          _ChartSection(data: data),
          const SizedBox(height: 20),
          _InsightCard(margin: data['margin'] ?? 0),
        ],
      ),
    );
  }
}

class _NetProfitHero extends StatelessWidget {
  final double netProfit;
  final double margin;
  const _NetProfitHero({required this.netProfit, required this.margin});

  @override
  Widget build(BuildContext context) {
    final bool isProfit = netProfit >= 0;
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: LinearGradient(colors: isProfit ? [Colors.blue.shade800, Colors.blue.shade600] : [Colors.red.shade800, Colors.red.shade600]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: (isProfit ? Colors.blue : Colors.red).withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(children: [
        Text("Laba Bersih", style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16)),
        const SizedBox(height: 8),
        Text(currency.format(netProfit), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)), child: Text("Margin: ${margin.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      ]),
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  final Map<String, double> data;
  const _BreakdownSection({required this.data});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _ReportTile(title: "Pendapatan (Kotor)", value: data['totalRevenue'] ?? 0, icon: Icons.monetization_on, color: Colors.green),
      _ReportTile(title: "Harga Pokok (HPP)", value: data['totalCOGS'] ?? 0, icon: Icons.shopping_bag, color: Colors.orange),
      _ReportTile(title: "Laba Kotor", value: data['grossProfit'] ?? 0, icon: Icons.pie_chart, color: Colors.blue, isBold: true),
      _ReportTile(title: "Beban Operasional", value: data['totalExpenses'] ?? 0, icon: Icons.money_off, color: Colors.red),
    ]);
  }
}

class _ReportTile extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final bool isBold;
  const _ReportTile({required this.title, required this.value, required this.icon, required this.color, this.isBold = false});
  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5)]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 24)),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal))),
        Text(currency.format(value), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
      ]),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final Map<String, double> data;
  const _ChartSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final rev = data['totalRevenue'] ?? 0;
    final cost = (data['totalCOGS'] ?? 0) + (data['totalExpenses'] ?? 0);
    final net = data['netProfit'] ?? 0;
    final maxVal = [rev, cost, net].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Visualisasi Perbandingan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 20),
        SizedBox(height: 200, child: RepaintBoundary(child: BarChart(BarChartData(
          maxY: maxVal == 0 ? 100 : maxVal * 1.2,
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: rev, color: Colors.green, width: 22, borderRadius: BorderRadius.circular(4))]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: cost, color: Colors.red, width: 22, borderRadius: BorderRadius.circular(4))]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: net, color: Colors.blue, width: 22, borderRadius: BorderRadius.circular(4))]),
          ],
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
              const s = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11);
              switch(v.toInt()) { case 0: return const Text("Income", style: s); case 1: return const Text("Cost", style: s); case 2: return const Text("Net", style: s); }
              return const SizedBox();
            })),
          ),
          gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
        )))),
      ]),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final double margin;
  const _InsightCard({required this.margin});
  @override
  Widget build(BuildContext context) {
    bool healthy = margin > 20;
    return Container(
      padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: healthy ? Colors.green.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: healthy ? Colors.green.shade200 : Colors.orange.shade200)),
      child: Row(children: [
        Icon(healthy ? Icons.check_circle : Icons.warning_rounded, color: healthy ? Colors.green : Colors.orange),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(healthy ? "Kondisi Keuangan Sehat" : "Perlu Evaluasi Margin", style: TextStyle(fontWeight: FontWeight.bold, color: healthy ? Colors.green.shade900 : Colors.orange.shade900)), Text(healthy ? "Margin keuntungan anda baik." : "HPP/Biaya tinggi dibanding omzet.", style: TextStyle(fontSize: 12, color: healthy ? Colors.green.shade800 : Colors.orange.shade800))])),
      ]),
    );
  }
}
