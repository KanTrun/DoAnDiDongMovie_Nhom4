import 'package:dio/dio.dart';
import '../models/note.dart';
import '../network/api_client.dart';

class NotesService {
  final String? _token;

  NotesService(this._token);

  Future<PagedNotesResponse> getNotes({int page = 1, int pageSize = 20}) async {
    try {
      final response = await ApiClient.backend(token: _token).get(
        '/api/notes',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return PagedNotesResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Note>> getNotesByMovie(int tmdbId, String mediaType) async {
    try {
      print('🔍 NOTES SERVICE - Getting notes for movie: $tmdbId, mediaType: $mediaType');
      print('🔑 NOTES SERVICE - Token: ${_token != null ? "Present" : "NULL"}');
      
      final response = await ApiClient.backend(token: _token).get(
        '/api/notes/movie/$tmdbId',
        queryParameters: {
          'mediaType': mediaType,
        },
      );
      
      print('✅ NOTES SERVICE - Response received: ${response.statusCode}');
      print('📄 NOTES SERVICE - Response data: ${response.data}');
      
      return (response.data as List)
          .map((noteJson) => Note.fromJson(noteJson))
          .toList();
    } on DioException catch (e) {
      print('❌ NOTES SERVICE - DioException caught');
      throw _handleError(e);
    } catch (e) {
      print('❌ NOTES SERVICE - General exception: $e');
      throw e.toString();
    }
  }

  Future<Note> createNote({
    required int tmdbId,
    required String mediaType,
    required String content,
  }) async {
    try {
      final response = await ApiClient.backend(token: _token).post(
        '/api/notes',
        data: {
          'tmdbId': tmdbId,
          'mediaType': mediaType,
          'content': content,
        },
      );
      return Note.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Note> updateNote({
    required int id,
    required String content,
  }) async {
    try {
      final response = await ApiClient.backend(token: _token).put(
        '/api/notes/$id',
        data: {
          'content': content,
        },
      );
      return Note.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await ApiClient.backend(token: _token).delete('/api/notes/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    print('❌ NOTES SERVICE ERROR:');
    print('   Status: ${e.response?.statusCode}');
    print('   Message: ${e.message}');
    print('   Data: ${e.response?.data}');
    print('   Headers: ${e.response?.headers}');
    
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        return data['message'];
      }
      if (data is String) {
        return data;
      }
    }
    return 'An error occurred while processing your request';
  }
}
