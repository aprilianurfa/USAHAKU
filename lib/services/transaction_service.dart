import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/transaction_model.dart';

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

  Future<List<Transaksi>> getTransactions() async {
    try {
      final response = await _dio.get('/transactions');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Transaksi.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gagal memuat riwayat transaksi: $e');
    }
  }
}
