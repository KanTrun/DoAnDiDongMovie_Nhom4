import 'package:dio/dio.dart';
import '../config/app_config.dart';

class ApiClient {
  static Dio backend({String? token}) {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.backendBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        print('API Error: ${error.response?.statusCode} - ${error.message}');
        return handler.next(error);
      },
    ));
    
    return dio;
  }
  
  static Dio tmdb() {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
    ));
    
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Always add API key
        options.queryParameters['api_key'] = AppConfig.tmdbApiKey;
        
        // Only add default language for specific endpoints that need it
        // Don't add language for search endpoints to allow global search
        if (!options.queryParameters.containsKey('language') && 
            !options.path.contains('/videos') &&
            !options.path.contains('/search')) {
          options.queryParameters['language'] = AppConfig.tmdbLanguage;
        }
        
        print('🔍 TMDB Request: ${options.method} ${options.path}');
        print('📋 Query params: ${options.queryParameters}');
        
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ TMDB Response: ${response.statusCode} - ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('❌ TMDB API Error: ${error.response?.statusCode} - ${error.message}');
        if (error.response?.data != null) {
          print('📄 Error data: ${error.response?.data}');
        }
        return handler.next(error);
      },
    ));
    
    return dio;
  }
}