import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/barang.dart';
import '../models/kategori.dart';

class ProductService {
  final Dio _dio = ApiClient().dio;

  // --- CATEGORIES ---

  Future<List<Kategori>> getCategories() async {
    try {
      final response = await _dio.get('/products/categories');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Kategori.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gagal memuat kategori: $e');
    }
  }

  Future<Kategori?> addCategory(String nama) async {
    try {
      final response = await _dio.post('/products/categories', data: {'nama': nama});
      if (response.statusCode == 201) {
        return Kategori.fromMap(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal menambah kategori: $e');
    }
  }

    Future<bool> deleteCategory(String id) async {
    try {
      final response = await _dio.delete('/products/categories/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }


  // --- PRODUCTS ---

  Future<List<Barang>> getProducts() async {
    try {
      final response = await _dio.get('/products');
      print('GET /products status: ${response.statusCode}');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        print('GET /products data length: ${data.length}');
        print('GET /products first item: ${data.isNotEmpty ? data.first : "empty"}');
        return data.map((json) {
           try {
             return Barang.fromMap(json);
           } catch (e) {
             print('Error parsing Barang: $e, json: $json');
             rethrow;
           }
        }).toList();
      }
      return [];
    } catch (e) {
      print('Exception in getProducts: $e');
      throw Exception('Gagal memuat produk: $e');
    }
  }

  Future<Barang?> addProduct(Barang barang, {String? imagePath}) async {
    try {
      FormData formData = FormData.fromMap(barang.toMap());
      
      if (imagePath != null) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(imagePath),
        ));
      }

      final response = await _dio.post('/products', data: formData);
      if (response.statusCode == 201) {
        return Barang.fromMap(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal menambah produk: $e');
    }
  }

  Future<bool> updateProduct(Barang barang, {String? imagePath}) async {
    try {
      FormData formData = FormData.fromMap(barang.toMap());

      if (imagePath != null) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(imagePath),
        ));
      }

      final response = await _dio.put('/products/${barang.id}', data: formData);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final response = await _dio.delete('/products/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
