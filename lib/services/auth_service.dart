import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api_client.dart';

class AuthService {
  final Dio _dio = ApiClient().dio;
  final _storage = const FlutterSecureStorage();

  // REGISTER
  Future<dynamic> register(
    String namaUsaha,
    String namaPemilik,
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        "/auth/register", // Endpoint yang sudah kita samakan di Express
        data: {
          "nama": namaPemilik,      // Sesuai req.body di backend
          "email": email,
          "password": password,
          "nama_toko": namaUsaha,   // Sesuai req.body di backend
        },
      );
      return response.data;
    } on DioException catch (e) {
      return e.response?.data ?? {"error": "Registrasi Gagal"};
    }
  }

  // LOGIN
  Future<dynamic> login(String email, String password) async {
    try {
      final response = await _dio.post(
        "/auth/login",
        data: {"email": email, "password": password},
      );

      if (response.statusCode == 200) {
        // Simpan token untuk proteksi route (add-staff, dll)
        await _storage.write(key: 'token', value: response.data['token']);
        return response.data;
      }
    } on DioException catch (e) {
      return e.response?.data ?? {"error": "Email atau Password salah"};
    }
  }
}