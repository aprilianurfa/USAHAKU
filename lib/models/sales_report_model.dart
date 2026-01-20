import 'transaction_model.dart';
class SalesReport {
  final int totalSales;
  final int transactionCount;
  final List<Transaksi> transactions;

  SalesReport({
    required this.totalSales,
    required this.transactionCount,
    required this.transactions,
  });

  factory SalesReport.fromMap(Map<String, dynamic> map) {
    return SalesReport(
      totalSales: map['totalSales'] ?? 0,
      transactionCount: map['transactionCount'] ?? 0,
      transactions: (map['data'] as List?)
              ?.map((e) => Transaksi.fromMap(e))
              .toList() ??
          [],
    );
  }
}

class DashboardSummary {
  final int salesToday;
  final int trxCountToday;
  final int profitToday;

  DashboardSummary({
    required this.salesToday,
    required this.trxCountToday,
    required this.profitToday,
  });

  factory DashboardSummary.fromMap(Map<String, dynamic> map) {
    return DashboardSummary(
      salesToday: map['salesToday'] ?? 0,
      trxCountToday: map['trxCountToday'] ?? 0,
      profitToday: map['profitToday'] ?? 0,
    );
  }
}
