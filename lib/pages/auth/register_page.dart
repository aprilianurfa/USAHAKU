import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

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
        // Registration Successful - Now Auto Login
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun Usahaku'),
        backgroundColor: const Color(0xFF0A3D62),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 10),
                
                // NAMA USAHA
                TextFormField(
                  controller: namaUsahaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Usaha',
                    prefixIcon: Icon(Icons.store),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Nama usaha wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // NAMA PEMILIK
                TextFormField(
                  controller: namaPemilikController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Pemilik',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Nama pemilik wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // EMAIL
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Email wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // PASSWORD
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.length < 6) ? 'Password minimal 6 karakter' : null,
                ),
                const SizedBox(height: 28),

                // REGISTER BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A3D62),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Daftar Akun'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}