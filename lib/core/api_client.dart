import 'package:dio/dio.dart';
import '../config/constants.dart';

class ApiClient {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      contentType: 'application/json',
    ),
  );

  // Kamu bisa tambahkan Interceptor di sini nanti untuk handle token otomatis
} 