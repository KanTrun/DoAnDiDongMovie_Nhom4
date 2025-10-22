import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/config/chat_config.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/contact.dart';

class ChatApiService {
  static String get _baseUrl => ChatConfig.fullApiUrl;
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ChatApiService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers['ngrok-skip-browser-warning'] = 'true';
  }

  Future<void> _setAuthHeader() async {
    String? token = await _storage.read(key: 'auth_token') ?? await _storage.read(key: 'jwt_token');
    if (token != null) _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<T> _handleRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token expired, clear storage
        await _storage.delete(key: 'auth_token');
        throw Exception('Authentication failed. Please login again.');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timeout. Please try again.');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // Conversations
  Future<List<Conversation>> getConversations() async {
    return _handleRequest(() async {
      await _setAuthHeader();
      final res = await _dio.get('/conversations');
      final list = (res.data as List).map((j) => Conversation.fromJson(j)).toList();
      // chuẩn hoá timezone: mọi DateTime coi như UTC và lưu nguyên bản
      return list;
    });
  }

  Future<Conversation> getConversation(int id) async {
    return await _handleRequest(() async {
      await _setAuthHeader();
      final response = await _dio.get('/conversations/$id');
      return Conversation.fromJson(response.data);
    });
  }

  Future<Conversation> createConversation({
    required bool isGroup,
    String? title,
    required List<String> participantIds,
  }) async {
    return await _handleRequest(() async {
      await _setAuthHeader();
      final response = await _dio.post('/conversations', data: {
        'isGroup': isGroup,
        'title': title,
        'participantIds': participantIds,
      });
      return Conversation.fromJson(response.data);
    });
  }

  Future<void> addParticipant(int conversationId, int userId) async {
    await _handleRequest(() async {
      await _setAuthHeader();
      await _dio.post('/conversations/$conversationId/participants', data: {
        'userId': userId,
      });
    });
  }

  Future<void> removeParticipant(int conversationId, int participantId) async {
    await _handleRequest(() async {
      await _setAuthHeader();
      await _dio.delete('/conversations/$conversationId/participants/$participantId');
    });
  }

  Future<void> markConversationAsRead(int conversationId) async {
    await _handleRequest(() async {
      await _setAuthHeader();
      await _dio.post('/conversations/$conversationId/read');
    });
  }

  // Messages
  Future<List<Message>> getMessages(int conversationId, {int page = 1, int pageSize = 50}) async {
    print('DEBUG API: Getting messages for conversation $conversationId');
    return _handleRequest(() async {
      await _setAuthHeader();
      print('DEBUG API: Making request to /conversations/$conversationId/messages');
      final res = await _dio.get('/conversations/$conversationId/messages', queryParameters: {
        'page': page,
        'pageSize': pageSize,
      });
      print('DEBUG API: Response received, status: ${res.statusCode}');
      final list = (res.data as List).map((j) => Message.fromJson(j)).toList();
      print('DEBUG API: Parsed ${list.length} messages');
      // sort ASC để UI hiển thị từ cũ → mới
      list.sort((a,b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  Future<Message> sendMessage(int conversationId, CreateMessage data) async {
    return _handleRequest(() async {
      await _setAuthHeader();
      final res = await _dio.post('/conversations/$conversationId/messages', data: data.toJson());
      return Message.fromJson(res.data);
    });
  }

  Future<Message> editMessage(int conversationId, int messageId, String content) async {
    return await _handleRequest(() async {
      await _setAuthHeader();
      final response = await _dio.put('/conversations/$conversationId/messages/$messageId', data: {
        'content': content,
      });
      return Message.fromJson(response.data);
    });
  }

  Future<void> deleteMessage(int conversationId, int messageId) async {
    await _handleRequest(() async {
      await _setAuthHeader();
      await _dio.delete('/conversations/$conversationId/messages/$messageId');
    });
  }

  Future<void> markMessageAsRead(int conversationId, int messageId) async {
    await _handleRequest(() async {
      await _setAuthHeader();
      await _dio.post('/conversations/$conversationId/messages/$messageId/read');
    });
  }

  Future<Message> addReaction(int conversationId, int messageId, String reaction) async {
    return await _handleRequest(() async {
      await _setAuthHeader();
      final response = await _dio.post('/conversations/$conversationId/messages/$messageId/reactions', data: {
        'reaction': reaction,
      });
      return Message.fromJson(response.data);
    });
  }

  Future<void> removeReaction(int conversationId, int messageId) async {
    await _handleRequest(() async {
      await _setAuthHeader();
      await _dio.delete('/conversations/$conversationId/messages/$messageId/reactions');
    });
  }

  // Contacts
  Future<List<Contact>> getContacts({String? filter}) async {
    return await _handleRequest(() async {
      await _setAuthHeader();
      final response = await _dio.get('/contacts', queryParameters: {
        if (filter != null) 'filter': filter,
      });
      return (response.data as List)
          .map((json) => Contact.fromJson(json))
          .toList();
    });
  }

  Future<List<Contact>> getFollowing() async {
    return await _handleRequest(() async {
      await _setAuthHeader();
      final response = await _dio.get('/contacts/following');
      return (response.data as List)
          .map((json) => Contact.fromJson(json))
          .toList();
    });
  }

  // Device Tokens
  Future<void> registerDeviceToken(String deviceToken, {String? platform}) async {
    await _handleRequest(() async {
      await _setAuthHeader();
      await _dio.post('/devicetokens', data: {
        'deviceToken': deviceToken,
        'platform': platform,
      });
    });
  }

  Future<void> unregisterDeviceToken(String deviceToken) async {
    await _handleRequest(() async {
      await _setAuthHeader();
      await _dio.delete('/devicetokens/$deviceToken');
    });
  }

}
