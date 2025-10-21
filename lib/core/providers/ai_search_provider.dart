import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/movie.dart';
import '../services/gemini_service.dart';
import '../config/app_config.dart';

// AI Search State
class AiSearchState {
  final List<Movie> movies;
  final bool isLoading;
  final String? error;
  final String lastQuery;

  const AiSearchState({
    this.movies = const [],
    this.isLoading = false,
    this.error,
    this.lastQuery = '',
  });

  AiSearchState copyWith({
    List<Movie>? movies,
    bool? isLoading,
    String? error,
    String? lastQuery,
  }) {
    return AiSearchState(
      movies: movies ?? this.movies,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastQuery: lastQuery ?? this.lastQuery,
    );
  }
}

// AI Search Notifier
class AiSearchNotifier extends StateNotifier<AiSearchState> {
  late final GeminiService _geminiService;
  
  AiSearchNotifier() : super(const AiSearchState()) {
    // Khởi tạo Dio cho TMDB API
    final dio = Dio(BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      queryParameters: {'api_key': AppConfig.tmdbApiKey},
    ));
    _geminiService = GeminiService(tmdb: dio);
  }

  // Tìm kiếm bằng ngôn ngữ tự nhiên
  Future<void> searchByNaturalLanguage(String query) async {
    if (query.trim().isEmpty) return;
    
    state = state.copyWith(
      isLoading: true,
      error: null,
      lastQuery: query,
    );

    try {
      print('🔍 AI Search: Bắt đầu tìm kiếm "$query"');
      
      // Sử dụng service mới - trả về dữ liệu phim trực tiếp từ TMDB
      final movieData = await _geminiService.searchMoviesByNaturalLanguage(query);
      
      print('🔍 AI Search: Tìm được ${movieData.length} kết quả');
      
      if (movieData.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          movies: [],
          error: 'Không tìm thấy phim phù hợp',
        );
        return;
      }

      // Chuyển đổi dữ liệu thành Movie objects
      final movies = <Movie>[];
      for (int i = 0; i < movieData.length; i++) {
        try {
          final movie = Movie.fromJson(movieData[i]);
          movies.add(movie);
          print('✅ Movie $i: ${movie.title}');
        } catch (e) {
          print('❌ Lỗi parse movie $i: $e');
          print('Data: ${movieData[i]}');
        }
      }

      print('🔍 AI Search: Parse thành công ${movies.length} phim');

      state = state.copyWith(
        isLoading: false,
        movies: movies,
        error: null,
      );
    } catch (e) {
      print('❌ AI Search Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi tìm kiếm: ${e.toString()}',
      );
    }
  }

  // Tìm kiếm theo tâm trạng
  Future<void> searchByMood(String mood) async {
    if (mood.trim().isEmpty) return;
    
    state = state.copyWith(
      isLoading: true,
      error: null,
      lastQuery: mood,
    );

    try {
      // Sử dụng service mới
      final movieData = await _geminiService.getMoviesByMood(mood);
      
      if (movieData.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          movies: [],
          error: 'Không tìm thấy phim phù hợp với tâm trạng này',
        );
        return;
      }

      // Chuyển đổi dữ liệu thành Movie objects
      final movies = movieData.map((data) => Movie.fromJson(data)).toList();

      state = state.copyWith(
        isLoading: false,
        movies: movies,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi tìm kiếm: ${e.toString()}',
      );
    }
  }

  // Tìm kiếm theo thể loại
  Future<void> searchByGenre(String genre) async {
    if (genre.trim().isEmpty) return;
    
    state = state.copyWith(
      isLoading: true,
      error: null,
      lastQuery: genre,
    );

    try {
      // Sử dụng service mới
      final movieData = await _geminiService.getMoviesByGenre(genre);
      
      if (movieData.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          movies: [],
          error: 'Không tìm thấy phim thuộc thể loại này',
        );
        return;
      }

      // Chuyển đổi dữ liệu thành Movie objects
      final movies = movieData.map((data) => Movie.fromJson(data)).toList();

      state = state.copyWith(
        isLoading: false,
        movies: movies,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi tìm kiếm: ${e.toString()}',
      );
    }
  }

  // Tìm kiếm theo mô tả chi tiết
  Future<void> searchByDescription(String description) async {
    if (description.trim().isEmpty) return;
    
    state = state.copyWith(
      isLoading: true,
      error: null,
      lastQuery: description,
    );

    try {
      // Sử dụng service mới
      final movieData = await _geminiService.getMovieRecommendationsByDescription(description);
      
      if (movieData.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          movies: [],
          error: 'Không tìm thấy phim phù hợp với mô tả này',
        );
        return;
      }

      // Chuyển đổi dữ liệu thành Movie objects
      final movies = movieData.map((data) => Movie.fromJson(data)).toList();

      state = state.copyWith(
        isLoading: false,
        movies: movies,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi tìm kiếm: ${e.toString()}',
      );
    }
  }

  // Tìm kiếm theo năm và thể loại
  Future<void> searchByYearAndGenre(int year, String genre) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      lastQuery: '$genre $year',
    );

    try {
      // Sử dụng service mới
      final movieData = await _geminiService.getMoviesByYearAndGenre(year, genre);
      
      if (movieData.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          movies: [],
          error: 'Không tìm thấy phim thuộc thể loại $genre năm $year',
        );
        return;
      }

      // Chuyển đổi dữ liệu thành Movie objects
      final movies = movieData.map((data) => Movie.fromJson(data)).toList();

      state = state.copyWith(
        isLoading: false,
        movies: movies,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi tìm kiếm: ${e.toString()}',
      );
    }
  }

  // Xóa kết quả tìm kiếm
  void clearResults() {
    state = const AiSearchState();
  }

  // Làm mới tìm kiếm
  void refreshSearch() {
    if (state.lastQuery.isNotEmpty) {
      searchByNaturalLanguage(state.lastQuery);
    }
  }
}

// Provider
final aiSearchProvider = StateNotifierProvider<AiSearchNotifier, AiSearchState>((ref) {
  return AiSearchNotifier();
});

// Provider cho việc tìm kiếm nhanh
final quickAiSearchProvider = FutureProvider.family<List<Movie>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  
  try {
    // Khởi tạo service
    final dio = Dio(BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      queryParameters: {'api_key': AppConfig.tmdbApiKey},
    ));
    final geminiService = GeminiService(tmdb: dio);
    
    // Sử dụng service mới
    final movieData = await geminiService.searchMoviesByNaturalLanguage(query);
    
    // Chuyển đổi dữ liệu thành Movie objects
    final movies = movieData.take(5).map((data) => Movie.fromJson(data)).toList();
    
    return movies;
  } catch (e) {
    return [];
  }
});
