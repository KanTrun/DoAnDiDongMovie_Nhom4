import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class FcmService {
  static final ChatApiService _apiService = ChatApiService();
  
  static final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  static Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  static Future<void> initialize() async {
    if (kIsWeb) {
      print('FCM initialization skipped on web platform');
      return;
    }

    // For mobile platforms, we'll use a different approach
    // Since Firebase messaging has compatibility issues, we'll skip it for now
    print('FCM initialization skipped due to compatibility issues');
  }

  static Future<void> _handleForegroundMessage(Map<String, dynamic> data) async {
    print('Received message: $data');
    
    if (data.containsKey('conversationId')) {
      _messageController.add(data);
    }
  }

  static Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    print('Notification tapped: $data');
    
    if (data.containsKey('conversationId')) {
      _messageController.add(data);
    }
  }

  static Future<void> unregister() async {
    print('FCM unregister called (no-op)');
    // No-op for now due to compatibility issues
  }
}
