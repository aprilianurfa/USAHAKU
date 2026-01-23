import 'package:dio/dio.dart';
import '../config/constants.dart';
import '../config/storage_config.dart';

class ApiClient {
  // Store Etags and Data in memory for current session
  static final Map<String, String> _etagCache = {};
  static final Map<String, dynamic> _dataCache = {};

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 8),
      contentType: 'application/json',
      validateStatus: (status) => status != null && (status >= 200 && status < 300 || status == 304),
    ),
  );

  ApiClient() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.path.contains('/auth/login') || options.path.contains('/auth/register')) {
          return handler.next(options);
        }

        final token = await StorageConfig.storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // --- 1. SET ETAG HEADER ---
        final cacheKey = "${options.method}:${options.path}:${options.queryParameters}";
        if (options.method == 'GET' && _etagCache.containsKey(cacheKey)) {
          options.headers['If-None-Match'] = _etagCache[cacheKey];
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        // --- 2. HANDLE ETAG STORAGE & 304 TRANSPARENCY ---
        if (response.requestOptions.method == 'GET') {
          final cacheKey = "${response.requestOptions.method}:${response.requestOptions.path}:${response.requestOptions.queryParameters}";
          
          final etag = response.headers.value('etag');
          if (etag != null) {
            _etagCache[cacheKey] = etag;
          }

          if (response.statusCode == 304) {
            // Data hasn't changed. Return cached data transparently.
            if (_dataCache.containsKey(cacheKey)) {
              response.data = _dataCache[cacheKey];
              // Optional: Mark as "came from cache" if needed, but transparent is better
            }
          } else if (response.statusCode == 200) {
            // Save fresh data to cache
            _dataCache[cacheKey] = response.data;
          }
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ));
  }

  static void clearCache() {
    _etagCache.clear();
    _dataCache.clear();
  }
}