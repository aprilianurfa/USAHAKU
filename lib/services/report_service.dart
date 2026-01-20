import 'package:dio/dio.dart';
import '../core/api_client.dart';

class ReportService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getSummary() async {
    try {
      final response = await _dio.get('/reports/summary');
      return response.data;
    } catch (e) {
      // Return zeroes on error to prevent crashes
      return {
        "salesToday": 0,
        "trxCountToday": 0,
        "profitToday": 0
      };
    }
  }

  Future<Map<String, dynamic>> getSalesReport({String? startDate, String? endDate}) async {
    try {
      final response = await _dio.get('/reports/sales', queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      });
      return response.data;
    } catch (e) {
       throw Exception("Gagal memuat laporan penjualan");
    }
  }
}
