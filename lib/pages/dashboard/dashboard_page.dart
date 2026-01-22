import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; 
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../config/constants.dart';
import '../../services/product_service.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/product_provider.dart';
import '../shift/open_shift_page.dart';
import '../shift/close_shift_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Service Instances - Reduced
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    // Refresh dashboard in background when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().refreshDashboard();
    });
  }


  String _formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount).replaceAll(",0", "");
  }
  
  String _formatRupiahShort(double amount) {
     return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 1,
    ).format(amount / 1000000).replaceAll(",0", "") + " jt";
  }

  Future<void> _showNotificationDialog() async {
    try {
      final lowStockItems = await _productService.getLowStockProducts();
      if (!mounted) return;

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "Low Stock",
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (ctx, anim1, anim2) => Container(),
        transitionBuilder: (ctx, anim1, anim2, child) {
          return ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade800, Colors.orange.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text("Stok Menipis!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                Text("Segera lakukan restock barang", style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // List
                    Flexible(
                      child: lowStockItems.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(30),
                            child: Column(
                              children: [
                                Icon(Icons.check_circle_outline, size: 60, color: Colors.green.shade300),
                                const SizedBox(height: 10),
                                const Text("Stok Aman", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const Text("Tidak ada barang yang perlu direstock.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            shrinkWrap: true,
                            itemCount: lowStockItems.length,
                            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final item = lowStockItems[i];
                              final double progress = (item.stok / (item.minStok == 0 ? 1 : item.minStok)).clamp(0.0, 1.0);
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                                  ],
                                  border: Border.all(color: Colors.grey.shade100)
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                       height: 40, width: 40,
                                       alignment: Alignment.center,
                                       decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                                       child: Text("${i+1}", style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              backgroundColor: Colors.grey.shade200,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                item.stok == 0 ? Colors.red : Colors.orange
                                              ),
                                              minHeight: 6,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text("Sisa: ${item.stok}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item.stok == 0 ? Colors.red : Colors.orange.shade800)),
                                              Text("Min: ${item.minStok}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    ),

                    // Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.shade100))
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                              ),
                              child: const Text("Tutup"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pushNamed(context, '/product');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0
                              ),
                              child: const Text("Kelola Stok"),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint("Error showing notification: $e");
    }
  }

  void _navigateToOpenShift() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const OpenShiftPage())
    );
    if (result == true) {
      context.read<DashboardProvider>().refreshDashboard();
    }
  }

  void _navigateToCloseShift() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const CloseShiftPage())
    );
    if (result == true) {
      context.read<DashboardProvider>().refreshDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashProvider = context.watch<DashboardProvider>();
    final isOwner = dashProvider.role == 'owner';
    final isShiftOpen = dashProvider.isShiftOpen;
    final totalPenjualan = dashProvider.summary?.salesToday.toDouble() ?? 0;
    final totalTransaksi = dashProvider.summary?.trxCountToday ?? 0;
    final stokMenipis = dashProvider.lowStockCount;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor, 
      body: dashProvider.isLoading && dashProvider.summary == null
          ? _buildLoadingSkeleton()
          : RefreshIndicator(
              onRefresh: () => dashProvider.refreshDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // --- HEADER & SUMMARY CARD STACK ---
                    SizedBox(
                      height: 260,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: 0, left: 0, right: 0,
                            height: 360,
                            child: _buildHeaderSectionTop(dashProvider),
                          ),
                          Positioned(
                            top: 150, 
                            left: 20, right: 20,
                            child: _buildSummaryCard(dashProvider, totalPenjualan, totalTransaksi),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10), // Spacing after Card
                    
                    // --- SHIFT ALERT SECTION ---
                    if (!isShiftOpen)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade200)
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_clock_outlined, color: Colors.red, size: 30),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text("Kasir Belum Dibuka", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                  Text("Anda tidak dapat melakukan transaksi sebelum membuka kasir.", style: TextStyle(fontSize: 12, color: Colors.red)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _navigateToOpenShift,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Buka"),
                            )
                          ],
                        ),
                      ),

                    // --- MENU SECTIONS ---
                    Column(
                      children: [
                        // --- OWNER MENU ---
                        if (isOwner) ...[
                          _buildSectionContainer(
                            title: "Manajemen Stok",
                            icon: Icons.inventory_2_rounded,
                            children: [
                              _menuItemModern(context, Icons.inventory_rounded, "Barang", Colors.indigo, '/product'),
                              _menuItemModern(context, Icons.grid_view_rounded, "Kategori", Colors.blue.shade700, '/category'),
                              _menuItemModern(context, Icons.shopping_bag_rounded, "Pembelian", Colors.blue.shade500, '/purchase'),
                            ],
                          ),
                          const SizedBox(height: 5),
                        ],

                        // --- KASIR MENU ---
                        _buildSectionContainer(
                          title: "Operasional Kasir",
                          icon: Icons.point_of_sale_rounded,
                          children: [
                            _menuItemModern(
                              context, 
                              Icons.add_shopping_cart_rounded, 
                              "Transaksi", 
                              isShiftOpen ? Colors.orange.shade800 : Colors.grey, 
                              '/transaction',
                              enabled: isShiftOpen,
                              onDisabledTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Buka Kasir terlebih dahulu!"))
                                );
                              }
                            ),
                            _menuItemModern(context, Icons.receipt_long_rounded, "Riwayat", Colors.purple.shade700, '/transaction-history'),
                            _menuItemModern(context, Icons.print_rounded, "Printer BT", Colors.blue.shade600, '/printer-setting'),
                          ],
                        ),

                        const SizedBox(height: 5),

                        // --- REPORT MENU (OWNER) ---
                        if (isOwner)
                          _buildSectionContainer(
                            title: "Analitik & Laporan",
                            icon: Icons.analytics_rounded,
                            gridCount: 3,
                            children: [
                              _menuItemModern(context, Icons.receipt_long_rounded, "Laporan Shift", Colors.blue.shade900, '/report-shift'),
                              _menuItemModern(context, Icons.trending_up_rounded, "Penjualan", Colors.green.shade700, '/report-sales'),
                              _menuItemModern(context, Icons.account_balance_wallet_rounded, "Laba Rugi", Colors.teal.shade700, '/report-profit-loss'),
                              _menuItemModern(context, Icons.assignment_rounded, "Lap. Beli", Colors.brown, '/report-purchase'),
                              _menuItemModern(context, Icons.savings_rounded, "Modal", Colors.deepOrange, '/report-capital'),
                              _menuItemModern(context, Icons.groups_rounded, "Pengunjung", Colors.cyan.shade800, '/report-visitor'),
                            ],
                          ),
                        const SizedBox(height: 20), // Bottom Margin
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSectionTop(DashboardProvider dashProvider) {
    bool isOwner = dashProvider.role == 'owner';
    bool isShiftOpen = dashProvider.isShiftOpen;
    int stokMenipis = dashProvider.lowStockCount;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.defaultGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: EdgeInsets.fromLTRB(25, 40 + MediaQuery.of(context).padding.top, 25, 80),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                  borderRadius: BorderRadius.circular(28),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    backgroundImage: dashProvider.shopLogo != null 
                         ? NetworkImage("${AppConstants.imageBaseUrl}${dashProvider.shopLogo}") 
                         : null,
                    child: dashProvider.shopLogo == null 
                        ? const Icon(Icons.person_rounded, size: 32, color: AppTheme.primaryColor)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dashProvider.shopName, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(isOwner ? "Owner (Premium)" : "Staff Kasir", style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: isShiftOpen ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: isShiftOpen ? _navigateToCloseShift : _navigateToOpenShift,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isShiftOpen ? Icons.check_circle : Icons.lock_outline, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          isShiftOpen ? "BUKA" : "TUTUP", 
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // SYNC STATUS INDICATOR
              Consumer<ProductProvider>(
                builder: (context, prodProv, _) {
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () => prodProv.performSync(),
                        icon: Icon(
                          prodProv.isLoading ? Icons.sync : Icons.cloud_done_outlined,
                          color: prodProv.pendingSyncCount > 0 ? Colors.orangeAccent : Colors.white,
                          size: 26,
                        ),
                      ),
                      if (prodProv.pendingSyncCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                            child: Text(
                              "${prodProv.pendingSyncCount}",
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 4),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    onPressed: isOwner ? _showNotificationDialog : null,
                    icon: Icon(Icons.notifications_none_rounded, color: isOwner ? Colors.white : Colors.white24, size: 28),
                  ),
                  if (isOwner && stokMenipis > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 10,
                          minHeight: 10,
                        ),
                      ),
                    ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(DashboardProvider dashProvider, double totalPenjualan, int totalTransaksi) {
    final isOwner = dashProvider.role == 'owner';
    final isShiftOpen = dashProvider.isShiftOpen;
    final stokMenipis = dashProvider.lowStockCount;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15), 
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
            Expanded(
              child: _buildSummaryText(
                "Penjualan", 
                _formatRupiahShort(totalPenjualan), 
                "$totalTransaksi Transaksi", 
                Icons.trending_up, 
                color: Colors.greenAccent,
                onTap: () => Navigator.pushNamed(context, '/report-sales'),
              )
            ),
          if (isOwner) ...[
            Container(width: 1, height: 40, color: Colors.white24),
            Expanded(
              child: _buildSummaryText(
                "Low Stock", 
                "$stokMenipis Item", 
                "Perlu Restok", 
                Icons.inventory_2_outlined,
                isWarning: stokMenipis > 0,
                color: stokMenipis > 0 ? Colors.orangeAccent : Colors.white24,
                onTap: _showNotificationDialog,
              ),
            ),
          ] else ...[
            Container(width: 1, height: 40, color: Colors.white24),
            Expanded(
              child: _buildSummaryText(
                "Kasir", 
                isShiftOpen ? "BUKA" : "TUTUP",
                isShiftOpen ? "Ready" : "Klik Buka",
                Icons.point_of_sale_rounded,
                isWarning: !isShiftOpen,
                color: isShiftOpen ? Colors.blueAccent : Colors.redAccent,
                onTap: isShiftOpen ? _navigateToCloseShift : _navigateToOpenShift,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSummaryText(String title, String value, String sub, IconData icon, {bool isWarning = false, Color color = Colors.white, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color.withOpacity(0.8)),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value, 
              style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, letterSpacing: 0.5)
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub, 
            style: TextStyle(
              color: isWarning ? Colors.orangeAccent : Colors.white54, 
              fontSize: 10, 
              fontWeight: isWarning ? FontWeight.bold : FontWeight.normal
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({required String title, required IconData icon, required List<Widget> children, int? gridCount}) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = gridCount ?? (screenWidth > 600 ? 4 : 3);
    if (screenWidth < 350) crossAxisCount = 2; // For very small phones
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A2142))),
              Icon(icon, size: 20, color: Colors.blueGrey.shade300),
            ],
          ),
          const SizedBox(height: 22),
            GridView.count(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 22,
              crossAxisSpacing: 10,
              childAspectRatio: crossAxisCount == 4 ? 0.8 : 0.95,
              children: children,
            ),
        ],
      ),
    );
  }

  Widget _menuItemModern(BuildContext context, IconData icon, String label, Color color, String route, {bool enabled = true, VoidCallback? onDisabledTap}) {
    return InkWell(
      onTap: enabled ? () => Navigator.pushNamed(context, route) : onDisabledTap,
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08), 
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF424769)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      child: Stack(
        children: [
          Container(
            height: 300,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.defaultGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 70),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  children: [
                    _skeletonBox(56, 56, radius: 28),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _skeletonBox(120, 20),
                        const SizedBox(height: 8),
                        _skeletonBox(80, 14),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _skeletonBox(double.infinity, 100, radius: 25),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _skeletonBox(double.infinity, 120, radius: 20),
                    const SizedBox(height: 20),
                    _skeletonBox(double.infinity, 120, radius: 20),
                  ],
                ),
              ),
            ],
          ),
          Positioned.fill(
             child: Center(
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   const SizedBox(height: 250),
                   const CircularProgressIndicator(color: AppTheme.primaryColor),
                   const SizedBox(height: 15),
                   Text("Menyiapkan Data Dashboard...", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                 ],
               ),
             ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonBox(double width, double height, {double radius = 8}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.4, end: 0.7),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      },
    );
  }
}
