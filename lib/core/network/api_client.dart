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
        'ngrok-skip-browser-warning': 'true', // Bypass ngrok warning
      },
    ));
    
        dio.interceptors.add(InterceptorsWrapper(
          onRequest: (options, handler) {
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            return handler.next(options);
          },
          onResponse: (response, handler) {
            return handler.next(response);
          },
          onError: (error, handler) {
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
        
        // Debug logs removed
        
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Debug logs removed
        return handler.next(response);
      },
      onError: (error, handler) {
        // Debug logs removed
        return handler.next(error);
      },
    ));
    
    return dio;
  }
}