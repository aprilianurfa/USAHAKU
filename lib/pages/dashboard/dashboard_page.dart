import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../services/shift_service.dart';
import '../../models/product_model.dart';
import '../shift/open_shift_page.dart';
import '../shift/close_shift_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Service Instances
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  final ShiftService _shiftService = ShiftService();

  // State Variables
  double _totalPenjualan = 0;
  int _totalTransaksi = 0;
  int _stokMenipis = 0;
  String _role = 'kasir';
  Map<String, dynamic>? _currentShift;
  bool _isLoadingShift = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadUserRole();
    await _checkShiftStatus();
    // Simulate sales data fetch (Replace with actual SalesService later if needed)
    if (mounted) {
      setState(() {
        _totalPenjualan = 2500000;
        _totalTransaksi = 47;
      });
    }
  }

  Future<void> _loadUserRole() async {
    final role = await _authService.getRole();
    if (mounted) {
      setState(() {
        _role = role ?? 'kasir';
      });
      if (_role == 'owner') {
        _fetchLowStockCount();
      }
    }
  }

  Future<void> _checkShiftStatus() async {
    if (!mounted) return;
    setState(() => _isLoadingShift = true);
    
    final shift = await _shiftService.getCurrentShift();
    
    if (mounted) {
      setState(() {
        _currentShift = shift;
        _isLoadingShift = false;
      });
    }
  }

  Future<void> _fetchLowStockCount() async {
    try {
      final products = await _productService.getLowStockProducts();
      if (mounted) {
        setState(() {
          _stokMenipis = products.length;
        });
      }
    } catch (e) {
      debugPrint("Error fetching low stock: $e");
    }
  }

  String _formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount).replaceAll(",0", ""); // Show full amount or customize as needed
  }
  
  // Alternative short format for header
  String _formatRupiahShort(double amount) {
     return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 1,
    ).format(amount / 1000000).replaceAll(",0", "") + "jt";
  }

  Future<void> _showNotificationDialog() async {
    try {
      final lowStockItems = await _productService.getLowStockProducts();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text("Stok Menipis"),
            ],
          ),
          content: lowStockItems.isEmpty
              ? const Text("Stok aman, tidak ada barang yang menipis.")
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: lowStockItems.length,
                    separatorBuilder: (ctx, i) => const Divider(),
                    itemBuilder: (ctx, i) {
                      final item = lowStockItems[i];
                      return ListTile(
                        title: Text(item.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Sisa: ${item.stok} (Min: ${item.minStok})"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                           Navigator.pop(ctx);
                           Navigator.pushNamed(context, '/product');
                        },
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Tutup"),
            )
          ],
        ),
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
    // If result is true (shift opened), refresh status
    if (result == true) {
      _checkShiftStatus();
    }
  }

  void _navigateToCloseShift() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const CloseShiftPage())
    );
    // If result is true (shift closed), refresh status
    if (result == true) {
      _checkShiftStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOwner = _role == 'owner';
    bool isShiftOpen = _currentShift != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor, 
      body: _isLoadingShift 
          ? _buildLoadingSkeleton()
          : SingleChildScrollView(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Column(
                    children: [
                      _buildHeaderSectionTop(isOwner, isShiftOpen),
                      Transform.translate(
                        offset: const Offset(0, -165), 
                        child: Column(
                          children: [
                            const SizedBox(height: 100), // Precise space for floating card
                            
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
                                gridCount: 4,
                                children: [
                                  _menuItemModern(context, Icons.insert_chart_rounded, "Ringkasan", Colors.blue.shade900, '/report'),
                                  _menuItemModern(context, Icons.trending_up_rounded, "Penjualan", Colors.green.shade700, '/sales-report'),
                                  _menuItemModern(context, Icons.account_balance_wallet_rounded, "Laba Rugi", Colors.teal.shade700, '/profit-loss-report'),
                                  _menuItemModern(context, Icons.assignment_rounded, "Lap. Beli", Colors.brown, '/purchase-report'),
                                  _menuItemModern(context, Icons.savings_rounded, "Modal", Colors.deepOrange, '/capital-report'),
                                  _menuItemModern(context, Icons.groups_rounded, "Pengunjung", Colors.cyan.shade800, '/visitor-report'),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 150, 
                    left: 20,
                    right: 20,
                    child: _buildSummaryCard(isOwner, isShiftOpen),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderSectionTop(bool isOwner, bool isShiftOpen) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: EdgeInsets.fromLTRB(25, 40 + MediaQuery.of(context).padding.top, 25, 200),
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
                  child: const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person_rounded, size: 32, color: AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Toko Berkah", style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
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
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    onPressed: isOwner ? _showNotificationDialog : null,
                    icon: Icon(Icons.notifications_none_rounded, color: isOwner ? Colors.white : Colors.white24, size: 28),
                  ),
                  if (isOwner && _stokMenipis > 0)
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

  Widget _buildSummaryCard(bool isOwner, bool isShiftOpen) {
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
              _formatRupiahShort(_totalPenjualan), 
              "$_totalTransaksi Transaksi", 
              Icons.trending_up, 
              color: Colors.greenAccent
            )
          ),
          if (isOwner) ...[
            Container(width: 1, height: 40, color: Colors.white24),
            Expanded(
              child: _buildSummaryText(
                "Low Stock", 
                "$_stokMenipis Item", 
                "Perlu Restok", 
                Icons.inventory_2_outlined,
                isWarning: true,
                color: Colors.orangeAccent,
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
              color: AppTheme.primaryColor,
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
