import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _role = 'kasir'; // Default fallback
  String _userName = 'User';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  void _loadUserRole() async {
    final role = await _authService.getRole();
    final name = await _authService.getUserName();
    if (mounted) {
      setState(() {
        _role = role ?? 'kasir';
        _userName = name ?? 'User';
      });
    }
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      // Navigate to login and remove all previous routes
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
    }

  @override
  Widget build(BuildContext context) {
    bool isOwner = _role == 'owner';

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF0A3D62),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store, color: Colors.white, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    'Halo, $_userName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isOwner ? 'Pemilik Toko' : 'Staff Kasir',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          _drawerItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            route: '/dashboard',
          ),
          
          if (isOwner) ...[
            _drawerItem(
              context,
              icon: Icons.inventory,
              title: 'Manajemen Barang',
              route: '/product',
            ),
            _drawerItem(
              context,
              icon: Icons.category,
              title: 'Kategori Barang',
              route: '/category',
            ),
             _drawerItem(
              context,
              icon: Icons.shopping_cart,
              title: 'Pembelian Barang',
              route: '/purchase',
            ),
          ],

          _drawerItem(
            context,
            icon: Icons.point_of_sale,
            title: 'Transaksi',
            route: '/transaction',
          ),
          _drawerItem(
            context,
            icon: Icons.receipt_long,
            title: 'Riwayat Transaksi',
            route: '/transaction-history',
          ),

          if (isOwner) ...[
            _drawerItem(
              context,
              icon: Icons.bar_chart,
              title: 'Laporan',
              route: '/report',
            ),
           _drawerItem(
              context,
              icon: Icons.people,
              title: 'Karyawan',
              route: '/employee-list', // Asumsi route ini ada, jika tidak bisa ke profile dulu
            ),
          ],

          const Divider(),
          _drawerItemLogout(context),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0A3D62)),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }

  Widget _drawerItemLogout(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text("Logout", style: TextStyle(color: Colors.red)),
      onTap: () {
        Navigator.pop(context);
         _logout();
      },
    );
  }
}
