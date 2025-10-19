import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  print('🧪 Testing TMDB API directly...');
  
  final dio = Dio();
  const apiKey = '2daf813d8e3ba7435e678ee33d90d6e9';
  const baseUrl = 'https://api.themoviedb.org/3';
  
  try {
    print('\n🔍 Testing search for "thỏa thuận bí mật"');
    
    // Test 1: Search movies
    print('\n🎬 Testing movie search...');
    final movieResponse = await dio.get(
      '$baseUrl/search/movie',
      queryParameters: {
        'api_key': apiKey,
        'query': 'thỏa thuận bí mật',
        'include_adult': false,
      },
    );
    
    print('📊 Movie search status: ${movieResponse.statusCode}');
    final movieData = movieResponse.data;
    print('📊 Movie results count: ${movieData['results']?.length ?? 0}');
    
    if (movieData['results'] != null && (movieData['results'] as List).isNotEmpty) {
      final firstMovie = (movieData['results'] as List).first;
      print('🎬 First movie: ${firstMovie['title']} (${firstMovie['original_language']})');
    }
    
    // Test 2: Search TV shows
    print('\n📺 Testing TV search...');
    final tvResponse = await dio.get(
      '$baseUrl/search/tv',
      queryParameters: {
        'api_key': apiKey,
        'query': 'thỏa thuận bí mật',
        'include_adult': false,
      },
    );
    
    print('📊 TV search status: ${tvResponse.statusCode}');
    final tvData = tvResponse.data;
    print('📊 TV results count: ${tvData['results']?.length ?? 0}');
    
    if (tvData['results'] != null && (tvData['results'] as List).isNotEmpty) {
      final firstTv = (tvData['results'] as List).first;
      print('📺 First TV: ${firstTv['name']} (${firstTv['original_language']})');
      print('📺 TV ID: ${firstTv['id']}');
      print('📺 TV Overview: ${firstTv['overview']}');
    }
    
    // Test 3: Search with Thai language (since the show is Thai)
    print('\n🇹🇭 Testing with Thai language...');
    final thaiResponse = await dio.get(
      '$baseUrl/search/tv',
      queryParameters: {
        'api_key': apiKey,
        'query': 'thỏa thuận bí mật',
        'language': 'th',
        'include_adult': false,
      },
    );
    
    print('📊 Thai TV search status: ${thaiResponse.statusCode}');
    final thaiData = thaiResponse.data;
    print('📊 Thai TV results count: ${thaiData['results']?.length ?? 0}');
    
    if (thaiData['results'] != null && (thaiData['results'] as List).isNotEmpty) {
      final firstThaiTv = (thaiData['results'] as List).first;
      print('🇹🇭 Thai TV: ${firstThaiTv['name']} (${firstThaiTv['original_language']})');
    }
    
  } catch (e) {
    print('❌ API test failed: $e');
  }
  
  print('\n✅ API test completed!');
  exit(0);
}



