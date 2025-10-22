import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/config/chat_config.dart';
import '../models/message.dart';

class SimpleHubService {
  static String get _baseUrl => ChatConfig.fullWsUrl;
  WebSocketChannel? _channel;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Stream controllers for real-time updates
  final StreamController<Message> _messageController = StreamController<Message>.broadcast();
  final StreamController<Map<String, dynamic>> _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _stopTypingController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messageSeenController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _conversationReadController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Message> _messageReactionController = StreamController<Message>.broadcast();
  final StreamController<Map<String, dynamic>> _messageReactionRemovedController = StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<Message> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get stopTypingStream => _stopTypingController.stream;
  Stream<Map<String, dynamic>> get messageSeenStream => _messageSeenController.stream;
  Stream<Map<String, dynamic>> get conversationReadStream => _conversationReadController.stream;
  Stream<Message> get messageReactionStream => _messageReactionController.stream;
  Stream<Map<String, dynamic>> get messageReactionRemovedStream => _messageReactionRemovedController.stream;

  Future<void> start() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No auth token found');
    }

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$_baseUrl?access_token=$token'),
      );

      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          print('WebSocket error: $error');
          // Try to reconnect after error
          Future.delayed(const Duration(seconds: 5), () {
            if (_channel == null) {
              start();
            }
          });
        },
        onDone: () {
          print('WebSocket connection closed');
          // Try to reconnect
          Future.delayed(const Duration(seconds: 5), () {
            if (_channel == null) {
              start();
            }
          });
        },
      );

      print('WebSocket connected');
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      rethrow;
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data);
      final method = message['method'] as String?;
      final arguments = message['arguments'] as List?;

      switch (method) {
        case 'ReceiveMessage':
          if (arguments != null && arguments.isNotEmpty) {
            final messageJson = arguments[0] as Map<String, dynamic>;
            final msg = Message.fromJson(messageJson);
            _messageController.add(msg);
          }
          break;
        case 'UserTyping':
          if (arguments != null && arguments.isNotEmpty) {
            final data = arguments[0] as Map<String, dynamic>;
            _typingController.add(data);
          }
          break;
        case 'UserStopTyping':
          if (arguments != null && arguments.isNotEmpty) {
            final data = arguments[0] as Map<String, dynamic>;
            _stopTypingController.add(data);
          }
          break;
        case 'MessageSeen':
          if (arguments != null && arguments.isNotEmpty) {
            final data = arguments[0] as Map<String, dynamic>;
            _messageSeenController.add(data);
          }
          break;
        case 'ConversationRead':
          if (arguments != null && arguments.isNotEmpty) {
            final data = arguments[0] as Map<String, dynamic>;
            _conversationReadController.add(data);
          }
          break;
        case 'MessageReactionAdded':
          if (arguments != null && arguments.isNotEmpty) {
            final messageJson = arguments[0] as Map<String, dynamic>;
            final msg = Message.fromJson(messageJson);
            _messageReactionController.add(msg);
          }
          break;
        case 'MessageReactionRemoved':
          if (arguments != null && arguments.isNotEmpty) {
            final data = arguments[0] as Map<String, dynamic>;
            _messageReactionRemovedController.add(data);
          }
          break;
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  Future<void> sendMessage(int conversationId, String content, {String? mediaUrl, String? mediaType}) async {
    if (_channel == null) throw Exception('Hub not started');
    
    final message = {
      'method': 'SendMessage',
      'arguments': [conversationId, content, mediaUrl, mediaType],
    };
    
    _channel!.sink.add(jsonEncode(message));
  }

  Future<void> startTyping(int conversationId) async {
    if (_channel == null) throw Exception('Hub not started');
    
    final message = {
      'method': 'Typing',
      'arguments': [conversationId],
    };
    
    _channel!.sink.add(jsonEncode(message));
  }

  Future<void> stopTyping(int conversationId) async {
    if (_channel == null) throw Exception('Hub not started');
    
    final message = {
      'method': 'StopTyping',
      'arguments': [conversationId],
    };
    
    _channel!.sink.add(jsonEncode(message));
  }

  Future<void> markSeen(int conversationId, int messageId) async {
    if (_channel == null) throw Exception('Hub not started');
    
    final message = {
      'method': 'MarkSeen',
      'arguments': [conversationId, messageId],
    };
    
    _channel!.sink.add(jsonEncode(message));
  }

  Future<void> markConversationAsRead(int conversationId) async {
    if (_channel == null) throw Exception('Hub not started');
    
    final message = {
      'method': 'MarkConversationAsRead',
      'arguments': [conversationId],
    };
    
    _channel!.sink.add(jsonEncode(message));
  }

  Future<void> addReaction(int messageId, String reaction) async {
    if (_channel == null) throw Exception('Hub not started');
    
    final message = {
      'method': 'AddReaction',
      'arguments': [messageId, reaction],
    };
    
    _channel!.sink.add(jsonEncode(message));
  }

  Future<void> removeReaction(int messageId) async {
    if (_channel == null) throw Exception('Hub not started');
    
    final message = {
      'method': 'RemoveReaction',
      'arguments': [messageId],
    };
    
    _channel!.sink.add(jsonEncode(message));
  }

  Future<void> joinConversation(int conversationId) async {
    if (_channel == null) throw Exception('Hub not started');
    
    final message = {
      'method': 'JoinConversation',
      'arguments': [conversationId],
    };
    
    _channel!.sink.add(jsonEncode(message));
  }

  Future<void> leaveConversation(int conversationId) async {
    if (_channel == null) throw Exception('Hub not started');
    
    final message = {
      'method': 'LeaveConversation',
      'arguments': [conversationId],
    };
    
    _channel!.sink.add(jsonEncode(message));
  }

  Future<void> stop() async {
    await _channel?.sink.close();
    await _messageController.close();
    await _typingController.close();
    await _stopTypingController.close();
    await _messageSeenController.close();
    await _conversationReadController.close();
    await _messageReactionController.close();
    await _messageReactionRemovedController.close();
  }

  bool get isConnected => _channel != null;
}
