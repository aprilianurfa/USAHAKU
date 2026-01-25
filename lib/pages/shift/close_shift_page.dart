import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/shift_service.dart';
import '../../services/auth_service.dart';
import '../../services/printer_service.dart';
import '../../core/theme.dart';
import '../../core/widgets/keyboard_spacer.dart';

class CloseShiftPage extends StatefulWidget {
  const CloseShiftPage({super.key});

  @override
  State<CloseShiftPage> createState() => _CloseShiftPageState();
}

class _CloseShiftPageState extends State<CloseShiftPage> {
  final ShiftService _shiftService = ShiftService();
  final AuthService _authService = AuthService();
  final TextEditingController _cashController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _shiftSummary;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _loadData() async {
    final results = await Future.wait([
      _authService.getUserName(),
      _shiftService.getShiftSummary(),
      _authService.getProfile(),
    ]);
    if (mounted) {
      setState(() {
        _userName = results[0] as String?;
        _shiftSummary = results[1] as Map<String, dynamic>?;
        _isLoading = false;
      });
    }
  }

  void _processCloseShift() async {
    if (_cashController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Masukkan jumlah uang tunai fisik")));
      return;
    }
    setState(() => _isSubmitting = true);
    String clean = _cashController.text.replaceAll(RegExp(r'[^0-9]'), '');
    double actual = double.tryParse(clean) ?? 0;
    
    final result = await _shiftService.closeShift(actual);
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result != null && result['error'] == null) {
        _showSuccessDialog(result['data'] ?? {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result?['error'] ?? "Gagal menutup kasir")));
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> data) async {
    await showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => _ClosingSuccessDialog(data: data, userName: _userName, summary: _shiftSummary),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_shiftSummary == null || _shiftSummary!['error'] != null) return Scaffold(body: Center(child: Text(_shiftSummary?['error'] ?? "Gagal memuat data")));

    final expectedCash = double.tryParse(_shiftSummary?['expectedCash']?.toString() ?? '0') ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      resizeToAvoidBottomInset: false, // MANDATORY
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.defaultGradient)),
        title: const Text("Tutup Kasir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0, foregroundColor: Colors.white,
      ),
      body: ListView( // ListView handles keyboard transitions better than SingleChildScrollView
        children: [
          _CloseShiftHeader(userName: _userName, startTime: _shiftSummary?['startTime']),
          Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                RepaintBoundary(child: _SystemCalculationCard(summary: _shiftSummary)),
                const SizedBox(height: 20),
                RepaintBoundary(child: _ActualCashInputSection(controller: _cashController, expectedCash: expectedCash)),
                const SizedBox(height: 30),
                _CloseShiftButton(isSubmitting: _isSubmitting, onPressed: _processCloseShift),
                const KeyboardSpacer(extraPadding: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseShiftHeader extends StatelessWidget {
  final String? userName;
  final String? startTime;
  const _CloseShiftHeader({this.userName, this.startTime});
  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    String timeStr = startTime != null ? fmt.format(DateTime.parse(startTime!).toLocal()) : "-";
    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(25, 10, 25, 40),
      decoration: const BoxDecoration(gradient: AppTheme.defaultGradient, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
      child: Column(children: [
        Text(userName?.toUpperCase() ?? "KASIR", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), letterSpacing: 1.5, fontSize: 12)),
        const SizedBox(height: 10),
        Text(timeStr, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)), child: const Text("SHIFT BERJALAN", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
      ]),
    );
  }
}

class _SystemCalculationCard extends StatelessWidget {
  final Map<String, dynamic>? summary;
  const _SystemCalculationCard({this.summary});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    double initial = double.tryParse(summary?['initialCash']?.toString() ?? '0') ?? 0;
    double sales = double.tryParse(summary?['totalSales']?.toString() ?? '0') ?? 0;
    double expected = double.tryParse(summary?['expectedCash']?.toString() ?? '0') ?? 0;

    return Container(
      padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(children: [
        Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.calculate_rounded, color: Colors.blue)), const SizedBox(width: 15), const Text("Perhitungan Sistem", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
        const Divider(height: 30),
        _RowInfo(label: "Modal Awal", value: currency.format(initial)),
        const SizedBox(height: 12),
        _RowInfo(label: "Total Penjualan", value: currency.format(sales), color: Colors.green),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: DottedLine()),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("Total Diharapkan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Flexible(child: Text(currency.format(expected), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black), overflow: TextOverflow.ellipsis)),
        ])
      ]),
    );
  }
}

class _ActualCashInputSection extends StatefulWidget {
  final TextEditingController controller;
  final double expectedCash;
  const _ActualCashInputSection({required this.controller, required this.expectedCash});

  @override
  State<_ActualCashInputSection> createState() => _ActualCashInputSectionState();
}

class _ActualCashInputSectionState extends State<_ActualCashInputSection> {
  // ISOALTE calculation state using ValueNotifier
  late final ValueNotifier<double> _diffNotifier;
  
  @override
  void initState() {
    super.initState();
    _diffNotifier = ValueNotifier(-widget.expectedCash);
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _diffNotifier.dispose();
    super.dispose();
  }

  void _onChanged() {
    String clean = widget.controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    double actual = double.tryParse(clean) ?? 0;
    _diffNotifier.value = actual - widget.expectedCash;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Uang Fisik di Laci", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey)),
        const SizedBox(height: 10),
        TextField(controller: widget.controller, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), decoration: InputDecoration(prefixText: "Rp ", filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 20),
        ValueListenableBuilder<double>(
          valueListenable: _diffNotifier,
          builder: (context, diff, _) {
            final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
            final statusColor = diff == 0 ? const Color(0xFF00C853) : (diff < 0 ? const Color(0xFFD50000) : const Color(0xFF2962FF));
            return Container(
              padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text("Selisih / Varian", style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
                Flexible(child: Text(diff == 0 ? "PAS" : (diff > 0 ? "+" : "") + currency.format(diff), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
              ]),
            );
          },
        )
      ]),
    );
  }
}

class _RowInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RowInfo({required this.label, required this.value, this.color = Colors.black});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
      Flexible(child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: color), overflow: TextOverflow.ellipsis)),
    ]);
  }
}

class DottedLine extends StatelessWidget {
  const DottedLine({super.key});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final count = (constraints.constrainWidth() / 10).floor();
      return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(count, (_) => Container(width: 5, height: 1, color: Colors.grey.shade300)));
    });
  }
}

class _CloseShiftButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onPressed;
  const _CloseShiftButton({required this.isSubmitting, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 5),
        child: isSubmitting ? const CircularProgressIndicator(color: Colors.white)
            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lock_rounded, color: Colors.white), SizedBox(width: 10), Text("TUTUP BUKU / KASIR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))]),
      ),
    );
  }
}

class _ClosingSuccessDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? userName;
  final Map<String, dynamic>? summary;
  const _ClosingSuccessDialog({required this.data, this.userName, this.summary});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(15), decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 30)),
          const SizedBox(height: 15),
          const Text("Shift Ditutup", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("Laporan berhasil disimpan", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
            child: Column(children: [
              _ReceiptRow(label: "Waktu Tutup", value: _formatDateTime(data['end']?.toString())),
              const Divider(),
              _ReceiptRow(label: "Uang Sistem", value: currency.format(double.tryParse(data['expected']?.toString() ?? '0') ?? 0)),
              _ReceiptRow(label: "Uang Fisik", value: currency.format(double.tryParse(data['actual']?.toString() ?? '0') ?? 0)),
              const Divider(),
              _ReceiptRow(label: "Selisih", value: currency.format(double.tryParse(data['difference']?.toString() ?? '0') ?? 0), isBold: true, color: (double.tryParse(data['difference']?.toString() ?? '0') ?? 0) == 0 ? Colors.green : Colors.red),
            ]),
          ),
          const SizedBox(height: 25),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _print(context), icon: const Icon(Icons.print_rounded), label: const Text("Cetak"), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("SELESAI"))),
          ]),
        ]),
      ),
    );
  }

  String _formatDateTime(String? iso) {
    if (iso == null) return "-";
    try { return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(iso).toLocal()); } catch (_) { return iso; }
  }

  void _print(BuildContext context) async {
    final ps = PrinterService();
    if (await ps.isConnected) {
      final printData = Map<String, dynamic>.from(summary ?? {});
      printData.addAll(data);
      await ps.printShiftReport(printData, userName: userName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Printer belum terhubung."), backgroundColor: Colors.orange));
    }
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;
  const _ReceiptRow({required this.label, required this.value, this.isBold = false, this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)), Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: color ?? Colors.black87))]));
  }
}
