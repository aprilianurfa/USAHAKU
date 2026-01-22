import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../core/theme.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  Future<void> _launchWA() async {
    const url = "https://wa.me/6285861906412"; // Updated Number
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'mprhanqu@gmail.com',
      queryParameters: {'subject': 'Bantuan Aplikasi Usahaku'},
    );
    if (await canLaunchUrlString(emailLaunchUri.toString())) {
      await launchUrlString(emailLaunchUri.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Bantuan & Dukungan", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.defaultGradient,
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Contact Support Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  Image.network(
                    "https://img.icons8.com/clouds/200/headset.png", // Use a placeholder or asset if available
                    height: 100,
                    errorBuilder: (_, __, ___) => const Icon(Icons.support_agent_rounded, size: 80, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Butuh Bantuan?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tim support kami siap membantu Anda 24/7 jika mengalami kendala.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _launchWA,
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text("WhatsApp"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _launchEmail,
                          icon: const Icon(Icons.email, size: 18),
                          label: const Text("Email"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            // FAQ
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Pertanyaan Umum (FAQ)", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),

            _buildFaqItem("Bagaimana cara mengubah profil?", "Anda dapat mengubah nama dan email melalui menu Edit Profil di halaman Profil."),
            _buildFaqItem("Bagaimana jika lupa password?", "Hubungi admin atau tim support kami untuk melakukan reset password akun Anda."),
            _buildFaqItem("Apakah data saya aman?", "Ya, data Anda disimpan dengan enkripsi standar industri dan backup berkala."),
             _buildFaqItem("Cara menambah karyawan?", "Hanya akun Owner yang dapat menambah karyawan melalui menu Daftar Karyawan."),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(answer, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
