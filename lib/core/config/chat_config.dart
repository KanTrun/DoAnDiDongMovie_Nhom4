class ChatConfig {
  // API Configuration
  static const String apiBaseUrl = 'https://silvana-detainable-nongratifyingly.ngrok-free.dev/api';
  static const String wsBaseUrl = 'wss://silvana-detainable-nongratifyingly.ngrok-free.dev';
  
  // SignalR Hub endpoint
  static const String hubEndpoint = '/chathub';
  
  // Full URLs
  static String get fullApiUrl => apiBaseUrl;
  static String get fullWsUrl => '$wsBaseUrl$hubEndpoint';
  
  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  
  // Retry configurations
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
