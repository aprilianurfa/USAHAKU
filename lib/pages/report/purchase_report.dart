import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/purchase_model.dart';
import '../../services/purchase_service.dart';

class LaporanPembelianPage extends StatefulWidget {
  const LaporanPembelianPage({super.key});

  @override
  State<LaporanPembelianPage> createState() => _LaporanPembelianPageState();
}

class _LaporanPembelianPageState extends State<LaporanPembelianPage> {
  final PurchaseService _purchaseService = PurchaseService();
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
  final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

  late Future<List<Pembelian>> _futurePurchases;

  @override
  void initState() {
    super.initState();
    _futurePurchases = _purchaseService.getPurchases();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FutureBuilder<List<Pembelian>>(
              future: _futurePurchases,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text("Belum ada riwayat pembelian"),
                      ],
                    ),
                  );
                }

                final list = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(Icons.shopping_cart_outlined, color: Colors.blue),
                        ),
                        title: Text(
                          item.supplier.isNotEmpty ? item.supplier : "Tanpa Supplier",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(dateFormatter.format(item.tanggal)),
                        trailing: Text(
                          currencyFormatter.format(item.totalBiaya),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        children: [
                          if (item.keterangan.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.note_alt_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(item.keterangan, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ),
                          const Divider(),
                          ...item.items.map((i) => ListTile(
                                title: Text(i.productName ?? "Produk", style: const TextStyle(fontSize: 14)),
                                subtitle: Text("${i.jumlah} unit x ${currencyFormatter.format(i.hargaBeli)}"),
                                trailing: Text(currencyFormatter.format(i.jumlah * i.hargaBeli)),
                              )),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 20 + MediaQuery.of(context).padding.top, 10, 20),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context), 
                  icon: const Icon(Icons.arrow_back, color: Colors.white)
                ),
              ),
              const Expanded(
                child: Text(
                  "Laporan Pembelian",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }
}
