import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/shift_service.dart';
import '../../core/theme.dart';

class OpenShiftPage extends StatefulWidget {
  const OpenShiftPage({super.key});

  @override
  State<OpenShiftPage> createState() => _OpenShiftPageState();
}

class _OpenShiftPageState extends State<OpenShiftPage> {
  final TextEditingController _cashController = TextEditingController();
  final ShiftService _shiftService = ShiftService();
  bool _isLoading = false;

  void _openShift() async {
    if (_cashController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan jumlah uang modal awal")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Clean input "Rp 100.000" -> "100000"
    String cleanString = _cashController.text.replaceAll(RegExp(r'[^0-9]'), '');
    double initialCash = double.tryParse(cleanString) ?? 0;

    final result = await _shiftService.openShift(initialCash);

    setState(() => _isLoading = false);

    if (result != null && result['error'] == null) {
      if (mounted) {
        // Success
        Navigator.pop(context, true); // Return true to signal refresh
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result?['error'] ?? "Gagal membuka kasir")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.point_of_sale, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                "Buka Kasir",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Masukkan modal awal di laci kasir\nsebelum memulai transaksi.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))
                  ]
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _cashController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Modal Awal (Rp)",
                        prefixIcon: const Icon(Icons.money),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50
                      ),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _openShift,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("MULAI SHIFT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
