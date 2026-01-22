import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/report_service.dart';
import '../../widgets/app_drawer.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  final ReportService _reportService = ReportService();
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  // State
  List<Map<String, dynamic>> _salesData = []; // Top selling (descending)
  List<Map<String, dynamic>> _customerData = [];
  Map<String, dynamic> _summary = {}; // Backend summary

  bool _isLoading = true;
  String _dateFilterLabel = "Bulan Ini";
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // Default to Today
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: now,
    );
    _dateFilterLabel = DateFormat('d MMM yyyy', 'id').format(now);
    
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    String? startDate;
    String? endDate;

    if (_selectedDateRange != null) {
      startDate = _selectedDateRange!.start.toIso8601String();
      endDate = _selectedDateRange!.end.toIso8601String();
    }

    try {
      final salesFuture = _reportService.getProductSalesAnalysis(startDate: startDate, endDate: endDate);
      final customerFuture = _reportService.getCustomerSalesAnalysis(startDate: startDate, endDate: endDate);

      final results = await Future.wait([salesFuture, customerFuture]);

      if (mounted) {
        setState(() {
          final productResult = results[0] as Map<String, dynamic>;
          _summary = productResult['summary'] ?? {};
          _salesData = productResult['data'] as List<Map<String, dynamic>>? ?? [];
          
          _customerData = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
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
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _dateFilterLabel = "${DateFormat('d MMM').format(picked.start)} - ${DateFormat('d MMM').format(picked.end)}";
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Summary Calculations from Backend
    int totalItemsSold = _summary['totalItemsSold'] ?? 0;
    int totalRevenue = _summary['totalRevenue'] ?? 0;
    int totalTransactions = _summary['totalTransactions'] ?? 0;

    // Least Selling: Take last 5 of salesData (which is sorted desc)
    List<Map<String, dynamic>> leastSelling = [];
    if (_salesData.isNotEmpty) {
      leastSelling = _salesData.reversed.take(5).toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("Laporan Penjualan", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.defaultGradient,
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => _pickDateRange(context),
            tooltip: "Pilih Tanggal",
          )
        ],
      ),
      body: Column(
        children: [
          // Header Date Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
            decoration: const BoxDecoration(
              gradient: AppTheme.defaultGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Text(
                  _dateFilterLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 5),
                Text(
                  currencyFormatter.format(totalRevenue),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Total Pendapatan",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Overview Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            "Produk Terjual",
                            "$totalItemsSold",
                            Icons.inventory_2_outlined,
                            Colors.blue,
                            onTap: () => Navigator.pushNamed(context, '/report-product-sales'),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildSummaryCard(
                            "Transaksi",
                             "$totalTransactions",
                            Icons.receipt_long_rounded,
                            Colors.orange,
                            subtitle: "Transaksi Sukses",
                            onTap: () => Navigator.pushNamed(context, '/report-visitor'), // Diarahkan ke data pelanggan/visit report
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // --- TOP CUSTOMERS SECTION ---
                    if (_customerData.isNotEmpty) ...[
                      const _SectionHeader(title: "Pelanggan Setia", icon: Icons.stars_rounded, color: Colors.amber),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 140, // Horizontal list height
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _customerData.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 15),
                          itemBuilder: (ctx, i) => _buildCustomerCard(_customerData[i], i),
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],
                    
                    // --- TOP SELLING SECTION ---
                    const _SectionHeader(title: "Produk Terlaris", icon: Icons.trending_up, color: Colors.green),
                    const SizedBox(height: 15),

                    ..._salesData.take(5).toList().asMap().entries.map((entry) { // Only show top 5 here to save space? Or all? Let's show all or top 10
                       int index = entry.key;
                       Map<String, dynamic> item = entry.value;
                       double percentage = (item['totalRevenue'] as int) / (totalRevenue == 0 ? 1 : totalRevenue);
                       return _buildSalesItem(index + 1, item, percentage);
                    }).toList(),

                    if (_salesData.length > 5) ...[
                       Center(child: TextButton(onPressed: (){}, child: const Text("Lihat Semua Produk")))
                    ],
                    
                    const SizedBox(height: 25),

                     // --- LEAST SELLING SECTION ---
                    if (leastSelling.isNotEmpty) ...[
                      const _SectionHeader(title: "Produk Kurang Laris", icon: Icons.trending_down, color: Colors.redAccent),
                      const SizedBox(height: 5),
                      const Text("Pertimbangkan untuk promosi atau restok lebih sedikit.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 15),
                      
                      ...leastSelling.map((item) => _buildLeastSellingItem(item)).toList(),
                    ]
                  ],
                ),
          ),
        ],
      ),
    );
  }

   Widget _buildSummaryCard(String title, String value, IconData icon, Color color, {String? subtitle, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 15),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(subtitle ?? title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> data, int index) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           CircleAvatar(
             radius: 20,
             backgroundColor: index == 0 ? Colors.amber.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
             child: Icon(Icons.person, color: index == 0 ? Colors.amber : Colors.blue, size: 20),
           ),
           const SizedBox(height: 10),
           Text(
             data['name'], 
             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
             maxLines: 1, 
             overflow: TextOverflow.ellipsis,
             textAlign: TextAlign.center,
           ),
           const SizedBox(height: 5),
           Text(
             "${data['trxCount']} Transaksi",
             style: const TextStyle(fontSize: 10, color: Colors.grey),
           ),
           const SizedBox(height: 4),
           Text(
             currencyFormatter.format(data['totalSpend']),
             style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
             textAlign: TextAlign.center,
           ),
        ],
      ),
    );
  }

  Widget _buildSalesItem(int rank, Map<String, dynamic> item, double percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))
        ]
      ),
      child: Row(
        children: [
           Container(
             width: 28,
             height: 28,
             alignment: Alignment.center,
             decoration: BoxDecoration(
               color: rank <= 3 ? const Color(0xFFFFD700) : Colors.grey.shade200,
               shape: BoxShape.circle,
             ),
             child: Text(
               "#$rank", 
               style: TextStyle(
                 fontWeight: FontWeight.bold, 
                 color: rank <= 3 ? Colors.black : Colors.grey.shade600,
                 fontSize: 11
               )
             ),
           ),
           const SizedBox(width: 12),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   item['productName'], 
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                   maxLines: 1, 
                   overflow: TextOverflow.ellipsis
                 ),
                 if (item['categoryName'] != null)
                   Text(
                     item['categoryName'], 
                     style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                   ),
                 const SizedBox(height: 4),
                 ClipRRect(
                   borderRadius: BorderRadius.circular(4),
                   child: LinearProgressIndicator(
                     value: percentage,
                     backgroundColor: Colors.grey.shade100,
                     color: AppTheme.primaryColor,
                     minHeight: 5,
                   ),
                 ),
               ],
             ),
           ),
           const SizedBox(width: 10),
           Column(
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
               Text(currencyFormatter.format(item['totalRevenue']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
               Text("${item['totalQty']} pcs", style: const TextStyle(fontSize: 11, color: Colors.grey)),
             ],
           )
        ],
      ),
    );
  }

  Widget _buildLeastSellingItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade300, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(item['productName'], style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
          Text("${item['totalQty']} Terjual", style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
