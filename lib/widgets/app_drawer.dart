import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF0A3D62),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.store, color: Colors.white, size: 40),
                SizedBox(height: 10),
                Text(
                  'USAHAKU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Smart POS System',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          _drawerItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            route: '/dashboard',
          ),
          _drawerItem(
            context,
            icon: Icons.inventory,
            title: 'Manajemen Barang',
            route: '/barang',
          ),
          _drawerItem(
            context,
            icon: Icons.category,
            title: 'Kategori Barang',
            route: '/kategori',
          ),
          _drawerItem(
            context,
            icon: Icons.shopping_cart,
            title: 'Pembelian Barang',
            route: '/pembelian',
          ),
          _drawerItem(
            context,
            icon: Icons.point_of_sale,
            title: 'Transaksi',
            route: '/transaksi',
          ),
          _drawerItem(
            context,
            icon: Icons.receipt_long,
            title: 'Riwayat Transaksi',
            route: '/riwayat-transaksi',
          ),
          _drawerItem(
            context,
            icon: Icons.bar_chart,
            title: 'Laporan',
            route: '/laporan',
          ),
          const Divider(),
          _drawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            route: '/login',
            replace: true,
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool replace = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0A3D62)),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        replace
            ? Navigator.pushReplacementNamed(context, route)
            : Navigator.pushNamed(context, route);
      },
    );
  }
}
