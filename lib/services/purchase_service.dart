import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/purchase_model.dart';

class PurchaseService {
  final Dio _dio = ApiClient().dio;

  Future<List<Pembelian>> getPurchases() async {
    try {
      final response = await _dio.get('/purchases');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Pembelian.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gagal memuat riwayat pembelian: $e');
    }
  }

  Future<Pembelian?> createPurchase(Pembelian pembelian) async {
    try {
      final response = await _dio.post('/purchases', data: pembelian.toMap());
      if (response.statusCode == 201) {
        return Pembelian.fromMap(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal menyimpan pembelian: $e');
    }
  }
}
