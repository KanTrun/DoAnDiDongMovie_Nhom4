import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/config/chat_config.dart';
import '../models/message.dart';
import 'api_service.dart';

class ChatHubService {
  static String get _baseUrl => ChatConfig.fullWsUrl;

  final _storage = const FlutterSecureStorage();
  final _api = ChatApiService();

  WebSocketChannel? _channel;
  Timer? _pollingTimer;
  bool _isPolling = false;
  int? _lastMessageId;
  final _joined = <int>{};

  // streams
  final _msgCtrl = StreamController<Message>.broadcast();
  final _typingCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _stopTypingCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _seenCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _reactionCtrl = StreamController<Message>.broadcast();

  Stream<Message> get messageStream => _msgCtrl.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingCtrl.stream;
  Stream<Map<String, dynamic>> get stopTypingStream => _stopTypingCtrl.stream;
  Stream<Map<String, dynamic>> get messageSeenStream => _seenCtrl.stream;
  Stream<Message> get messageReactionStream => _reactionCtrl.stream;

  Future<void> start() async {
    if (_channel != null) {
      print('DEBUG HUB: Already started');
      return;
    }

    print('DEBUG HUB: Starting hub service...');
    final token = await _storage.read(key: 'auth_token') ?? await _storage.read(key: 'jwt_token');
    if (token == null) {
      print('DEBUG HUB: No auth token found');
      throw Exception('No auth token');
    }

    final wsUrl = '$_baseUrl?access_token=$token';
    print('DEBUG HUB: WebSocket URL: $wsUrl');
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.stream.listen(
        _handleInbound,
        onError: (error) {
          print('DEBUG HUB: WebSocket error: $error');
          _fallbackToPolling();
        },
        onDone: () {
          print('DEBUG HUB: WebSocket connection closed');
          _fallbackToPolling();
        },
        cancelOnError: true,
      );
      print('DEBUG HUB: WebSocket connected successfully');
    } catch (e) {
      print('DEBUG HUB: WebSocket connection failed: $e');
      _fallbackToPolling();
    }
  }

  void _fallbackToPolling() {
    _channel = null;
    if (_isPolling) return;
    _isPolling = true;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      for (final id in _joined) {
        try {
          final list = await _api.getMessages(id, page: 1, pageSize: 30);
          for (final m in list) {
            if (_lastMessageId == null || m.id > _lastMessageId!) {
              _lastMessageId = m.id;
              _msgCtrl.add(m);
            }
          }
        } catch (_) {}
      }
    });
  }

  void _handleInbound(dynamic data) {
    try {
      final root = jsonDecode(data);
      final method = root['method'] as String?;
      final args = root['arguments'] as List?;

      switch (method) {
        case 'ReceiveMessage':
          if (args?.isNotEmpty == true) {
            final m = Message.fromJson(args![0] as Map<String, dynamic>);
            if (_lastMessageId == null || m.id > _lastMessageId!) _lastMessageId = m.id;
            _msgCtrl.add(m);
          }
          break;
        case 'UserTyping':
          if (args?.isNotEmpty == true) _typingCtrl.add(args![0] as Map<String, dynamic>);
          break;
        case 'UserStopTyping':
          if (args?.isNotEmpty == true) _stopTypingCtrl.add(args![0] as Map<String, dynamic>);
          break;
        case 'MessageSeen':
          if (args?.isNotEmpty == true) _seenCtrl.add(args![0] as Map<String, dynamic>);
          break;
        case 'MessageReactionAdded':
          if (args?.isNotEmpty == true) _reactionCtrl.add(Message.fromJson(args![0] as Map<String, dynamic>));
          break;
      }
    } catch (_) {}
  }

  // client → server
  Future<void> sendMessage(int conversationId, String content, {String? mediaUrl, String? mediaType}) async {
    if (_channel == null) throw Exception('Hub not started');
    _channel!.sink.add(jsonEncode({'method':'SendMessage','arguments':[conversationId, content, mediaUrl, mediaType]}));
  }

  Future<void> startTyping(int conversationId) async {
    _channel?.sink.add(jsonEncode({'method':'Typing','arguments':[conversationId]}));
  }

  Future<void> stopTyping(int conversationId) async {
    _channel?.sink.add(jsonEncode({'method':'StopTyping','arguments':[conversationId]}));
  }

  Future<void> joinConversation(int conversationId) async {
    _joined.add(conversationId);
    _channel?.sink.add(jsonEncode({'method':'JoinConversation','arguments':[conversationId]}));
  }

  Future<void> leaveConversation(int conversationId) async {
    _joined.remove(conversationId);
    _channel?.sink.add(jsonEncode({'method':'LeaveConversation','arguments':[conversationId]}));
  }

  Future<void> stop() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    _joined.clear();
    await _channel?.sink.close();
    _channel = null;
  }

  bool get isConnected => _channel != null;
}
