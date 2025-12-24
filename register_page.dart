import 'package:flutter/material.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color primaryBlue = Color(0xFF4DA3FF);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color borderSoft = Color(0xFF8EC5B8);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController referralController = TextEditingController();

  bool agree = false;

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: primaryBlue),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    referralController.dispose();
    super.dispose();
  }

  void _submitRegister() {
    if (!agree) return;

    debugPrint("Nama: ${nameController.text}");
    debugPrint("Email: ${emailController.text}");
    debugPrint("Password: ${passwordController.text}");
    debugPrint("Telepon: ${phoneController.text}");
    debugPrint("Referral: ${referralController.text}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Daftar",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),

            /// ================= CARD REGISTER =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: borderSoft, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    "Daftar Manual",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: nameController,
                    decoration: _inputDecoration("Nama"),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration("Email"),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _inputDecoration("Password"),
                  ),
                  const SizedBox(height: 14),

                  /// NOMOR TELEPON
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Row(
                          children: [
                            Text("🇮🇩"),
                            SizedBox(width: 6),
                            Text("+62"),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration:
                              _inputDecoration("Nomor Telepon"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: referralController,
                    decoration:
                        _inputDecoration("Kode Referral (jika ada)"),
                  ),

                  const SizedBox(height: 20),

                  /// BUTTON DAFTAR
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: agree ? _submitRegister : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: agree
                            ? primaryBlue
                            : Colors.grey.shade300,
                        disabledBackgroundColor:
                            Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Buat Akun",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// CHECKBOX
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: agree,
                        activeColor: primaryBlue,
                        onChanged: (val) {
                          setState(() => agree = val ?? false);
                        },
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text.rich(
                            TextSpan(
                              text:
                                  "Dengan mendaftar, kamu menyetujui ",
                              style: const TextStyle(fontSize: 12),
                              children: [
                                TextSpan(
                                  text:
                                      "Syarat Ketentuan & Kebijakan Privasi",
                                  style: TextStyle(
                                    color: accentBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// ================= GOOGLE LOGIN =================
            const Text(
              "Atau login langsung melalui",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Image.network(
                  "https://upload.wikimedia.org/wikipedia/commons/0/09/IOS_Google_icon.png",
                  width: 28,
                  height: 28,
                ),
              ),
            ),

            const SizedBox(height: 28),

            /// ================= MASUK =================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Sudah punya akun? "),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(),
                      ),
                    );
                  },
                  child: Text(
                    "Masuk disini",
                    style: TextStyle(
                      color: accentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
