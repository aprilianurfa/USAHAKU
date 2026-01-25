import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/report_service.dart';
import 'package:usahaku_main/core/app_shell.dart';
import 'package:usahaku_main/core/view_metrics.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  final ReportService _reportService = ReportService();

  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _customerData = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String _dateFilterLabel = "";
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(start: DateTime(now.year, now.month, now.day), end: now);
    _dateFilterLabel = DateFormat('d MMM yyyy', 'id').format(now);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    String? start = _selectedDateRange?.start.toIso8601String();
    String? end = _selectedDateRange?.end.toIso8601String();

    try {
      final results = await Future.wait([
        _reportService.getProductSalesAnalysis(startDate: start, endDate: end),
        _reportService.getCustomerSalesAnalysis(startDate: start, endDate: end),
      ]);
      if (mounted) {
        setState(() {
          final prodRes = results[0] as Map<String, dynamic>;
          _summary = prodRes['summary'] ?? {};
          _salesData = prodRes['data'] as List<Map<String, dynamic>>? ?? [];
          _customerData = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); }
    }
  }

  void _onDatePicked(DateTimeRange range) {
    setState(() {
      _selectedDateRange = range;
      _dateFilterLabel = "${DateFormat('d MMM').format(range.start)} - ${DateFormat('d MMM').format(range.end)}";
    });
    _fetchData();
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
        title: const Text("Laporan Penjualan", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0, backgroundColor: Colors.transparent, foregroundColor: Colors.white,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.defaultGradient)),
        actions: [IconButton(icon: const Icon(Icons.calendar_month_rounded), onPressed: () => _pickDateRange())],
      ),
      body: Column(
        children: [
          _SalesHeader(label: _dateFilterLabel, total: _summary['totalRevenue'] ?? 0),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator())
                : _SalesContent(
                    summary: _summary,
                    customerData: _customerData,
                    salesData: _salesData,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDateRange: _selectedDateRange);
    if (picked != null) _onDatePicked(picked);
  }
}

class _SalesHeader extends StatelessWidget {
  final String label;
  final int total;
  const _SalesHeader({required this.label, required this.total});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      decoration: const BoxDecoration(gradient: AppTheme.defaultGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
      child: Column(children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 5),
        Text(fmt.format(total), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const Text("Total Pendapatan", style: TextStyle(color: Colors.white54, fontSize: 12)),
      ]),
    );
  }
}

class _SalesContent extends StatelessWidget {
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> customerData;
  final List<Map<String, dynamic>> salesData;
  const _SalesContent({required this.summary, required this.customerData, required this.salesData});

  @override
  Widget build(BuildContext context) {
    final totalRevenue = summary['totalRevenue'] ?? 1;
    return RepaintBoundary(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SummaryRow(itemsSold: summary['totalItemsSold'] ?? 0, trxCount: summary['totalTransactions'] ?? 0),
          const SizedBox(height: 25),
          if (customerData.isNotEmpty) ...[
            const _SectionLabel(title: "Pelanggan Setia", icon: Icons.stars_rounded, color: Colors.amber),
            const SizedBox(height: 10),
            _CustomerHorizontalList(data: customerData),
            const SizedBox(height: 25),
          ],
          const _SectionLabel(title: "Produk Terlaris", icon: Icons.trending_up, color: Colors.green),
          const SizedBox(height: 15),
          ...salesData.take(10).toList().asMap().entries.map((e) => _ProductSalesTile(rank: e.key + 1, item: e.value, revenueTarget: totalRevenue)),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int itemsSold;
  final int trxCount;
  const _SummaryRow({required this.itemsSold, required this.trxCount});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _StatCard(title: "Produk Terjual", value: "$itemsSold", icon: Icons.inventory_2_outlined, color: Colors.blue, route: '/report-product-sales')),
      const SizedBox(width: 15),
      Expanded(child: _StatCard(title: "Transaksi", value: "$trxCount", icon: Icons.receipt_long_rounded, color: Colors.orange, route: '/report-visitor')),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String route;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color, required this.route});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionLabel({required this.title, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: color)),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ]);
  }
}

class _CustomerHorizontalList extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _CustomerHorizontalList({required this.data});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: data.length, separatorBuilder: (_, __) => const SizedBox(width: 15),
        itemBuilder: (ctx, i) => _CustomerCard(data: data[i], index: i),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;
  const _CustomerCard({required this.data, required this.index});
  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      width: 140, padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircleAvatar(radius: 20, backgroundColor: index == 0 ? Colors.amber.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.1), child: Icon(Icons.person, color: index == 0 ? Colors.amber : Colors.blue, size: 20)),
        const SizedBox(height: 10),
        Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        Text("${data['trxCount']} Transaksi", style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(fmt.format(data['totalSpend']), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _ProductSalesTile extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> item;
  final int revenueTarget;
  const _ProductSalesTile({required this.rank, required this.item, required this.revenueTarget});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    double pct = (item['totalRevenue'] as int) / (revenueTarget == 0 ? 1 : revenueTarget);
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: rank <= 3 ? const Color(0xFFFFD700) : Colors.grey.shade200, shape: BoxShape.circle), child: Text("#$rank", style: TextStyle(fontWeight: FontWeight.bold, color: rank <= 3 ? Colors.black : Colors.grey.shade600, fontSize: 11))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['productName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (item['categoryName'] != null) Text(item['categoryName'], style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          const SizedBox(height: 4),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, backgroundColor: Colors.grey.shade100, color: AppTheme.primaryColor, minHeight: 5)),
        ])),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(fmt.format(item['totalRevenue']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text("${item['totalQty']} pcs", style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ]),
    );
  }
}
