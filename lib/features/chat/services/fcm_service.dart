import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

class FcmService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final ChatApiService _apiService = ChatApiService();
  
  static final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  static Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  static Future<void> initialize() async {
    // Request permission
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      await _apiService.registerDeviceToken(token, platform: 'flutter');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      print('FCM Token refreshed: $newToken');
      await _apiService.registerDeviceToken(newToken, platform: 'flutter');
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    
    final data = message.data;
    if (data.containsKey('conversationId')) {
      _messageController.add(data);
    }
  }

  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('Notification tapped: ${message.messageId}');
    
    final data = message.data;
    if (data.containsKey('conversationId')) {
      _messageController.add(data);
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
    
    // You can perform background tasks here
    // Note: This function must be top-level
  }

  static Future<void> unregister() async {
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _apiService.unregisterDeviceToken(token);
    }
  }
}

// This function must be top-level for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}
