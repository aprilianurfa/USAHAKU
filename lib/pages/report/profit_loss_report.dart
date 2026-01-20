import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/dummy_data.dart';
import '../../widgets/summary_card.dart';

enum FilterMode { harian, bulanan }

class LaporanLabaRugiPage extends StatefulWidget {
  const LaporanLabaRugiPage({super.key});

  @override
  State<LaporanLabaRugiPage> createState() => _LaporanLabaRugiPageState();
}

class _LaporanLabaRugiPageState extends State<LaporanLabaRugiPage> {
  FilterMode mode = FilterMode.harian;
  DateTime selectedDate = DateTime.now();

  String rupiah(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  List<Map<String, dynamic>> get filteredTransaksi {
    return DummyData.transaksi.where((t) {
      final DateTime tanggal = t['tanggal'];

      if (mode == FilterMode.harian) {
        return tanggal.year == selectedDate.year &&
            tanggal.month == selectedDate.month &&
            tanggal.day == selectedDate.day;
      } else {
        return tanggal.year == selectedDate.year &&
            tanggal.month == selectedDate.month;
      }
    }).toList();
  }

  int get totalPenjualan =>
      filteredTransaksi.fold(0, (sum, t) => sum + (t['total'] as int));

  int get labaBersih =>
      (totalPenjualan * 0.3).toInt(); // simulasi laba 30%

  int get totalBiaya => totalPenjualan - labaBersih;

  @override
  Widget build(BuildContext context) {
    final margin =
        totalPenjualan == 0 ? 0 : (labaBersih / totalPenjualan) * 100;

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Laba Rugi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= FILTER =================
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<FilterMode>(
                    value: mode,
                    items: const [
                      DropdownMenuItem(
                        value: FilterMode.harian,
                        child: Text('Harian'),
                      ),
                      DropdownMenuItem(
                        value: FilterMode.bulanan,
                        child: Text('Bulanan'),
                      ),
                    ],
                    onChanged: (v) => setState(() => mode = v!),
                    decoration: const InputDecoration(
                      labelText: 'Filter',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    mode == FilterMode.harian
                        ? DateFormat('dd MMM yyyy').format(selectedDate)
                        : DateFormat('MMMM yyyy').format(selectedDate),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ================= SUMMARY =================
            SummaryCard(
              title: 'Total Penjualan',
              value: rupiah(totalPenjualan),
              icon: Icons.payments,
            ),
            const SizedBox(height: 12),
            SummaryCard(
              title: 'Total Biaya',
              value: rupiah(totalBiaya),
              icon: Icons.money_off,
            ),
            const SizedBox(height: 12),
            SummaryCard(
              title: 'Laba Bersih',
              value: rupiah(labaBersih),
              icon: Icons.trending_up,
            ),

            const SizedBox(height: 24),

            // ================= MARGIN =================
            Card(
              color: Colors.green.withOpacity(0.1),
              child: ListTile(
                leading: const Icon(Icons.percent, color: Colors.green),
                title: const Text('Margin Laba'),
                subtitle: Text('${margin.toStringAsFixed(1)} %'),
              ),
            ),

            const SizedBox(height: 24),

            // ================= GRAFIK =================
            Text(
              'Grafik Laba Rugi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 260,
              child: BarChart(_buildChart()),
            ),

            const SizedBox(height: 24),

            // ================= INSIGHT =================
            Card(
              child: ListTile(
                leading: Icon(
                  labaBersih >= 0 ? Icons.check_circle : Icons.warning,
                  color: labaBersih >= 0 ? Colors.green : Colors.red,
                ),
                title: Text(
                  labaBersih >= 0
                      ? 'Usaha menguntungkan'
                      : 'Usaha mengalami kerugian',
                ),
                subtitle: Text(
                  labaBersih >= 0
                      ? 'Pertahankan efisiensi biaya'
                      : 'Perlu evaluasi pengeluaran',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= GRAFIK =================
  BarChartData _buildChart() {
    final maxY = [
      totalPenjualan.toDouble(),
      totalBiaya.toDouble(),
      labaBersih.toDouble(),
    ].reduce((a, b) => a > b ? a : b);

    return BarChartData(
      maxY: maxY == 0 ? 100 : maxY * 1.2,
      barGroups: [
        _bar(0, totalPenjualan, Colors.blue),
        _bar(1, totalBiaya, Colors.red),
        _bar(2, labaBersih, Colors.green),
      ],
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              switch (v.toInt()) {
                case 0:
                  return const Text('Penjualan');
                case 1:
                  return const Text('Biaya');
                case 2:
                  return const Text('Laba');
                default:
                  return const SizedBox();
              }
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) => Text('${v ~/ 1000}k'),
          ),
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, int value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          color: color,
          width: 22,
        ),
      ],
    );
  }
}
