import 'package:dio/dio.dart';
import '../config/constants.dart';
import '../config/storage_config.dart';

class ApiClient {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      contentType: 'application/json',
    ),
  );

  ApiClient() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip token check for auth endpoints to prevent unnecessary storage access
        if (options.path.contains('/auth/login') || options.path.contains('/auth/register')) {
          return handler.next(options);
        }

        final token = await StorageConfig.storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Handle global errors (like 401 Unauthorized) here if needed
        return handler.next(e);
      },
    ));
  }
}