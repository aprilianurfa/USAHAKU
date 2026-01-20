import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/shift_service.dart';
import '../../services/auth_service.dart';

class CloseShiftPage extends StatefulWidget {
  const CloseShiftPage({Key? key}) : super(key: key);

  @override
  State<CloseShiftPage> createState() => _CloseShiftPageState();
}

class _CloseShiftPageState extends State<CloseShiftPage> {
  // Service
  final ShiftService _shiftService = ShiftService();
  final AuthService _authService = AuthService();

  // State
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _shiftSummary;
  
  // Input
  final TextEditingController _cashController = TextEditingController();
  double _actualCash = 0;
  double _difference = 0;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadData();
    _cashController.addListener(_onCashChanged);
  }

  @override
  void dispose() {
    _cashController.removeListener(_onCashChanged);
    _cashController.dispose();
    super.dispose();
  }

  void _loadData() async {
    _userName = await _authService.getUserName();
    final summary = await _shiftService.getShiftSummary();
    
    if (mounted) {
      setState(() {
        _shiftSummary = summary;
        _isLoading = false;
        
        // Calculate initial difference (assuming 0 actual cash)
        if (_shiftSummary != null) {
          _updateCalculation(0);
        }
      });
    }
  }

  void _onCashChanged() {
    String clean = _cashController.text.replaceAll(RegExp(r'[^0-9]'), '');
    double val = double.tryParse(clean) ?? 0;
    _updateCalculation(val);
  }

  void _updateCalculation(double actual) {
    if (_shiftSummary == null) return;
    double expected = double.tryParse(_shiftSummary!['expectedCash'].toString()) ?? 0;
    
    setState(() {
      _actualCash = actual;
      _difference = _actualCash - expected;
    });
  }

  void _processCloseShift() async {
    if (_cashController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan jumlah uang tunai fisik")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _shiftService.closeShift(_actualCash);

    setState(() => _isSubmitting = false);

    if (result != null && result['error'] == null) {
       // Success Dialog
       if (mounted) {
         await showDialog(
           context: context,
           barrierDismissible: false,
           builder: (ctx) => AlertDialog(
             title: const Row(
               children: [
                 Icon(Icons.check_circle, color: Colors.green),
                 SizedBox(width: 10),
                 Text("Shift Ditutup"),
               ],
             ),
             content: const Text("Laporan shift berhasil disimpan."),
             actions: [
               TextButton(
                 onPressed: () {
                   Navigator.pop(ctx); // Close dialog
                   Navigator.pop(context, true); // Return to dashboard, true = refresh
                 },
                 child: const Text("OK"),
               )
             ],
           )
         );
       }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result?['error'] ?? "Gagal menutup kasir")),
        );
      }
    }
  }

  String _formatRupiah(double val) {
    return NumberFormat.currency(
      locale: 'id_ID', 
      symbol: 'Rp ', 
      decimalDigits: 0
    ).format(val);
  }

  String _formatDateTime(String? isoDate) {
    if (isoDate == null) return "-";
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    final bool isDiscrepancyNegative = _difference < 0;
    final bool isMatch = _difference == 0;
    final Color statusColor = isMatch ? Colors.green : (isDiscrepancyNegative ? Colors.red : Colors.blue);
    
    // Values
    final double initialCash = double.tryParse(_shiftSummary?['initialCash']?.toString() ?? '0') ?? 0;
    final double systemSales = double.tryParse(_shiftSummary?['totalSales']?.toString() ?? '0') ?? 0;
    final double expectedCash = double.tryParse(_shiftSummary?['expectedCash']?.toString() ?? '0') ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Tutup Kasir", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _shiftSummary == null || _shiftSummary!['error'] != null
            ? Center(child: Text(_shiftSummary?['error'] ?? "Gagal memuat data"))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 1. INFO SHIFT CARD
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                      ),
                      child: Column(
                        children: [
                          _buildRowInfo("Nama Kasir", _userName ?? "-"),
                          const Divider(height: 24),
                          _buildRowInfo("Waktu Buka", _formatDateTime(_shiftSummary?['startTime'])),
                          const SizedBox(height: 12),
                          _buildRowInfo("Modal Awal", _formatRupiah(initialCash), isValueBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. SUMMARY SALES (SYSTEM)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade100)
                      ),
                      child: Column(
                        children: [
                          _buildRowInfo("Total Penjualan (Sistem)", _formatRupiah(systemSales), isValueBold: true),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total Uang Diharapkan", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(_formatRupiah(expectedCash), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. INPUT ACTUAL CASH
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Hitung Uang Fisik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300)
                      ),
                      child: TextField(
                        controller: _cashController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          prefixText: "Rp ",
                          border: InputBorder.none,
                          hintText: "0"
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. DISCREPANCY STATUS
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.5))
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Selisih", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                          Text(
                            _difference == 0 ? "SESUAI" : _formatRupiah(_difference),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18),
                          )
                        ],
                      ),
                    ),
                    if (_difference != 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          isDiscrepancyNegative 
                            ? "* Uang fisik kurang dari sistem (Expense)" 
                            : "* Uang fisik lebih dari sistem (Surplus)",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ),

                    const SizedBox(height: 40),

                    // 5. BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _processCloseShift,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor: Colors.redAccent.withOpacity(0.5),
                        ),
                        child: _isSubmitting 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("PROSES TUTUP KASIR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
            ),
    );
  }

  Widget _buildRowInfo(String label, String value, {bool isValueBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontWeight: isValueBold ? FontWeight.bold : FontWeight.normal, fontSize: 15)),
      ],
    );
  }
}
