import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/report_service.dart';
import '../../core/theme.dart';
import 'package:usahaku_main/core/app_shell.dart';

class VisitorReportPage extends StatefulWidget {
  const VisitorReportPage({super.key});

  @override
  State<VisitorReportPage> createState() => _VisitorReportPageState();
}

class _VisitorReportPageState extends State<VisitorReportPage> {
  final ReportService _reportService = ReportService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _customers = [];
  double _totalSpendAll = 0;
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)), 
    end: DateTime.now()
  );

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _reportService.getCustomerSalesAnalysis(
        startDate: _selectedDateRange.start.toIso8601String(),
        endDate: _selectedDateRange.end.toIso8601String(),
      );
      
      double total = 0;
      for (var c in data) {
        total += (c['totalSpend'] ?? 0);
      }

      if (mounted) {
        setState(() {
          _customers = data;
          _totalSpendAll = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error fetching visitor report: $e");
    }
  }

  String _formatCurrency(num amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
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
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.defaultGradient)),
        title: const Text('Laporan Pelanggan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: InkWell(
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  initialDateRange: _selectedDateRange,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
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
                  setState(() => _selectedDateRange = picked);
                  _fetchData();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${DateFormat('dd MMM yyyy').format(_selectedDateRange.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange.end)}",
                       style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryColor)
                  ],
                ),
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _customers.isEmpty 
                  ? const Center(child: Text("Belum ada data pelanggan."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _customers.length,
                      itemBuilder: (context, index) {
                        final customer = _customers[index];
                        final double profit = (customer['totalProfit'] ?? 0).toDouble();
                        final double spend = (customer['totalSpend'] ?? 0).toDouble();
                        final String name = customer['name'] ?? 'Umum';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: index < 3 ? Colors.amber.shade100 : Colors.blue.shade50,
                                    child: Icon(
                                      index < 3 ? Icons.emoji_events_rounded : Icons.person, 
                                      color: index < 3 ? Colors.amber.shade800 : Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text("${customer['trxCount']} Transaksi", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                       Text(_formatCurrency(spend), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                       Text("Total Belanja", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                    ],
                                  )
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Keuntungan dari ${name.split(' ')[0]}:", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green.shade100)
                                    ),
                                    child: Text(
                                      "+${_formatCurrency(profit)}", 
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 13)
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
