import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../core/theme.dart';
import '../config/constants.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _role = 'kasir';
  String _userName = 'User';
  String? _shopLogo;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final role = await _authService.getRole();
    final name = await _authService.getUserName();
    final shopLogo = await _authService.getShopLogo();
    if (mounted) {
      setState(() {
        _role = role ?? 'kasir';
        _userName = name ?? 'User';
        _shopLogo = shopLogo;
      });
    }
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOwner = _role == 'owner';
    // Get current route to highlight active item (optional, basic checking)
    String? currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              children: [
                _buildSectionHeader("MENU UTAMA"),
                _drawerItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  route: '/dashboard',
                  isActive: currentRoute == '/dashboard',
                ),

                if (isOwner) ...[
                  const SizedBox(height: 15),
                  _buildSectionHeader("MANAJEMEN STOK"),
                  _drawerItem(
                    context,
                    icon: Icons.inventory_2_rounded,
                    title: 'Daftar Barang',
                    route: '/product',
                    isActive: currentRoute == '/product',
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.category_rounded,
                    title: 'Kategori',
                    route: '/category',
                    isActive: currentRoute == '/category',
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.shopping_bag_rounded,
                    title: 'Pembelian',
                    route: '/purchase',
                    isActive: currentRoute == '/purchase',
                  ),
                ],

                const SizedBox(height: 15),
                _buildSectionHeader("TRANSAKSI"),
                _drawerItem(
                  context,
                  icon: Icons.point_of_sale_rounded,
                  title: 'Kasir',
                  route: '/transaction',
                  isActive: currentRoute == '/transaction',
                ),
                _drawerItem(
                  context,
                  icon: Icons.receipt_long_rounded,
                  title: 'Riwayat',
                  route: '/transaction-history',
                  isActive: currentRoute == '/transaction-history',
                ),

                if (isOwner) ...[
                  const SizedBox(height: 15),
                  _buildSectionHeader("LAPORAN & ADMIN"),
                  _drawerItem(
                    context,
                    icon: Icons.analytics_rounded,
                    title: 'Laporan',
                    route: '/report',
                    isActive: currentRoute == '/report',
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.people_rounded,
                    title: 'Karyawan',
                    route: '/employee-list',
                    isActive: currentRoute == '/employee-list',
                  ),
                ],
              ],
            ),
          ),
          
          const Divider(height: 1),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A3D62), Color(0xFF1E3A8A)], // Gradient matching Theme
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context); // Close drawer
            Navigator.pushNamed(context, '/profile');
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: _shopLogo != null 
                        ? NetworkImage("${AppConstants.imageBaseUrl}$_shopLogo")
                        : null,
                    child: _shopLogo == null 
                      ? Text(
                          _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _role == 'owner' ? 'Pemilik Toko' : 'Staff Kasir',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon, 
          color: isActive ? AppTheme.primaryColor : Colors.grey.shade600,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppTheme.primaryColor : Colors.black87,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          if (!isActive) {
            Navigator.pop(context); // Close drawer first
            Navigator.pushReplacementNamed(context, route); // Use pushReplacement for drawer nav usually better, or keep pushNamed if retaining stack
          } else {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Semua data sesi akan dihapus. Anda yakin ingin keluar?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close Dialog
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.pop(context);
              _confirmLogout();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Keluar Aplikasi",
                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Ver 1.0.0 • by Usahaku",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
