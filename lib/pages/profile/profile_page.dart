import 'package:flutter/material.dart';
import 'dart:ui'; // For BackdropFilter
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../settings/employee_list_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  UserModel? _user;
  
  // Custom Colors
  // final Color _royalBlue = const Color(0xFF1A46BE); // Removed hardcoded
  final Color _bgGrey = const Color(0xFFF8F9FE);

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  void _fetchProfile() async {
    setState(() => _isLoading = true);
    final data = await _authService.getProfile();
    if (data != null && data['error'] == null) {
      if (mounted) {
        setState(() {
          _user = UserModel.fromJson(data);
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        // Fallback dummy data if API fails (for testing UI)
        setState(() {
          // _user = UserModel(id: 1, nama: "Demo User", email: "demo@usahaku.com", role: "owner", shopId: 1); // Uncomment to test without API
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(data?['error'] ?? 'Gagal memuat profil')),
        );
      }
    }
  }

  void _logout() async {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: _user?.nama);
    final emailCtrl = TextEditingController(text: _user?.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Edit Profil",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            
            // Nama Input
            const Text("Nama Lengkap", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline),
                hintText: "Masukkan nama Anda",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Email Input
            const Text("Email", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
            const SizedBox(height: 8),
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_outlined),
                hintText: "email@contoh.com",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Batal", style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final result = await _authService.updateProfile(nameCtrl.text, emailCtrl.text);
                      if (result != null && result['error'] == null) {
                        _fetchProfile();
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil diperbarui")));
                      } else {
                         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result?['error'] ?? "Gagal update")));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Simpan Perubahan", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 60), 
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 50),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _buildMenuList(),
              const SizedBox(height: 30),
              _buildLogoutButton(),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 310,  // Increased from 280 to prevent overflow
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Standardized Back Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    child: _isLoading 
                      ? _skeletonBox(40, 40, radius: 20, isDark: false)
                      : Text(
                          _user?.nama != null && _user!.nama.isNotEmpty ? _user!.nama[0].toUpperCase() : "U",
                          style: TextStyle(fontSize: 40, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                _isLoading
                  ? _skeletonBox(150, 24, radius: 12, isDark: false)
                  : Text(
                      _user?.nama ?? "",
                      style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                const SizedBox(height: 8),
                _isLoading
                  ? _skeletonBox(180, 16, radius: 8, isDark: false)
                  : Text(
                      _user?.email ?? "",
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
              ],
            ),
          ),
        ),

        Positioned(
          bottom: -40,
          left: 24,
          right: 24,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoItem("Status Akun", _user?.role == 'owner' ? "Owner" : "Karyawan"),
                    Container(height: 30, width: 1, color: Colors.grey.shade300),
                    _buildInfoItem("Bergabung", "Jan 2026"),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        _isLoading
          ? _skeletonBox(80, 18, radius: 6)
          : Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
      ],
    );
  }

  Widget _buildMenuList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _menuTile("Edit Profil", Icons.person_outline, onTap: _showEditProfileSheet),
          const Divider(height: 1, indent: 20, endIndent: 20),
          
          if (_user?.role == 'owner') ...[
            _menuTile("Daftar Karyawan", Icons.groups_outlined, onTap: () {
              // Hapus 'const' di sini karena EmployeeListPage mungkin tidak const atau kita ingin fleksibel
              Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeListPage()));
            }),
            const Divider(height: 1, indent: 20, endIndent: 20),
          ],

          _menuTile("Keamanan", Icons.lock_outline, onTap: () {}),
           const Divider(height: 1, indent: 20, endIndent: 20),
          _menuTile("Metode Pembayaran", Icons.payments_outlined, onTap: () {}),
           const Divider(height: 1, indent: 20, endIndent: 20),
          _menuTile("Bantuan & Dukungan", Icons.help_outline, onTap: () {}),
        ],
      ),
    );
  }

  Widget _menuTile(String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextButton(
        onPressed: _logout,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFFFFECEC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text("Keluar Aplikasi", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _skeletonBox(double width, double height, {double radius = 8, bool isDark = true}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 0.6),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade300 : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      },
    );
  }
}
