import 'dart:async';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../config/storage_config.dart';

class AuthService {
  final Dio _dio = ApiClient().dio;
  final _storage = StorageConfig.storage;

  // REGISTER
  Future<dynamic> register(
    String namaUsaha,
    String namaPemilik,
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        "/auth/register",
        data: {
          "nama": namaPemilik,
          "email": email,
          "password": password,
          "nama_toko": namaUsaha,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout || 
          e.type == DioExceptionType.connectionError) {
        return {"error": "Gagal terhubung ke server. Periksa koneksi internet Anda."};
      }
      return e.response?.data ?? {"error": "Registrasi Gagal"};
    } catch (e) {
      return {"error": "Terjadi kesalahan yang tidak diketahui"};
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
        
        // Simpan role & shopId untuk proteksi menu di frontend dan API calls
        final user = response.data['user'];
        if (user != null) {
          if (user['role'] != null) await _storage.write(key: 'role', value: user['role']);
          if (user['nama'] != null) await _storage.write(key: 'userName', value: user['nama']);
          if (user['shop_id'] != null) await _storage.write(key: 'shopId', value: user['shop_id'].toString());
        }
        
        return response.data;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return {"error": "Gagal terhubung ke server. Periksa koneksi internet Anda."};
      }
      return e.response?.data ?? {"error": "Email atau Password salah"};
    } catch (e) {
       return {"error": "Terjadi kesalahan saat login"};
    }
  }

  // LOGOUT (Optional helper)
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  // GET CURRENT ROLE
  Future<String?> getRole() async {
    return await _storage.read(key: 'role');
  }

  // GET CURRENT USER NAME
  Future<String?> getUserName() async {
    return await _storage.read(key: 'userName');
  }

  // GET SHOP ID
  Future<String?> getShopId() async {
    return await _storage.read(key: 'shopId');
  }

  // --- PROFILE ---
  Future<dynamic> getProfile() async {
    try {
      // Token akan otomatis di-handle oleh ApiClient interceptors (jika ada)
      // atau kita harus pasang manual jika ApiClient belum support auto-attach token
      // Asumsi: ApiClient sudah menghandle atau kita butuh cara lain.
      // Cek ApiClient nanti.
      final response = await _dio.get("/auth/profile");
      return response.data;
    } on DioException catch (e) {
      return e.response?.data ?? {"error": "Gagal mengambil profil"};
    }
  }

  Future<dynamic> updateProfile(String nama, String email) async {
    try {
      final response = await _dio.put(
        "/auth/profile",
        data: {"nama": nama, "email": email},
      );
      return response.data;
    } on DioException catch (e) {
      return e.response?.data ?? {"error": "Gagal update profil"};
    }
  }

  // --- EMPLOYEE MANAGEMENT ---
  Future<dynamic> getEmployees() async {
    try {
      final response = await _dio.get("/auth/employees");
      return response.data;
    } on DioException catch (e) {
      return e.response?.data ?? {"error": "Gagal mengambil data karyawan"};
    }
  }

  Future<dynamic> addEmployee(String nama, String email, String password) async {
    try {
      final response = await _dio.post(
        "/auth/add-staff",
        data: {
          "nama": nama,
          "email": email,
          "password": password,
          // shop_id diambil dari token user owner yg login
        },
      );
      return response.data;
    } on DioException catch (e) {
      return e.response?.data ?? {"error": "Gagal menambah karyawan"};
    }
  }

  Future<dynamic> deleteEmployee(int id) async {
    try {
      final response = await _dio.delete("/auth/employees/$id");
      return response.data;
    } on DioException catch (e) {
      return e.response?.data ?? {"error": "Gagal menghapus karyawan"};
    }
  }
}