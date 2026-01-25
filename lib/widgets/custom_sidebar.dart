import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../core/theme.dart';
import '../config/constants.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/purchase_provider.dart';
import '../core/route_awareness.dart';

class CustomSidebar extends StatefulWidget {
  final ValueNotifier<bool> isOpen;
  const CustomSidebar({super.key, required this.isOpen});

  @override
  State<CustomSidebar> createState() => _CustomSidebarState();
}

class _CustomSidebarState extends State<CustomSidebar> {
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
      context.read<ProductProvider>().resetState();
      context.read<DashboardProvider>().resetState();
      context.read<PurchaseProvider>().resetState();
      UsahakuApp.navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = 280.0;
    
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isOpen,
      builder: (context, open, _) {
        return FocusTraversalGroup(
          child: Stack(
            children: [
              if (open)
                GestureDetector(
                  onTap: () => widget.isOpen.value = false,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, val, child) => Container(color: Colors.black.withValues(alpha: 0.4 * val)),
                  ),
                ),
              
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuart,
                left: open ? 0 : -sidebarWidth,
                top: 0, bottom: 0, width: sidebarWidth,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(5, 0))],
                  ),
                  child: Column(children: [
                    _buildHeader(),
                    Expanded(child: _buildMenuList()),
                    _buildFooter(),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: () {
        widget.isOpen.value = false;
        UsahakuApp.navigatorKey.currentState?.pushReplacementNamed('/profile');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
        decoration: const BoxDecoration(
          gradient: AppTheme.defaultGradient,
          borderRadius: BorderRadius.only(topRight: Radius.circular(30)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white38, width: 2)),
            child: CircleAvatar(
              radius: 35, backgroundColor: Colors.white,
              backgroundImage: _shopLogo != null ? NetworkImage("${AppConstants.imageBaseUrl}$_shopLogo") : null,
              child: _shopLogo == null ? const Icon(Icons.person_rounded, color: AppTheme.primaryColor, size: 35) : null,
            ),
          ),
          const SizedBox(height: 20),
          Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(_role == 'owner' ? 'Administrator' : 'Staff Kasir', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  Widget _buildMenuList() {
    return ListenableBuilder(
      listenable: RouteAwareness(),
      builder: (context, _) {
        final currentRoute = RouteAwareness().currentRoute;
        
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          physics: const BouncingScrollPhysics(),
          children: [
            _sectionLabel("UTAMA"),
            _menuTile(Icons.dashboard_rounded, "Dashboard", "/dashboard", currentRoute == '/dashboard'),
            
            const SizedBox(height: 10),
            _sectionLabel("OPERASIONAL"),
            if (_role == 'owner') ...[
              _menuTile(Icons.inventory_2_outlined, "Inventori Barang", "/product", currentRoute == '/product'),
              _menuTile(Icons.category_outlined, "Manajemen Kategori", "/category", currentRoute == '/category'),
              _menuTile(Icons.shopping_bag_outlined, "Data Pembelian", "/purchase", currentRoute == '/purchase'),
            ],
            _menuTile(Icons.point_of_sale_rounded, "Kasir (POS)", "/transaction", currentRoute == '/transaction'),
            _menuTile(Icons.receipt_long_outlined, "Riwayat Transaksi", "/transaction-history", currentRoute == '/transaction-history'),
            
            const SizedBox(height: 10),
            _sectionLabel("LAINNYA"),
            _menuTile(Icons.insert_chart_outlined_rounded, "Laporan Analistik", "/report", currentRoute == '/report'),
            _menuTile(Icons.person_outline_rounded, "Profil Saya", "/profile", currentRoute == '/profile'),
          ],
        );
      }
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Text(text, style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)));
  }

  Widget _menuTile(IconData icon, String title, String route, bool active) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Icon(icon, color: active ? AppTheme.primaryColor : Colors.grey.shade600, size: 24),
        title: Text(title, style: TextStyle(fontWeight: active ? FontWeight.bold : FontWeight.w500, color: active ? AppTheme.primaryColor : Colors.black87, fontSize: 14)),
        selected: active,
        selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        onTap: () {
          if (!active) {
            UsahakuApp.navigatorKey.currentState?.pushReplacementNamed(route);
          }
          // Close concurrently for smooth animation
          widget.isOpen.value = false;
        },
        dense: true,
        visualDensity: const VisualDensity(vertical: 2),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(15)),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.power_settings_new_rounded, color: Colors.red, size: 20),
            SizedBox(width: 12),
            Text("Keluar Sesi", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
        ),
      ),
    );
  }
}
