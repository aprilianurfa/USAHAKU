import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/shift_service.dart';
import '../../core/theme.dart';
import '../../core/widgets/keyboard_spacer.dart';

class OpenShiftPage extends StatefulWidget {
  const OpenShiftPage({super.key});

  @override
  State<OpenShiftPage> createState() => _OpenShiftPageState();
}

class _OpenShiftPageState extends State<OpenShiftPage> {
  final TextEditingController _cashController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _openShift() async {
    if (_cashController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Masukkan jumlah uang modal awal")));
      return;
    }
    setState(() => _isLoading = true);
    String cleanString = _cashController.text.replaceAll(RegExp(r'[^0-9]'), '');
    double initialCash = double.tryParse(cleanString) ?? 0;
    final result = await ShiftService().openShift(initialCash);
    if (mounted) {
      if (result != null && result['error'] == null) {
        Navigator.pop(context, true);
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result?['error'] ?? "Gagal membuka kasir")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // MANDATORY
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.defaultGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const _OpenShiftIcon(),
              const SizedBox(height: 30),
              const _OpenShiftTitle(),
              const SizedBox(height: 50),
              RepaintBoundary(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))]),
                  child: Column(children: [
                    const Text("INPUT MODAL AWAL", style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    const SizedBox(height: 15),
                    _CashInputField(controller: _cashController),
                    const SizedBox(height: 30),
                    _MulaiButton(isLoading: _isLoading, onPressed: _openShift),
                  ]),
                ),
              ),
              const SizedBox(height: 30),
              const _CurrentDateFooter(),
              const KeyboardSpacer(),
            ]),
          ),
        ),
      ),
    );
  }
}

class _OpenShiftIcon extends StatelessWidget {
  const _OpenShiftIcon();
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.storefront_rounded, size: 80, color: Colors.white));
  }
}

class _OpenShiftTitle extends StatelessWidget {
  const _OpenShiftTitle();
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Text("Buka Kasir", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      const SizedBox(height: 10),
      Text("Selamat Datang! Siapkan modal awal\nuntuk memulai operasional hari ini.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16)),
    ]);
  }
}

class _CashInputField extends StatelessWidget {
  final TextEditingController controller;
  const _CashInputField({required this.controller});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, keyboardType: TextInputType.number, textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A1F3D)),
      decoration: InputDecoration(
        hintText: "0", prefixText: "Rp ", prefixStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
        border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300, width: 2)),
      ),
    );
  }
}

class _MulaiButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _MulaiButton({required this.isLoading, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 60,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 5),
        child: isLoading ? const CircularProgressIndicator(color: Colors.white)
            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle_outline, color: Colors.white), SizedBox(width: 10), Text("MULAI OPERASIONAL", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))]),
      ),
    );
  }
}

class _CurrentDateFooter extends StatelessWidget {
  const _CurrentDateFooter();
  @override
  Widget build(BuildContext context) {
    return Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()), style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14));
  }
}
