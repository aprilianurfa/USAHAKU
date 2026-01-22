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
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.defaultGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_rounded, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 30),
                
                const Text(
                  "Buka Kasir",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Selamat Datang! Siapkan modal awal\nuntuk memulai operasional hari ini.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                ),
                const SizedBox(height: 50),

                // Input Card
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "INPUT MODAL AWAL",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _cashController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1F3D),
                        ),
                        decoration: InputDecoration(
                          hintText: "0",
                          prefixText: "Rp ",
                          prefixStyle: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade400,
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _openShift,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C3E50), // Dark premium color
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 5,
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.check_circle_outline, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text("MULAI OPERASIONAL", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "${DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now())}",
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
