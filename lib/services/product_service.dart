import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart'; // Required for MediaType
import '../core/api_client.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

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

  Future<bool> updateCategory(String id, String nama) async {
    try {
      final response = await _dio.put('/products/categories/$id', data: {'nama': nama});
      return response.statusCode == 200;
    } catch (e) {
      return false;
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

  Future<List<Barang>> getLowStockProducts() async {
    try {
      final response = await _dio.get('/products/low-stock');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Barang.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gagal memuat stok menipis: $e');
    }
  }

  Future<Barang?> addProduct(Barang barang, {Uint8List? imageBytes, String? imageFilename}) async {
    print('Starting addProduct...');
    try {
      final formData = FormData();
      
      // Manually add fields
      formData.fields.addAll([
        MapEntry('nama', barang.nama),
        MapEntry('harga', barang.harga.toString()),
        MapEntry('harga_dasar', barang.hargaDasar.toString()),
        MapEntry('stok', barang.stok.toString()),
        MapEntry('min_stok', barang.minStok.toString()),
        MapEntry('barcode', barang.barcode),
        MapEntry('is_jasa', barang.isJasa.toString()),
        MapEntry('kategori_id', barang.kategoriId),
      ]);
      print('FormData fields added.');

      if (imageBytes != null && imageFilename != null) {
        print('Adding image bytes to FormData. Size: ${imageBytes.length}');
        
        final multipartFile = MultipartFile.fromBytes(
          imageBytes, 
          filename: imageFilename,
          contentType: MediaType('image', 'jpeg'), 
        );
        
        formData.files.add(MapEntry('image', multipartFile));
        print('File added to FormData.');
      }

      print('Sending POST request...');
      final response = await _dio.post('/products', data: formData);
      print('Response received: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        return Barang.fromMap(response.data);
      }
      return null;
    } catch (e, stack) {
      print('Add Product Critical Error: $e');
      print('Stacktrace: $stack');
      throw Exception('Gagal menambah produk: $e');
    }
  }

  Future<bool> updateProduct(Barang barang, {Uint8List? imageBytes, String? imageFilename}) async {
    print('Starting updateProduct...');
    try {
      final formData = FormData();

      formData.fields.addAll([
        MapEntry('nama', barang.nama),
        MapEntry('harga', barang.harga.toString()),
        MapEntry('harga_dasar', barang.hargaDasar.toString()),
        MapEntry('stok', barang.stok.toString()),
        MapEntry('min_stok', barang.minStok.toString()),
        MapEntry('barcode', barang.barcode),
        MapEntry('is_jasa', barang.isJasa.toString()),
        MapEntry('kategori_id', barang.kategoriId),
      ]);

      if (imageBytes != null && imageFilename != null) {
        print('Updating image bytes. Size: ${imageBytes.length}');

        formData.files.add(MapEntry(
          'image',
          MultipartFile.fromBytes(
            imageBytes, 
            filename: imageFilename,
            contentType: MediaType('image', 'jpeg'),
          ),
        ));
      }

      print('Sending PUT request...');
      final response = await _dio.put('/products/${barang.id}', data: formData);
      print('Response received: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e, stack) {
       print('Update Product Critical Error: $e');
       print('Stacktrace: $stack');
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
