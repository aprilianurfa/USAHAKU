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

  Future<Map<String, dynamic>> getProductSalesAnalysis({String? startDate, String? endDate}) async {
    try {
      final response = await _dio.get('/reports/product-sales', queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      });
      // consoleLog("Service Response: ${response.data}");
      return {
        "summary": response.data['summary'],
        "data": List<Map<String, dynamic>>.from(response.data['data'])
      };
    } catch (e) {
      consoleLog("Service Error: $e");
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerSalesAnalysis({String? startDate, String? endDate}) async {
    try {
      final response = await _dio.get('/reports/customer-sales', queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      });
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (e) {
      consoleLog("Customer Service Error: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> getInventoryAnalysis() async {
    try {
      final response = await _dio.get('/reports/inventory-analysis');
      return response.data;
    } catch (e) {
      consoleLog("Inventory Analysis Error: $e");
      return {};
    }
  }

  Future<Map<String, dynamic>> getProfitLossAnalysis({String? startDate, String? endDate}) async {
    try {
      final response = await _dio.get('/reports/profit-loss', queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      });
      return response.data;
    } catch (e) {
      consoleLog("Profit Loss Error: $e");
      throw Exception('Failed to load profit loss analysis');
    }
  }

  Future<List<Map<String, dynamic>>> getShiftReports({String? startDate, String? endDate}) async {
    try {
      final response = await _dio.get('/reports/shifts', queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      consoleLog("Shift Report Error: $e");
      return [];
    }
  }

  void consoleLog(String msg) {
    // Helper for debugging
    print("[ReportService] $msg");
  }
}
