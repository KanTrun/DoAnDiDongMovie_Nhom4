class AppConfig {
  static const String tmdbApiKey = String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: '2daf813d8e3ba7435e678ee33d90d6e9',
  );
  
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://silvana-detainable-nongratifyingly.ngrok-free.dev',
  );
  
  static const String tmdbLanguage = String.fromEnvironment(
    'TMDB_LANGUAGE',
    defaultValue: 'vi-VN',
  );
}