import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/report_service.dart';
import '../../core/theme.dart';
import '../../widgets/app_drawer.dart';

enum SortMode { terbanyak, tersedikit }

class ProductSalesReportPage extends StatefulWidget {
  const ProductSalesReportPage({super.key});

  @override
  State<ProductSalesReportPage> createState() => _ProductSalesReportPageState();
}

class _ProductSalesReportPageState extends State<ProductSalesReportPage> {
  final ReportService _reportService = ReportService();
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  DateTimeRange? _selectedDateRange;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  Map<String, dynamic> _summary = {};
  
  String _keyword = '';
  SortMode _sortMode = SortMode.terbanyak;

  @override
  void initState() {
    super.initState();
    // Default to this month
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    String? startStr;
    String? endStr;

    if (_selectedDateRange != null) {
      startStr = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
      endStr = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
    }

    final result = await _reportService.getProductSalesAnalysis(startDate: startStr, endDate: endStr);

    if (mounted) {
      setState(() {
        _summary = result['summary'] ?? {};
        _allProducts = List<Map<String, dynamic>>.from(result['data'] ?? []);
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    // 1. Keyword Filter
    var temp = _allProducts.where((p) {
      final name = (p['productName'] ?? '').toString().toLowerCase();
      return name.contains(_keyword.toLowerCase());
    }).toList();

    // 2. Sorting
    temp.sort((a, b) {
      final qtyA = a['totalQty'] as int? ?? 0;
      final qtyB = b['totalQty'] as int? ?? 0;
      
      if (_sortMode == SortMode.terbanyak) {
        return qtyB.compareTo(qtyA);
      } else {
        return qtyA.compareTo(qtyB);
      }
    });

    _filteredProducts = temp;
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.defaultGradient)),
        title: const Text('Produk Terlaris', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: _pickDateRange,
            tooltip: "Pilih Tanggal",
          )
        ],
      ),
      body: Column(
        children: [
          // HEADER DATE INFO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.date_range, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  _selectedDateRange != null
                      ? "${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}"
                      : "Semua Waktu",
                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // SUMMARY CARDS
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: _buildSummaryCard(
                    "Total Terjual", 
                    "${_summary['totalItemsSold'] ?? 0} Item", 
                    Icons.inventory_2_outlined, 
                    Colors.orange
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSummaryCard(
                    "Pendapatan", 
                    currencyFormatter.format(_summary['totalRevenue'] ?? 0), 
                    Icons.monetization_on_outlined, 
                    Colors.green
                  )),
                ],
              ),
            ),

          // FILTER & SEARCH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (v) {
                      setState(() {
                        _keyword = v;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<SortMode>(
                  value: _sortMode,
                  underline: Container(),
                  icon: const Icon(Icons.sort_rounded, color: AppTheme.primaryColor),
                  onChanged: (SortMode? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _sortMode = newValue;
                        _applyFilters();
                      });
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: SortMode.terbanyak, child: Text("Terbanyak")),
                    DropdownMenuItem(value: SortMode.tersedikit, child: Text("Tersedikit")),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          // LIST
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _filteredProducts.isEmpty
                    ? const Center(child: Text("Tidak ada data penjualan"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final item = _filteredProducts[index];
                          final rank = index + 1;
                          final isTop3 = rank <= 3 && _sortMode == SortMode.terbanyak;
                          
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              child: Row(
                                children: [
                                  // RANK BADGE
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isTop3 ? Colors.amber.shade100 : Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                      border: isTop3 ? Border.all(color: Colors.amber, width: 2) : null,
                                    ),
                                    child: Text(
                                      "#$rank",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isTop3 ? Colors.deepOrange : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // INFO
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['productName'] ?? 'Unknown',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${item['categoryName'] ?? '-'}",
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // STATS
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${item['totalQty']} Terjual",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        currencyFormatter.format(item['totalRevenue']),
                                        style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        ],
      ),
    );
  }
}
