import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/transaction_model.dart';
import '../models/sales_report_model.dart';

class TransactionService {
  final Dio _dio = ApiClient().dio;

  Future<bool> createTransaction(Transaksi transaksi) async {
    try {
      final response = await _dio.post('/transactions', data: transaksi.toMap());
      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Gagal membuat transaksi: $e');
    }
  }

  Future<List<Transaksi>> getTransactions({DateTime? startDate, DateTime? endDate, String? namaPelanggan}) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (startDate != null && endDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (namaPelanggan != null && namaPelanggan != 'Semua') {
        queryParams['namaPelanggan'] = namaPelanggan;
      }

      final response = await _dio.get('/transactions', queryParameters: queryParams);
      if (response.statusCode == 200 || response.statusCode == 304) {
        List<dynamic> data = response.data;
        return data.map((json) => Transaksi.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gagal memuat riwayat transaksi: $e');
    }
  }

  Future<SalesReport> getSalesReport({DateTime? startDate, DateTime? endDate}) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (startDate != null && endDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await _dio.get('/reports/sales', queryParameters: queryParams);
      if (response.statusCode == 200) {
        return SalesReport.fromMap(response.data);
      }
      throw Exception('Gagal memuat laporan penjualan');
    } catch (e) {
      throw Exception('Gagal memuat laporan penjualan: $e');
    }
  }

  Future<DashboardSummary> getDashboardSummary({DateTime? startTime}) async {
    try {
      final queryParams = startTime != null ? {'startTime': startTime.toIso8601String()} : null;
      final response = await _dio.get('/reports/summary', queryParameters: queryParams);
      if (response.statusCode == 200 || response.statusCode == 304) {
        return DashboardSummary.fromMap(response.data);
      }
      throw Exception('Gagal memuat ringkasan dashboard');
    } catch (e) {
      throw Exception('Gagal memuat ringkasan dashboard: $e');
    }
  }

  Future<List<String>> getCustomerNames() async {
    try {
      final response = await _dio.get('/transactions/customers');
      if (response.statusCode == 200 || response.statusCode == 304) {
        return List<String>.from(response.data);
      }
      return [];
    } catch (e) {
      throw Exception('Gagal memuat daftar pelanggan: $e');
    }
  }
}
