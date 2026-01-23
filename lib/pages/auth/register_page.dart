import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController namaUsahaController = TextEditingController();
  final TextEditingController namaPemilikController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await _authService.register(
        namaUsahaController.text,
        namaPemilikController.text,
        emailController.text,
        passwordController.text,
      );

      // Don't set loading to false yet if success, we want to proceed to login
      
      if (!mounted) return;

      if (result != null && (result['message'] != null || result['userId'] != null || result['id'] != null)) {
        
        // NEW: Check if token is directly returned (Auto Login V2)
        if (result['token'] != null) {
             // SAVE SESSION DATA MANUALLY
             final token = result['token'];
             final user = result['user'];
             
             await _authService.saveSessionManual(
               token: token,
               role: user != null && user['role'] != null ? user['role'] : 'owner', // Fallback to owner
               name: user != null ? user['nama'] : null,
               shopId: user != null && user['shop_id'] != null ? user['shop_id'].toString() : null,
               shopName: user != null ? user['shop_name'] : null,
               shopLogo: user != null ? user['shop_logo'] : null,
             );

             setState(() => _isLoading = false);
             if (!mounted) return;
             
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Registrasi Berhasil! Selamat Datang Owner.'), backgroundColor: Colors.green),
             );
             
             Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
             return;
        }

        // Registration Successful - Legacy Fallback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil, sedang login...'), backgroundColor: Colors.green),
        );

        final loginResult = await _authService.login(emailController.text, passwordController.text);
        
        setState(() => _isLoading = false); // Stop loading now

        if (!mounted) return;

        if (loginResult != null && loginResult['token'] != null) {
          // Auto Login Success
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        } else {
          // Auto Login Failed
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Login otomatis gagal: ${loginResult?['error']}'), backgroundColor: Colors.orange),
           );
           Navigator.pop(context); // Go back to login page
        }

      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Registrasi gagal. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Custom Header
            Stack(
              children: [
                Container(
                  height: size.height * 0.35, // Slightly shorter than login
                  decoration: const BoxDecoration(
                    gradient: AppTheme.defaultGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Daftar Akun',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Mulai kelola usahamu hari ini',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Floating Card Form
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // NAMA USAHA
                      TextFormField(
                        controller: namaUsahaController,
                        decoration: InputDecoration(
                          labelText: 'Nama Usaha',
                          prefixIcon: const Icon(Icons.store_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryColor),
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? 'Nama usaha wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      // NAMA PEMILIK
                      TextFormField(
                        controller: namaPemilikController,
                        decoration: InputDecoration(
                          labelText: 'Nama Pemilik',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryColor),
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? 'Nama pemilik wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      // EMAIL
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                           enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryColor),
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? 'Email wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      // PASSWORD
                      TextFormField(
                        controller: passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                           suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                           enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryColor),
                          ),
                        ),
                        validator: (value) => (value == null || value.length < 6) ? 'Password minimal 6 karakter' : null,
                      ),
                      const SizedBox(height: 28),

                      // REGISTER BUTTON
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: AppTheme.defaultGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading 
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              )
                            : const Text(
                                'DAFTAR SEKARANG',
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Back to Login
             Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sudah punya akun?',
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Login Disini',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}