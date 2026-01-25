import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import 'package:usahaku_main/core/app_shell.dart';
import '../../services/report_service.dart';

class ShiftReportPage extends StatefulWidget {
  const ShiftReportPage({super.key});

  @override
  State<ShiftReportPage> createState() => _ShiftReportPageState();
}

class _ShiftReportPageState extends State<ShiftReportPage> {
  final ReportService _reportService = ReportService();
  
  List<Map<String, dynamic>> _shifts = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Summary Variables
  double _totalSalesPeriod = 0;
  double _totalVariancePeriod = 0;
  
  // Date Filter
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _fetchShifts();
  }

  Future<void> _fetchShifts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? startStr;
      String? endStr;

      if (_selectedDateRange != null) {
        startStr = _selectedDateRange!.start.toIso8601String();
        endStr = _selectedDateRange!.end.toIso8601String();
      }

      final data = await _reportService.getShiftReports(startDate: startStr, endDate: endStr);
      
      // Calculate Totals
      double totalSales = 0;
      double totalVariance = 0;
      for (var shift in data) {
         totalSales += (shift['totalSales'] ?? 0).toDouble();
         totalVariance += (shift['variance'] ?? 0).toDouble();
      }

      if (mounted) {
        setState(() {
          _shifts = data;
          _totalSalesPeriod = totalSales;
          _totalVariancePeriod = totalVariance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat laporan shift.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now()
      ),
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
      _fetchShifts();
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return "Rp 0";
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  String _formatDateTime(String? iso) {
    if (iso == null) return "-";
    try {
      return DateFormat("dd MMM yyyy, HH:mm").format(DateTime.parse(iso).toLocal());
    } catch (e) {
      return iso;
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return "-";
    try {
      return DateFormat("HH:mm").format(DateTime.parse(iso).toLocal());
    } catch (e) {
      return iso;
    }
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
        title: const Text("Laporan Shift", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterHeader(),
          if (!_isLoading) _buildPeriodSummary(), // Added Summary
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
                        TextButton(onPressed: _fetchShifts, child: const Text("Coba Lagi"))
                      ],
                    ))
                  : _shifts.isEmpty
                      ? const Center(child: Text("Belum ada data shift.", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _shifts.length,
                          itemBuilder: (context, index) {
                            return _buildShiftCard(_shifts[index]);
                          },
                        ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    String dateText = "Semua Waktu";
    if (_selectedDateRange != null) {
       dateText = "${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Filter Tanggal", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 4),
              Text(dateText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.calendar_today_rounded, size: 16),
            label: const Text("Pilih"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPeriodSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem("Total Pendapatan", _formatCurrency(_totalSalesPeriod), Icons.monetization_on_rounded),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildSummaryItem("Total Selisih", _formatCurrency(_totalVariancePeriod), Icons.difference_rounded, 
            isWarning: _totalVariancePeriod < 0),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, {bool isWarning = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value, 
          style: TextStyle(
            color: isWarning ? Colors.redAccent.shade100 : Colors.white, 
            fontSize: 18, 
            fontWeight: FontWeight.bold
          )
        ),
      ],
    );
  }

  Widget _buildShiftCard(Map<String, dynamic> shift) {
    final double sales = (shift['totalSales'] ?? 0).toDouble();
    final double variance = (shift['variance'] ?? 0).toDouble();
    final bool isLoss = variance < 0;
    final bool isSurplus = variance > 0;
    final Color varianceColor = isLoss ? Colors.red : (isSurplus ? Colors.green : Colors.grey);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200))
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shift['employeeName'] ?? "Kasir", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                        "${_formatDateTime(shift['startTime'])} - ${_formatTime(shift['endTime'])}", 
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade100)
                  ),
                  child: const Text("CLOSED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                )
              ],
            ),
          ),
          
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRow("Modal Awal", _formatCurrency(shift['initialCash'])),
                const SizedBox(height: 8),
                _buildRow("Total Penjualan", _formatCurrency(sales), isBold: true, color: AppTheme.primaryColor),
                const Divider(height: 24),
                _buildRow("Uang Fisik", _formatCurrency(shift['finalCash'])),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Selisih", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: varianceColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6)
                      ),
                      child: Text(
                        (isSurplus ? "+" : "") + _formatCurrency(variance), 
                        style: TextStyle(fontWeight: FontWeight.bold, color: varianceColor)
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color color = Colors.black}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        Text(value, style: TextStyle(
          fontSize: 15, 
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color
        )),
      ],
    );
  }
}
