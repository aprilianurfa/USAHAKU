import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/theme.dart';
import '../../core/widgets/keyboard_spacer.dart';

class AddEmployeePage extends StatefulWidget {
  const AddEmployeePage({super.key});

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await AuthService().addEmployee(_nameCtrl.text, _emailCtrl.text, _passCtrl.text);

    if (mounted) {
      if (result != null && result['error'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Karyawan berhasil ditambahkan")));
        Navigator.pop(context, true);
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result?['error'] ?? "Gagal menambah karyawan")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: false, // MANDATORY
      appBar: AppBar(title: const Text("Tambah Karyawan"), backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, elevation: 0, centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const _FormInfoCard(),
          const SizedBox(height: 24),
          RepaintBoundary(
            child: Card(
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const _InputLabel("Nama Lengkap"),
                    _FormInput(controller: _nameCtrl, hint: "Contoh: Budi Santoso", icon: Icons.badge_outlined),
                    const SizedBox(height: 20),
                    const _InputLabel("Email Login"),
                    _FormInput(controller: _emailCtrl, hint: "Contoh: budi@toko.com", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 20),
                    const _InputLabel("Password"),
                    _FormInput(controller: _passCtrl, hint: "Minimal 6 karakter", icon: Icons.lock_outline_rounded, isObscure: true),
                    const SizedBox(height: 32),
                    _SubmitButton(isLoading: _isLoading, onPressed: _submit),
                  ]),
                ),
              ),
            ),
          ),
          const KeyboardSpacer(),
        ]),
      ),
    );
  }
}

class _FormInfoCard extends StatelessWidget {
  const _FormInfoCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.person_add_rounded, color: AppTheme.primaryColor, size: 28)),
        const SizedBox(width: 16),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Informasi Staff", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
          Text("Masukkan data akun untuk login kasir", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ])),
      ]),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String label;
  const _InputLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 8, left: 4), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF424769))));
  }
}

class _FormInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isObscure;
  final TextInputType? keyboardType;
  const _FormInput({required this.controller, required this.hint, required this.icon, this.isObscure = false, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller, obscureText: isObscure, keyboardType: keyboardType,
      validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
      decoration: InputDecoration(
        hintText: hint, prefixIcon: Icon(icon, color: Colors.grey), filled: true, fillColor: const Color(0xFFF8F9FC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _SubmitButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
        child: isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
        : const Text("SIMPAN KARYAWAN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}
