import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../config/constants.dart';
import '../../core/widgets/keyboard_spacer.dart';
import 'package:usahaku_main/core/view_metrics.dart';
import 'package:usahaku_main/core/app_shell.dart';
import '../settings/employee_list_page.dart';
import 'security_page.dart';
import 'help_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  UserModel? _user;
  String? _shopLogo;

  @override
  void initState() {
    super.initState();
    _loadCachedProfile();
    _fetchProfile();
  }

  Future<void> _loadCachedProfile() async {
    final results = await Future.wait([
      _authService.getUserName(),
      _authService.getUserEmail(),
      _authService.getRole(),
      _authService.getShopId(),
      _authService.getUserId(),
      _authService.getShopLogo(),
    ]);

    if (results[0] != null && mounted) {
      setState(() {
        _user = UserModel(
          id: int.tryParse(results[4] ?? '0') ?? 0,
          nama: results[0] as String,
          email: results[1] as String? ?? "",
          role: results[2] as String?,
          shopId: int.tryParse(results[3] ?? ''),
        );
        _shopLogo = results[5] as String?;
        _isLoading = false;
      });
    }
  }

  void _fetchProfile() async {
    final data = await _authService.getProfile();
    if (data is Map<String, dynamic> && data['error'] == null && mounted) {
      setState(() {
        _user = UserModel.fromJson(data);
        if (data['Shop'] != null && data['Shop'] is Map && data['Shop']['logo'] != null) {
          _shopLogo = data['Shop']['logo'];
        }
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      setState(() => _isLoading = true);
      await _authService.uploadShopLogo(image.path);
      _fetchProfile();
    }
  }

  void _showEditProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileSheet(
        user: _user,
        logo: _shopLogo,
        onPickImage: _pickImage,
        onSaved: _fetchProfile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: false, // MANDATORY
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => AppShell.of(context).toggleSidebar(),
        ),
        title: const Text("Profil Saya", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.defaultGradient)),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _user == null ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        child: Column(
          children: [
            _ProfileHeader(user: _user, logo: _shopLogo, isLoading: _isLoading),
            const SizedBox(height: 60), 
            _ProfileMenu(user: _user, onEdit: _showEditProfileSheet),
            const SizedBox(height: 30),
            _LogoutButton(onLogout: _logout),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false), child: const Text('Ya', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel? user;
  final String? logo;
  final bool isLoading;
  const _ProfileHeader({this.user, this.logo, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 250, width: double.infinity,
          decoration: const BoxDecoration(gradient: AppTheme.defaultGradient, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
          child: Column(children: [
            const SizedBox(height: 10),
            Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: CircleAvatar(radius: 50, backgroundColor: Colors.grey.shade200, 
                  backgroundImage: logo != null ? NetworkImage("${AppConstants.imageBaseUrl}$logo") : null,
                  child: isLoading ? const CircularProgressIndicator() : (logo == null ? Text(user?.nama.isNotEmpty == true ? user!.nama[0].toUpperCase() : "U", style: const TextStyle(fontSize: 40, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)) : null),
              ),
            ),
            const SizedBox(height: 12),
            Text(user?.nama ?? "", style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(user?.email ?? "", style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ]),
        ),
        Positioned(
          bottom: -40, left: 24, right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(20), 
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
              border: Border.all(color: Colors.white.withValues(alpha: 0.2))
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _InfoItem(title: "Status Akun", value: user?.role == 'owner' ? "Owner" : "Karyawan"),
              Container(height: 30, width: 1, color: Colors.grey.shade300),
              const _InfoItem(title: "Bergabung", value: "Jan 2026"),
            ]),
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String title;
  final String value;
  const _InfoItem({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
    ]);
  }
}

class _ProfileMenu extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onEdit;
  const _ProfileMenu({this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        _MenuTile("Edit Profil", Icons.person_outline, onTap: onEdit),
        if (user?.role == 'owner') ...[
          const Divider(height: 1, indent: 20, endIndent: 20),
          _MenuTile("Daftar Karyawan", Icons.groups_outlined, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeListPage()))),
        ],
        const Divider(height: 1, indent: 20, endIndent: 20),
        _MenuTile("Keamanan", Icons.lock_outline, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityPage()))),
        const Divider(height: 1, indent: 20, endIndent: 20),
        _MenuTile("Bantuan & Dukungan", Icons.help_outline, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpPage()))),
      ]),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  const _MenuTile(this.title, this.icon, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppTheme.primaryColor, size: 22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;
  const _LogoutButton({required this.onLogout});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextButton(onPressed: onLogout, style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: const Color(0xFFFFECEC), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 10), Text("Keluar Aplikasi", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16))]),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final UserModel? user;
  final String? logo;
  final VoidCallback onPickImage;
  final VoidCallback onSaved;
  const _EditProfileSheet({this.user, this.logo, required this.onPickImage, required this.onSaved});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.user?.nama);
    emailCtrl = TextEditingController(text: widget.user?.email);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      padding: const EdgeInsets.all(25),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 20),
          const Text("Edit Profil", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const SizedBox(height: 20),
          Center(
            child: Stack(alignment: Alignment.bottomRight, children: [
              CircleAvatar(radius: 50, backgroundColor: Colors.grey.shade200, backgroundImage: widget.logo != null ? NetworkImage("${AppConstants.imageBaseUrl}${widget.logo}") : null,
                child: widget.logo == null ? Text(widget.user?.nama.isNotEmpty == true ? widget.user!.nama[0].toUpperCase() : "U", style: const TextStyle(fontSize: 40, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)) : null,
              ),
              InkWell(onTap: widget.onPickImage, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 20))),
            ]),
          ),
          const SizedBox(height: 30),
          _EditField(label: "Nama Lengkap", controller: nameCtrl, icon: Icons.person_outline),
          const SizedBox(height: 16),
          _EditField(label: "Email", controller: emailCtrl, icon: Icons.email_outlined),
          const SizedBox(height: 30),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Batal", style: TextStyle(color: Colors.black)))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(onPressed: _isSaving ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Simpan", style: TextStyle(fontWeight: FontWeight.bold)))),
          ]),
          KeyboardSpacer(extraPadding: 40),
        ]),
      ),
    );
  }

  void _save() async {
    setState(() => _isSaving = true);
    final res = await AuthService().updateProfile(nameCtrl.text, emailCtrl.text);
    if (mounted) {
       setState(() => _isSaving = false);
       if (res != null && res['error'] == null) {
          widget.onSaved();
          Navigator.pop(context);
       }
    }
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  const _EditField({required this.label, required this.controller, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(controller: controller, decoration: InputDecoration(prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
    ]);
  }
}
