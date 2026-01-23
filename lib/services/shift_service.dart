import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../config/storage_config.dart';

class ShiftService {
  final Dio _dio = ApiClient().dio;
  final _storage = StorageConfig.storage;

  Future<dynamic> openShift(double initialCash) async {
    try {
      // Ambil shopId dari local storage
      String? shopId = await _storage.read(key: 'shopId');

      if (shopId == null) {
        return {"error": "Data toko tidak ditemukan (shopId null). Silakan login ulang."};
      }

      final response = await _dio.post("/shift/open", data: {
        "initialCash": initialCash,
        "shopId": shopId, 
      });
      return response.data;
    } on DioException catch (e) {
      return e.response?.data ?? {"error": "Gagal membuka kasir: ${e.message}"};
    }
  }

  Future<dynamic> closeShift(double finalCash) async {
    try {
      final response = await _dio.post("/shift/close", data: {
        "finalCash": finalCash,
      });
      return response.data;
    } on DioException catch (e) {
      return e.response?.data ?? {"error": "Gagal menutup kasir"};
    }
  }

  Future<dynamic> getCurrentShift() async {
    try {
      // Add timestamp to prevent caching
      final response = await _dio.get("/shift/current?_t=${DateTime.now().millisecondsSinceEpoch}");
      return response.data; // Returns null if no shift is open
    } on DioException catch (e) {
      // If 404/Null - treat as no shift
      return null;
    }
  }

  Future<dynamic> getShiftSummary() async {
    try {
      // Add timestamp to prevent caching
      final response = await _dio.get("/shift/summary?_t=${DateTime.now().millisecondsSinceEpoch}");
      return response.data;
    } on DioException catch (e) {
      return e.response?.data ?? {"error": "Gagal memuat ringkasan shift"};
    }
  }
}
