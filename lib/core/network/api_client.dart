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
        
        // Only add default language if not already specified AND not for videos endpoint
        // Videos endpoint doesn't support language filtering and returns empty results
        if (!options.queryParameters.containsKey('language') && 
            !options.path.contains('/videos')) {
          options.queryParameters['language'] = AppConfig.tmdbLanguage;
        }
        
        // Debug logs removed for cleaner output
        
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (error, handler) {
        print('🌐 TMDB API Error: ${error.message}');
        return handler.next(error);
      },
    ));
    
    return dio;
  }
}