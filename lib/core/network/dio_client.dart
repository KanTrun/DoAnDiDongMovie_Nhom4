import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../config/app_config.dart';
import '../env/tmdb_config.dart';

class DioClient {
  static final Logger _logger = Logger();

  static Dio createBackendClient({String? token}) {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.backendBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Request interceptor để thêm auth token
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        _logger.d('Request: ${options.method} ${options.uri}');
        _logger.d('Headers: ${options.headers}');
        _logger.d('Data: ${options.data}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.d('Response: ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (error, handler) {
        _logger.e('Error: ${error.message}');
        _logger.e('Response: ${error.response?.data}');
        handler.next(error);
      },
    ));

    return dio;
  }

  static Dio createTmdbClient() {
    final dio = Dio(BaseOptions(
      baseUrl: TmdbConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Interceptor để thêm API key và language
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.queryParameters.addAll({
          'api_key': TmdbConfig.apiKey,
          'language': TmdbConfig.tmdbLanguage,
        });
        _logger.d('TMDB Request: ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.d('TMDB Response: ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (error, handler) {
        _logger.e('TMDB Error: ${error.message}');
        _logger.e('TMDB Response: ${error.response?.data}');
        handler.next(error);
      },
    ));

    return dio;
  }
}

// Providers
final backendDioProvider = Provider<Dio>((ref) {
  return DioClient.createBackendClient();
});

final tmdbDioProvider = Provider<Dio>((ref) {
  return DioClient.createTmdbClient();
});

final authenticatedDioProvider = Provider.family<Dio, String?>((ref, token) {
  return DioClient.createBackendClient(token: token);
});