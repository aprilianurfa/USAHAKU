import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../config/constants.dart';
import '../../services/product_service.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/product_provider.dart';
import '../../core/view_metrics.dart';
import '../../core/app_shell.dart';
import '../shift/open_shift_page.dart';
import '../shift/close_shift_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardProvider>().refreshDashboard();
        context.read<ProductProvider>().loadProducts(); // Pre-load products for alerts
      }
    });
  }

  bool _isDialogShowing = false;

  void _showNotificationDialog() {
    if (_isDialogShowing) return;
    
    final prodProv = context.read<ProductProvider>();
    final items = prodProv.lowStockProducts;
    
    _isDialogShowing = true;
    showDialog(context: context, builder: (ctx) => _LowStockDialog(items: items))
      .then((_) => _isDialogShowing = false);
  }

  void _navigateToOpenShift() async {
    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const OpenShiftPage()));
    if (res == true && mounted) context.read<DashboardProvider>().refreshDashboard();
  }

  void _navigateToCloseShift() async {
    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CloseShiftPage()));
    if (res == true && mounted) context.read<DashboardProvider>().refreshDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashProvider, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          resizeToAvoidBottomInset: false, // MANDATORY
          body: dashProvider.isLoading && dashProvider.summary == null ? const _DashboardLoadingSkeleton()
              : RefreshIndicator(
                  onRefresh: () => dashProvider.refreshDashboard(),
                  child: ListView( // Replaced SingleChildScrollView for better physics
                    padding: EdgeInsets.zero,
                    children: [
                      _DashboardHeaderStack(
                        dashProvider: dashProvider,
                        onNotify: _showNotificationDialog,
                        onOpenShift: _navigateToOpenShift,
                        onCloseShift: _navigateToCloseShift,
                      ),
                      const SizedBox(height: 10),
                      if (!dashProvider.isShiftOpen) _ShiftAlert(onOpen: _navigateToOpenShift),
                      _ManagementSection(isOwner: dashProvider.role == 'owner'),
                      _OperationalSection(isShiftOpen: dashProvider.isShiftOpen),
                      if (dashProvider.role == 'owner') const _AnalyticSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _DashboardHeaderStack extends StatelessWidget {
  final DashboardProvider dashProvider;
  final VoidCallback onNotify;
  final VoidCallback onOpenShift;
  final VoidCallback onCloseShift;
  const _DashboardHeaderStack({required this.dashProvider, required this.onNotify, required this.onOpenShift, required this.onCloseShift});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(top: 0, left: 0, right: 0, height: 300, child: _HeaderBackground(dashProvider: dashProvider, onNotify: onNotify, onOpenShift: onOpenShift, onCloseShift: onCloseShift)),
        Positioned(top: 150, left: 20, right: 20, child: _SummaryCard(dashProvider: dashProvider, onNotify: onNotify, onOpenShift: onOpenShift, onCloseShift: onCloseShift)),
      ]),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  final DashboardProvider dashProvider;
  final VoidCallback onNotify;
  final VoidCallback onOpenShift;
  final VoidCallback onCloseShift;
  const _HeaderBackground({required this.dashProvider, required this.onNotify, required this.onOpenShift, required this.onCloseShift});

  @override
  Widget build(BuildContext context) {
    final topPadding = getViewportTopPadding(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.defaultGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      padding: EdgeInsets.fromLTRB(24, topPadding + 20, 24, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ShopLogo(logo: dashProvider.shopLogo),
                    const SizedBox(width: 16),
                    _ShopInfo(name: dashProvider.shopName, isOwner: dashProvider.role == 'owner'),
                    const SizedBox(width: 16), // Maintain gap to Expand
                  ],
                ),
              ),
              const Spacer(),
              _ShiftButton(isOpen: dashProvider.isShiftOpen, onTap: dashProvider.isShiftOpen ? onCloseShift : onOpenShift),
              const SizedBox(width: 8),
              _NotificationButton(isOwner: dashProvider.role == 'owner', hasAlert: dashProvider.lowStockCount > 0, onTap: onNotify),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopLogo extends StatelessWidget {
  final String? logo;
  const _ShopLogo({this.logo});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2)),
      child: CircleAvatar(
        radius: 28, backgroundColor: Colors.white,
        backgroundImage: logo != null ? NetworkImage("${AppConstants.imageBaseUrl}$logo") : null,
        child: logo == null ? const Icon(Icons.person_rounded, size: 32, color: AppTheme.primaryColor) : null,
      ),
    );
  }
}

class _ShopInfo extends StatelessWidget {
  final String name;
  final bool isOwner;
  const _ShopInfo({required this.name, required this.isOwner});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(isOwner ? "Owner (Premium)" : "Staff Kasir", style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _ShiftButton extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;
  const _ShiftButton({required this.isOpen, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: isOpen ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(12),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(isOpen ? Icons.check_circle : Icons.lock_outline, size: 14, color: Colors.white), const SizedBox(width: 6), Text(isOpen ? "BUKA" : "TUTUP", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))])),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final bool isOwner;
  final bool hasAlert;
  final VoidCallback onTap;
  const _NotificationButton({required this.isOwner, required this.hasAlert, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.topRight, children: [
      IconButton(onPressed: isOwner ? onTap : null, icon: Icon(Icons.notifications_none_rounded, color: isOwner ? Colors.white : Colors.white24, size: 28)),
      if (isOwner && hasAlert) Positioned(right: 8, top: 8, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 10, minHeight: 10))),
    ]);
  }
}

class _SummaryCard extends StatelessWidget {
  final DashboardProvider dashProvider;
  final VoidCallback onNotify;
  final VoidCallback onOpenShift;
  final VoidCallback onCloseShift;
  const _SummaryCard({required this.dashProvider, required this.onNotify, required this.onOpenShift, required this.onCloseShift});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final salesToday = dashProvider.summary?.salesToday.toDouble() ?? 0;
    final trxToday = dashProvider.summary?.trxCountToday ?? 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Expanded(child: _SummaryBox(title: "Penjualan", value: currency.format(salesToday), sub: "$trxToday Transaksi", icon: Icons.trending_up, color: Colors.greenAccent, onTap: () => Navigator.pushNamed(context, '/report-sales'))),
        Container(width: 1, height: 40, color: Colors.white24),
        if (dashProvider.role == 'owner')
          Expanded(child: _SummaryBox(title: "Low Stock", value: "${dashProvider.lowStockCount} Item", sub: "Perlu Restok", icon: Icons.inventory_2_outlined, isWarning: dashProvider.lowStockCount > 0, color: dashProvider.lowStockCount > 0 ? Colors.orangeAccent : Colors.white24, onTap: onNotify))
        else
          Expanded(child: _SummaryBox(title: "Kasir", value: dashProvider.isShiftOpen ? "BUKA" : "TUTUP", sub: dashProvider.isShiftOpen ? "Ready" : "Klik Buka", icon: Icons.point_of_sale_rounded, isWarning: !dashProvider.isShiftOpen, color: dashProvider.isShiftOpen ? Colors.blueAccent : Colors.redAccent, onTap: dashProvider.isShiftOpen ? onCloseShift : onOpenShift)),
      ]),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final String sub;
  final IconData icon;
  final bool isWarning;
  final Color color;
  final VoidCallback onTap;
  const _SummaryBox({required this.title, required this.value, required this.sub, required this.icon, this.isWarning = false, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap,
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 12, color: color.withValues(alpha: 0.8)), const SizedBox(width: 4), Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 5),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
        const SizedBox(height: 4),
        Text(sub, style: TextStyle(color: isWarning ? Colors.orangeAccent : Colors.white54, fontSize: 10, fontWeight: isWarning ? FontWeight.bold : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _ShiftAlert extends StatelessWidget {
  final VoidCallback onOpen;
  const _ShiftAlert({required this.onOpen});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade200)),
      child: Row(children: [
        const Icon(Icons.lock_clock_outlined, color: Colors.red, size: 30),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Kasir Belum Dibuka", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)), Text("Harap buka kasir untuk bertransaksi.", style: TextStyle(fontSize: 12, color: Colors.red))])),
        ElevatedButton(onPressed: onOpen, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("Buka")),
      ]),
    );
  }
}

class _ManagementSection extends StatelessWidget {
  final bool isOwner;
  const _ManagementSection({required this.isOwner});
  @override
  Widget build(BuildContext context) {
    if (!isOwner) return const SizedBox.shrink();
    return _SectionContainer(title: "Manajemen Stok", icon: Icons.inventory_2_rounded, children: [
      _MenuIcon(icon: Icons.inventory_rounded, label: "Barang", color: Colors.indigo, route: '/product'),
      _MenuIcon(icon: Icons.grid_view_rounded, label: "Kategori", color: Colors.blue.shade700, route: '/category'),
      _MenuIcon(icon: Icons.shopping_bag_rounded, label: "Pembelian", color: Colors.blue.shade500, route: '/purchase'),
    ]);
  }
}

class _OperationalSection extends StatelessWidget {
  final bool isShiftOpen;
  const _OperationalSection({required this.isShiftOpen});
  @override
  Widget build(BuildContext context) {
    return _SectionContainer(title: "Operasional Kasir", icon: Icons.point_of_sale_rounded, children: [
      _MenuIcon(icon: Icons.add_shopping_cart_rounded, label: "Transaksi", color: isShiftOpen ? Colors.orange.shade800 : Colors.grey, route: '/transaction', enabled: isShiftOpen),
      _MenuIcon(icon: Icons.receipt_long_rounded, label: "Riwayat", color: Colors.purple.shade700, route: '/transaction-history'),
      _MenuIcon(icon: Icons.print_rounded, label: "Printer", color: Colors.blue.shade600, route: '/printer-setting'),
    ]);
  }
}

class _AnalyticSection extends StatelessWidget {
  const _AnalyticSection();
  @override
  Widget build(BuildContext context) {
    return _SectionContainer(title: "Analitik & Laporan", icon: Icons.analytics_rounded, gridCount: 3, children: [
      _MenuIcon(icon: Icons.receipt_long_rounded, label: "Lap. Shift", color: Colors.blue.shade900, route: '/report-shift'),
      _MenuIcon(icon: Icons.trending_up_rounded, label: "Penjualan", color: Colors.green.shade700, route: '/report-sales'),
      _MenuIcon(icon: Icons.account_balance_wallet_rounded, label: "Laba Rugi", color: Colors.teal.shade700, route: '/report-profit-loss'),
      _MenuIcon(icon: Icons.assignment_rounded, label: "Lap. Beli", color: Colors.brown, route: '/report-purchase'),
      _MenuIcon(icon: Icons.savings_rounded, label: "Modal", color: Colors.deepOrange, route: '/report-capital'),
      _MenuIcon(icon: Icons.groups_rounded, label: "Pengunjung", color: Colors.cyan.shade800, route: '/report-visitor'),
    ]);
  }
}

class _SectionContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final int? gridCount;
  const _SectionContainer({required this.title, required this.icon, required this.children, this.gridCount});

  @override
  Widget build(BuildContext context) {
    final width = getViewportScreenWidth(context);
    int cross = gridCount ?? (width > 600 ? 4 : 3);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A2142))), Icon(icon, size: 20, color: Colors.blueGrey.shade300)]),
        const SizedBox(height: 22),
        GridView.count(shrinkWrap: true, padding: EdgeInsets.zero, physics: const NeverScrollableScrollPhysics(), crossAxisCount: cross, mainAxisSpacing: 22, crossAxisSpacing: 10, childAspectRatio: cross == 4 ? 0.8 : 0.95, children: children),
      ]),
    );
  }
}

class _MenuIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final bool enabled;
  const _MenuIcon({required this.icon, required this.label, required this.color, required this.route, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => Navigator.pushNamed(context, route) : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Buka Kasir Dahulu"))),
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withValues(alpha: 0.08), shape: BoxShape.circle), child: Icon(icon, size: 26, color: color)),
          const SizedBox(height: 10),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF424769)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

class _DashboardLoadingSkeleton extends StatelessWidget {
  const _DashboardLoadingSkeleton();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Stack(children: [
        Container(height: 300, decoration: const BoxDecoration(gradient: AppTheme.defaultGradient, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)))),
        Column(children: [
          const SizedBox(height: 70),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 25), child: Row(children: [const _SkeletonCircle(radius: 28), const SizedBox(width: 15), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const _SkeletonBox(width: 120, height: 20), const SizedBox(height: 8), const _SkeletonBox(width: 80, height: 14)])])),
          const SizedBox(height: 60),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: const _SkeletonBox(width: double.infinity, height: 100, radius: 25)),
          const SizedBox(height: 40),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [const _SkeletonBox(width: double.infinity, height: 120, radius: 20), const SizedBox(height: 20), const _SkeletonBox(width: double.infinity, height: 120, radius: 20)])),
        ]),
        const Positioned.fill(child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))),
      ]),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  final double radius;
  const _SkeletonCircle({required this.radius});
  @override
  Widget build(BuildContext context) {
    return Container(width: radius * 2, height: radius * 2, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle));
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _SkeletonBox({required this.width, required this.height, this.radius = 8});
  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: height, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(radius)));
  }
}

class _LowStockDialog extends StatelessWidget {
  final List<dynamic> items; // ProductModel type
  const _LowStockDialog({required this.items});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), contentPadding: EdgeInsets.zero,
      content: Container(
        width: getViewportScreenWidth(context) * 0.9, constraints: BoxConstraints(maxHeight: getViewportScreenHeight(context) * 0.7),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.orange.shade800, Colors.orange.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24)), const SizedBox(width: 15), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Stok Menipis!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text("Segera lakukan restock.", style: TextStyle(color: Colors.white70, fontSize: 12))]))])),
          Flexible(child: items.isEmpty ? const _StockSafe() : ListView.separated(padding: const EdgeInsets.all(12), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (ctx, i) => _LowStockItem(item: items[i], index: i))),
          _DialogFooter(onClose: () => Navigator.pop(context), onManage: () { Navigator.pop(context); Navigator.pushNamed(context, '/product'); }),
        ]),
      ),
    );
  }
}

class _StockSafe extends StatelessWidget {
  const _StockSafe();
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(30), child: Column(children: [Icon(Icons.check_circle_outline, size: 60, color: Colors.green.shade300), const SizedBox(height: 10), const Text("Stok Aman", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const Text("Tidak ada barang perlu restok.", style: TextStyle(color: Colors.grey, fontSize: 12))]));
  }
}

class _LowStockItem extends StatelessWidget {
  final dynamic item;
  final int index;
  const _LowStockItem({required this.item, required this.index});
  @override
  Widget build(BuildContext context) {
    double progress = (item.stok / (item.minStok == 0 ? 1 : item.minStok)).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)], border: Border.all(color: Colors.grey.shade100)),
      child: Row(children: [
        Container(height: 40, width: 40, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)), child: Text("${index+1}", style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 6), ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation(item.stok == 0 ? Colors.red : Colors.orange), minHeight: 6)), const SizedBox(height: 4), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Sisa: ${item.stok}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item.stok == 0 ? Colors.red : Colors.orange.shade800)), Text("Min: ${item.minStok}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600))])])),
      ]),
    );
  }
}

class _DialogFooter extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onManage;
  const _DialogFooter({required this.onClose, required this.onManage});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))), child: Row(children: [Expanded(child: OutlinedButton(onPressed: onClose, child: const Text("Tutup"))), const SizedBox(width: 10), Expanded(child: ElevatedButton(onPressed: onManage, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor), child: const Text("Kelola Stok"))) ]));
  }
}
