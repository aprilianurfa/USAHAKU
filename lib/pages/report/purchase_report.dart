import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/purchase_provider.dart';
import 'package:usahaku_main/core/app_shell.dart';

class PurchaseReportPage extends StatefulWidget {
  const PurchaseReportPage({super.key});

  @override
  State<PurchaseReportPage> createState() => _PurchaseReportPageState();
}

class _PurchaseReportPageState extends State<PurchaseReportPage> {
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
  final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');
  
  DateTimeRange? _selectedDateRange;
  String _dateFilterLabel = "Semua Waktu";

  @override
  void initState() {
    super.initState();
    // Default to show all, or we could default to today
    _dateFilterLabel = "Semua Waktu";
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
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
        title: const Text("Laporan Pembelian", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.defaultGradient,
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => _pickDateRange(context),
          ),
          Consumer<PurchaseProvider>(
            builder: (context, provider, _) => IconButton(
              icon: provider.isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.sync_rounded),
              onPressed: () => provider.performSync(),
            ),
          ),
        ],
      ),
      body: Consumer<PurchaseProvider>(
        builder: (context, provider, child) {
          final allPurchases = provider.purchases;
          
          // Filter by date range
          final filtered = allPurchases.where((p) {
            if (_selectedDateRange == null) return true;
            return p.tanggal.isAfter(_selectedDateRange!.start.subtract(const Duration(seconds: 1))) &&
                   p.tanggal.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
          }).toList();

          final int totalBeli = filtered.fold(0, (sum, p) => sum + p.totalBiaya);

          return Column(
            children: [
              // Summary Header
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
                      currencyFormatter.format(totalBeli),
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Total Nilai Pembelian",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              _selectedDateRange == null 
                                ? "Belum ada riwayat pembelian" 
                                : "Tidak ada pembelian di periode ini",
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(color: Colors.grey.shade100),
                            ),
                            child: ExpansionTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.local_shipping_outlined, color: Colors.blue),
                              ),
                              title: Text(
                                item.supplier.isNotEmpty ? item.supplier : "Tanpa Supplier",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(dateFormatter.format(item.tanggal)),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormatter.format(item.totalBiaya),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 15),
                                  ),
                                  if (!item.isSynced)
                                    const Text("Tertunda", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              children: [
                                if (item.keterangan.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.note_alt_outlined, size: 16, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(item.keterangan, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                const Divider(indent: 16, endIndent: 16),
                                ...item.items.map((i) => ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                      title: Text(i.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                      subtitle: Text("${i.jumlah} unit x ${currencyFormatter.format(i.hargaBeli)}", style: const TextStyle(fontSize: 12)),
                                      trailing: Text(
                                        currencyFormatter.format(i.jumlah * i.hargaBeli),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    )),
                                const SizedBox(height: 12),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
