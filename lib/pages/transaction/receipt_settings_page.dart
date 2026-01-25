import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/printer_service.dart';
import '../../core/widgets/keyboard_spacer.dart';

class ReceiptSettingsPage extends StatefulWidget {
  const ReceiptSettingsPage({super.key});

  @override
  State<ReceiptSettingsPage> createState() => _ReceiptSettingsPageState();
}

class _ReceiptSettingsPageState extends State<ReceiptSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _shopNameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _footerCtrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _shopNameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _footerCtrl = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _addressCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final s = await PrinterService().getReceiptSettings();
    if (mounted) {
      setState(() {
        _shopNameCtrl.text = s['shopName'] ?? '';
        _addressCtrl.text = s['address'] ?? '';
        _footerCtrl.text = s['footer'] ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await PrinterService().saveReceiptSettings(shopName: _shopNameCtrl.text, address: _addressCtrl.text, footer: _footerCtrl.text);
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pengaturan Disimpan"), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: false, // MANDATORY
      appBar: AppBar(
        title: const Text("Pengaturan Struk", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.defaultGradient)),
        elevation: 0,
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _ReceiptPreviewCard(shopNameCtrl: _shopNameCtrl, addressCtrl: _addressCtrl, footerCtrl: _footerCtrl),
                  const SizedBox(height: 25),
                  const Text("Kustomisasi Teks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  const SizedBox(height: 15),
                  _SettingsField(controller: _shopNameCtrl, label: "Nama Toko", icon: Icons.store),
                  const SizedBox(height: 15),
                  _SettingsField(controller: _addressCtrl, label: "Alamat", icon: Icons.location_on, maxLines: 2),
                  const SizedBox(height: 15),
                  _SettingsField(controller: _footerCtrl, label: "Footer", icon: Icons.notes, maxLines: 2),
                  const SizedBox(height: 30),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _saveSettings, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("SIMPAN PENGATURAN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)))),
                  const KeyboardSpacer(),
                ]),
              ),
            ),
    );
  }
}

class _ReceiptPreviewCard extends StatelessWidget {
  final TextEditingController shopNameCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController footerCtrl;
  const _ReceiptPreviewCard({required this.shopNameCtrl, required this.addressCtrl, required this.footerCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))], border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: [
        const Text("PREVIEW STRUK", style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1.5)),
        const SizedBox(height: 15),
        ListenableBuilder(
          listenable: Listenable.merge([shopNameCtrl, addressCtrl, footerCtrl]),
          builder: (context, _) => Container(
            padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFFFFFDF0), border: Border.all(color: Colors.grey.shade300)),
            child: Column(children: [
              Text(shopNameCtrl.text.isEmpty ? "NAMA TOKO" : shopNameCtrl.text.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Courier'), textAlign: TextAlign.center),
              const SizedBox(height: 5),
              Text(addressCtrl.text.isEmpty ? "Alamat Toko..." : addressCtrl.text, style: const TextStyle(fontSize: 12, fontFamily: 'Courier'), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              const Divider(color: Colors.black54, thickness: 1, height: 10),
              const _ReceiptSimulationRow(label: "Item 1", value: "10.000"),
              const _ReceiptSimulationRow(label: "Item 2", value: "20.000"),
              const Divider(color: Colors.black54, thickness: 1, height: 10),
              const _ReceiptSimulationRow(label: "TOTAL", value: "30.000", isBold: true),
              const SizedBox(height: 15),
              Text(footerCtrl.text.isEmpty ? "Terima Kasih" : footerCtrl.text, style: const TextStyle(fontSize: 12, fontFamily: 'Courier'), textAlign: TextAlign.center),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ReceiptSimulationRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  const _ReceiptSimulationRow({required this.label, required this.value, this.isBold = false});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontFamily: 'Courier', fontSize: isBold ? 14 : 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)), Text(value, style: TextStyle(fontFamily: 'Courier', fontSize: isBold ? 14 : 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal))]);
  }
}

class _SettingsField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  const _SettingsField({required this.controller, required this.label, required this.icon, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller, maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppTheme.primaryColor), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );
  }
}
