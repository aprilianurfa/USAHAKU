import 'dart:async';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../config/storage_config.dart';
import '../../services/local_storage_service.dart';

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

      // AUTO LOGIN START
      if (response.data['token'] != null) {
        await _storage.write(key: 'token', value: response.data['token']);
        
        final user = response.data['user'];
        if (user != null) {
          if (user['role'] != null) await _storage.write(key: 'role', value: user['role']);
          if (user['nama'] != null) await _storage.write(key: 'userName', value: user['nama']);
          if (user['email'] != null) await _storage.write(key: 'userEmail', value: user['email']);
          if (user['id'] != null) await _storage.write(key: 'userId', value: user['id'].toString());
          if (user['shop_id'] != null) await _storage.write(key: 'shopId', value: user['shop_id'].toString());
          if (user['shop_name'] != null) await _storage.write(key: 'shopName', value: user['shop_name']);
          if (user['shop_logo'] != null) await _storage.write(key: 'shopLogo', value: user['shop_logo']);
        }
      }
      // AUTO LOGIN END

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
        // --- FAILSAFE CLEANUP ---
        await _storage.deleteAll();
        await LocalStorageService().clearAll();
        ApiClient.clearCache();

        // Save new token
        await _storage.write(key: 'token', value: response.data['token']);
        
        final user = response.data['user'];
        if (user != null) {
          if (user['role'] != null) await _storage.write(key: 'role', value: user['role']);
          if (user['nama'] != null) await _storage.write(key: 'userName', value: user['nama']);
          if (user['email'] != null) await _storage.write(key: 'userEmail', value: user['email']);
          if (user['id'] != null) await _storage.write(key: 'userId', value: user['id'].toString());
          if (user['shop_id'] != null) await _storage.write(key: 'shopId', value: user['shop_id'].toString());
          if (user['shop_name'] != null) await _storage.write(key: 'shopName', value: user['shop_name']);
          if (user['shop_logo'] != null) await _storage.write(key: 'shopLogo', value: user['shop_logo']);
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
    return {"error": "Unknown error"};
  }

  // LOGOUT (Optional helper)
  Future<void> logout() async {
    await _storage.deleteAll();
    // Clear Hive Offline Storage
    await LocalStorageService().clearAll();
    // Clear Memory Cache
    ApiClient.clearCache();
  }

  // MANUAL SAVE SESSION (For Registration direct login)
  Future<void> saveSessionManual({
    required String token,
    required String role,
    String? name,
    String? email,
    String? userId,
    String? shopId,
    String? shopName,
    String? shopLogo,
  }) async {
    // 1. Cleanup old session
    await _storage.deleteAll();
    await LocalStorageService().clearAll();
    ApiClient.clearCache();

    // 2. Write new session
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'role', value: role);
    
    if (name != null) await _storage.write(key: 'userName', value: name);
    if (email != null) await _storage.write(key: 'userEmail', value: email);
    if (userId != null) await _storage.write(key: 'userId', value: userId);
    if (shopId != null) await _storage.write(key: 'shopId', value: shopId);
    if (shopName != null) await _storage.write(key: 'shopName', value: shopName);
    if (shopLogo != null) await _storage.write(key: 'shopLogo', value: shopLogo);
  }

  // GET CURRENT ROLE
  Future<String?> getRole() async {
    return await _storage.read(key: 'role');
  }

  // GET CURRENT USER NAME
  Future<String?> getUserName() async {
    return await _storage.read(key: 'userName');
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: 'userEmail');
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'userId');
  }

  Future<String?> getShopId() async {
    return await _storage.read(key: 'shopId');
  }

  // GET SHOP NAME
  Future<String?> getShopName() async {
    return await _storage.read(key: 'shopName');
  }

  // GET SHOP LOGO
  Future<String?> getShopLogo() async {
    return await _storage.read(key: 'shopLogo');
  }

  // --- PROFILE ---
  Future<dynamic> getProfile() async {
    try {
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

  Future<dynamic> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _dio.put(
        "/auth/change-password",
        data: {"oldPassword": oldPassword, "newPassword": newPassword},
      );
      return response.data;
    } on DioException catch (e) {
      return e.response?.data ?? {"error": "Gagal mengubah password"};
    }
  }

  Future<dynamic> uploadShopLogo(String filePath) async {
    try {
      String fileName = filePath.split('/').last;
      FormData formData = FormData.fromMap({
        "logo": await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.put(
        "/auth/update-logo",
        data: formData,
      );

      if (response.data != null && response.data['logoUrl'] != null) {
        await _storage.write(key: 'shopLogo', value: response.data['logoUrl']);
      }

      return response.data;
    } on DioException catch (e) {
      return e.response?.data ?? {"error": "Gagal upload logo"};
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

  // CHECK LOGIN STATUS
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }
}
