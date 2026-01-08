import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double totalPenjualan = 2500000;
  int totalTransaksi = 47;
  int stokMenipis = 12;

  String formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 1,
    ).format(amount / 1000000).replaceAll(",0", "") + "jt";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), 
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(),
            Transform.translate(
              offset: const Offset(0, -80), 
              child: Column(
                children: [
                  // Section Manajemen Stok
                  _buildSectionContainer(
                    title: "Manajemen Stok",
                    icon: Icons.inventory_2_rounded,
                    children: [
                      _menuItemModern(context, Icons.inventory_rounded, "Barang", Colors.indigo, '/barang'),
                      _menuItemModern(context, Icons.grid_view_rounded, "Kategori", Colors.blue.shade700, '/kategori'),
                      _menuItemModern(context, Icons.shopping_bag_rounded, "Pembelian", Colors.blue.shade500, '/pembelian'),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // Section Operasional Kasir
                  _buildSectionContainer(
                    title: "Operasional Kasir",
                    icon: Icons.point_of_sale_rounded,
                    children: [
                      _menuItemModern(context, Icons.add_shopping_cart_rounded, "Transaksi", Colors.orange.shade800, '/transaksi'),
                      _menuItemModern(context, Icons.receipt_long_rounded, "Riwayat", Colors.purple.shade700, '/riwayat-transaksi'),
                      // FITUR BARU: PRINTER SETTING
                      _menuItemModern(context, Icons.print_rounded, "Printer BT", Colors.blue.shade600, '/printer-setting'),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // Section Analitik & Laporan
                  _buildSectionContainer(
                    title: "Analitik & Laporan",
                    icon: Icons.analytics_rounded,
                    gridCount: 4,
                    children: [
                      _menuItemModern(context, Icons.insert_chart_rounded, "Ringkasan", Colors.blue.shade900, '/laporan'),
                      _menuItemModern(context, Icons.trending_up_rounded, "Penjualan", Colors.green.shade700, '/laporan-penjualan'),
                      _menuItemModern(context, Icons.account_balance_wallet_rounded, "Laba Rugi", Colors.teal.shade700, '/laporan-laba-rugi'),
                      _menuItemModern(context, Icons.swap_horizontal_circle_rounded, "Arus Kas", Colors.blueGrey, '/laporan-arus-kas'),
                      _menuItemModern(context, Icons.assignment_rounded, "Lap. Beli", Colors.brown, '/laporan-pembelian'),
                      _menuItemModern(context, Icons.savings_rounded, "Modal", Colors.deepOrange, '/laporan-modal'),
                      _menuItemModern(context, Icons.money_off_csred_rounded, "Biaya", Colors.redAccent, '/laporan-biaya'),
                      _menuItemModern(context, Icons.groups_rounded, "Pengunjung", Colors.cyan.shade800, '/laporan-pengunjung'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 360, 
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF1A46BE),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(25, 60, 25, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person_rounded, size: 32, color: Color(0xFF1A46BE)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Toko Berkah", style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                      Text("Premium Member", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(onPressed: (){}, icon: const Icon(Icons.notifications_none_rounded, color: Colors.white))
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 145, 
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), 
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
              ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryText("Penjualan Hari Ini", formatRupiah(totalPenjualan), "$totalTransaksi transaksi"),
                Container(width: 1.5, height: 45, color: Colors.white30),
                _buildSummaryText("Stok Menipis", "$stokMenipis item", "Perlu restock", isWarning: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryText(String title, String value, String sub, {bool isWarning = false}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(sub, style: TextStyle(color: isWarning ? Colors.yellowAccent : Colors.white60, fontSize: 11, fontWeight: isWarning ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildSectionContainer({required String title, required IconData icon, required List<Widget> children, int gridCount = 3}) {
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
            crossAxisCount: gridCount,
            mainAxisSpacing: 22,
            crossAxisSpacing: 10,
            childAspectRatio: gridCount == 4 ? 0.75 : 0.9,
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _menuItemModern(BuildContext context, IconData icon, String label, Color color, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(20),
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
    );
  }
}