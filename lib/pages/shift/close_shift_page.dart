import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/shift_service.dart';
import '../../services/auth_service.dart';
import '../../services/printer_service.dart';
import '../../core/theme.dart';

class CloseShiftPage extends StatefulWidget {
  const CloseShiftPage({Key? key}) : super(key: key);

  @override
  State<CloseShiftPage> createState() => _CloseShiftPageState();
}

class _CloseShiftPageState extends State<CloseShiftPage> {
  // Service
  final ShiftService _shiftService = ShiftService();
  final AuthService _authService = AuthService();
  final PrinterService _printerService = PrinterService();

  // State
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _shiftSummary;
  
  // Input
  final TextEditingController _cashController = TextEditingController();
  double _actualCash = 0;
  double _difference = 0;
  String? _userName;
  String _shopName = "USAHAKU";

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
      final profile = await _authService.getProfile();
      String shopName = "USAHAKU";
      if (profile != null && profile['Shop'] != null) {
        shopName = profile['Shop']['nama_toko'] ?? "USAHAKU";
      }

      setState(() {
        _shiftSummary = summary;
        _shopName = shopName;
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

    if (mounted) setState(() => _isSubmitting = true);

    final result = await _shiftService.closeShift(_actualCash);

    if (mounted) setState(() => _isSubmitting = false);

    if (result != null && result['error'] == null) {
       // Extract compare data
       final data = result['data'] ?? {};
       
       if (mounted) {
         await showDialog(
           context: context,
           barrierDismissible: false,
           builder: (ctx) => Dialog(
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
             child: Padding(
               padding: const EdgeInsets.all(25),
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Container(
                     padding: const EdgeInsets.all(15),
                     decoration: const BoxDecoration(
                       color: Colors.green,
                       shape: BoxShape.circle
                     ),
                     child: const Icon(Icons.check, color: Colors.white, size: 30),
                   ),
                   const SizedBox(height: 15),
                   const Text("Shift Ditutup", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                   const Text("Laporan berhasil disimpan", style: TextStyle(color: Colors.grey)),
                   const SizedBox(height: 25),
                   
                   // Receipt View
                   Container(
                     padding: const EdgeInsets.all(15),
                     decoration: BoxDecoration(
                       color: Colors.grey.shade50,
                       borderRadius: BorderRadius.circular(10),
                       border: Border.all(color: Colors.grey.shade200)
                     ),
                     child: Column(
                       children: [
                         _buildReceiptRow("Waktu Tutup", _formatDateTime(data['end']?.toString())),
                         const SizedBox(height: 8),
                         const Divider(),
                         const SizedBox(height: 8),
                         _buildReceiptRow("Uang Sistem", _formatRupiah(double.tryParse(data['expected']?.toString() ?? '0') ?? 0)),
                         _buildReceiptRow("Uang Fisik", _formatRupiah(double.tryParse(data['actual']?.toString() ?? '0') ?? 0)),
                         const SizedBox(height: 8),
                         const Divider(),
                         const SizedBox(height: 8),
                         _buildReceiptRow("Selisih", _formatRupiah(double.tryParse(data['difference']?.toString() ?? '0') ?? 0), 
                           isBold: true, 
                           color: (double.tryParse(data['difference']?.toString() ?? '0') ?? 0) == 0 ? Colors.green : Colors.red
                         ),
                       ],
                     ),
                   ),
                   
                   const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              bool connected = await _printerService.isConnected;
                              if (connected) {
                                // Merge shiftSummary with closing result data for printing
                                final printData = Map<String, dynamic>.from(_shiftSummary ?? {});
                                printData.addAll(data);
                                
                                await _printerService.printShiftReport(
                                  printData,
                                  shopName: _shopName,
                                  userName: _userName,
                                );
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Printer belum terhubung."),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.print_rounded),
                            label: const Text("Cetak"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pop(context, true); 
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                            ),
                            child: const Text("SELESAI"),
                          ),
                        ),
                      ],
                    ),
                 ],
               ),
             ),
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

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: color ?? Colors.black87)),
        ],
      ),
    );
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
    final Color statusColor = isMatch ? const Color(0xFF00C853) : (isDiscrepancyNegative ? const Color(0xFFD50000) : const Color(0xFF2962FF));

    // Values
    final double initialCash = double.tryParse(_shiftSummary?['initialCash']?.toString() ?? '0') ?? 0;
    final double systemSales = double.tryParse(_shiftSummary?['totalSales']?.toString() ?? '0') ?? 0;
    final double expectedCash = double.tryParse(_shiftSummary?['expectedCash']?.toString() ?? '0') ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        flexibleSpace: Container(decoration: BoxDecoration(gradient: AppTheme.defaultGradient)),
        title: const Text("Tutup Kasir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _shiftSummary == null || _shiftSummary!['error'] != null
            ? Center(child: Text(_shiftSummary?['error'] ?? "Gagal memuat data"))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Summary
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: AppTheme.defaultGradient,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(25, 10, 25, 40),
                      child: Column(
                        children: [
                          Text(_userName?.toUpperCase() ?? "KASIR", style: TextStyle(color: Colors.white.withOpacity(0.8), letterSpacing: 1.5, fontSize: 12)),
                          const SizedBox(height: 10),
                          Text(
                            _formatDateTime(_shiftSummary?['startTime']),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                            child: const Text("SHIFT BERJALAN", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),

                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // 1. SYSTEM CALCULATION CARD
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))]
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.calculate_rounded, color: Colors.blue)),
                                      const SizedBox(width: 15),
                                      const Text("Perhitungan Sistem", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                  const Divider(height: 30),
                                  _buildRowInfo("Modal Awal", _formatRupiah(initialCash)),
                                  const SizedBox(height: 12),
                                  _buildRowInfo("Total Penjualan", _formatRupiah(systemSales), color: Colors.green),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: DottedLine()),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Total Diharapkan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                      Flexible(child: Text(_formatRupiah(expectedCash), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black), overflow: TextOverflow.ellipsis)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),

                            // 2. ACTUAL INPUT CARD
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))]
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Uang Fisik di Laci", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey)),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _cashController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      prefixText: "Rp ",
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Result Container
                                  Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statusColor.withOpacity(0.3))
                                    ),
                                    child: Column(
                                      children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text("Selisih / Varian", style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
                                              Flexible(
                                                child: Text(
                                                   _difference == 0 ? "PAS" : (_difference > 0 ? "+" : "") + _formatRupiah(_difference),
                                                   style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
                                                   overflow: TextOverflow.ellipsis,
                                                ),
                                              )
                                            ],
                                          ),
                                        if (_difference != 0)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              isDiscrepancyNegative 
                                                ? "Uang kurang $_difference (Rugi)" 
                                                : "Uang berlebih +$_difference (Surplus)",
                                              style: TextStyle(color: statusColor, fontSize: 12),
                                            ),
                                          )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 30),

                            // 3. ACTION BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _processCloseShift,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD32F2F),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  elevation: 5,
                                ),
                                child: _isSubmitting 
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.lock_rounded, color: Colors.white),
                                        SizedBox(width: 10),
                                        Text("TUTUP BUKU / KASIR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ],
                                    ),
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ),
    );
  }

  // Adding DottedLine Widget Helper inside the class or extracted
  Widget _buildRowInfo(String label, String value, {Color color = Colors.black}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(width: 8), // Spacing
        Flexible(
          child: Text(
            value, 
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class DottedLine extends StatelessWidget {
  const DottedLine({super.key});
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey.shade300)),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
        );
      },
    );
  }
}
