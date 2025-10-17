import 'package:dio/dio.dart';
import '../models/movie.dart';
import '../network/api_client.dart';
import 'translation_service.dart';

class TmdbService {
  // Discover Movies
  static Future<MovieResponse> getPopularMovies({int page = 1}) async {
    try {
      final response = await ApiClient.tmdb().get(
        '/movie/popular',
        queryParameters: {'page': page},
      );
      return MovieResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<MovieResponse> getTopRatedMovies({int page = 1}) async {
    try {
      final response = await ApiClient.tmdb().get(
        '/movie/top_rated',
        queryParameters: {'page': page},
      );
      return MovieResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<MovieResponse> getUpcomingMovies({int page = 1}) async {
    try {
      final response = await ApiClient.tmdb().get(
        '/movie/upcoming',
        queryParameters: {'page': page},
      );
      return MovieResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<MovieResponse> getNowPlayingMovies({int page = 1}) async {
    try {
      final response = await ApiClient.tmdb().get(
        '/movie/now_playing',
        queryParameters: {'page': page},
      );
      return MovieResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<MovieResponse> getTrendingMovies({
    String timeWindow = 'day',
    int page = 1,
  }) async {
    try {
      final response = await ApiClient.tmdb().get(
        '/trending/movie/$timeWindow',
        queryParameters: {'page': page},
      );
      return MovieResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<MovieResponse> discoverMovies({
    int page = 1,
    String? sortBy,
    String? withGenres,
    String? withoutGenres,
    double? voteAverageGte,
    double? voteAverageLte,
    String? releaseDateGte,
    String? releaseDateLte,
    String? withOriginalLanguage,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (withGenres != null) queryParams['with_genres'] = withGenres;
      if (withoutGenres != null) queryParams['without_genres'] = withoutGenres;
      if (voteAverageGte != null) queryParams['vote_average.gte'] = voteAverageGte;
      if (voteAverageLte != null) queryParams['vote_average.lte'] = voteAverageLte;
      if (releaseDateGte != null) queryParams['release_date.gte'] = releaseDateGte;
      if (releaseDateLte != null) queryParams['release_date.lte'] = releaseDateLte;
      if (withOriginalLanguage != null) queryParams['with_original_language'] = withOriginalLanguage;

      final response = await ApiClient.tmdb().get(
        '/discover/movie',
        queryParameters: queryParams,
      );
      return MovieResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Search
  static Future<MovieResponse> searchMovies(String query, {int page = 1}) async {
    try {
      final response = await ApiClient.tmdb().get(
        '/search/movie',
        queryParameters: {
          'query': query,
          'page': page,
        },
      );
      return MovieResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Movie Details
  static Future<MovieDetail> getMovieDetails(int movieId) async {
    try {
      // Try to get Vietnamese content first, then fallback to English if overview is empty
      final response = await ApiClient.tmdb().get(
        '/movie/$movieId',
        queryParameters: {
          'append_to_response': 'videos,credits,similar,recommendations,translations',
          'language': 'vi-VN',
        },
      );
      
      final movieDetail = MovieDetail.fromJson(response.data);
      
      // If overview is empty or very short, try to get English version
      if (movieDetail.overview.isEmpty || movieDetail.overview.length < 20) {
        try {
          final englishResponse = await ApiClient.tmdb().get(
            '/movie/$movieId',
            queryParameters: {
              'append_to_response': 'videos,credits,similar,recommendations',
              'language': 'en-US',
            },
          );
          
          final englishMovieDetail = MovieDetail.fromJson(englishResponse.data);
          
          // Use English overview if Vietnamese is not available or too short
          if (englishMovieDetail.overview.isNotEmpty && 
              englishMovieDetail.overview.length > movieDetail.overview.length) {
            return MovieDetail(
              id: movieDetail.id,
              title: movieDetail.title.isNotEmpty ? movieDetail.title : englishMovieDetail.title,
              overview: englishMovieDetail.overview,
              posterPath: movieDetail.posterPath,
              backdropPath: movieDetail.backdropPath,
              releaseDate: movieDetail.releaseDate,
              voteAverage: movieDetail.voteAverage,
              voteCount: movieDetail.voteCount,
              popularity: movieDetail.popularity,
              originalLanguage: movieDetail.originalLanguage,
              genreIds: movieDetail.genreIds,
              adult: movieDetail.adult,
              video: movieDetail.video,
              originalTitle: movieDetail.originalTitle,
              budget: movieDetail.budget,
              genres: movieDetail.genres.isNotEmpty ? movieDetail.genres : englishMovieDetail.genres,
              homepage: movieDetail.homepage.isNotEmpty ? movieDetail.homepage : englishMovieDetail.homepage,
              imdbId: movieDetail.imdbId,
              revenue: movieDetail.revenue,
              runtime: movieDetail.runtime,
              status: movieDetail.status.isNotEmpty ? movieDetail.status : englishMovieDetail.status,
              tagline: movieDetail.tagline.isNotEmpty ? movieDetail.tagline : englishMovieDetail.tagline,
              productionCompanies: movieDetail.productionCompanies.isNotEmpty ? movieDetail.productionCompanies : englishMovieDetail.productionCompanies,
              productionCountries: movieDetail.productionCountries.isNotEmpty ? movieDetail.productionCountries : englishMovieDetail.productionCountries,
              spokenLanguages: movieDetail.spokenLanguages.isNotEmpty ? movieDetail.spokenLanguages : englishMovieDetail.spokenLanguages,
              cast: movieDetail.cast.isNotEmpty ? movieDetail.cast : englishMovieDetail.cast,
              crew: movieDetail.crew.isNotEmpty ? movieDetail.crew : englishMovieDetail.crew,
            );
          }
        } catch (e) {
          // If English request fails, just return the Vietnamese version
          print('Failed to fetch English version: $e');
        }
      }
      
      return movieDetail;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }


  static Future<Map<String, dynamic>> getMovieCredits(int movieId) async {
    try {
      final response = await ApiClient.tmdb().get('/movie/$movieId/credits');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<MovieResponse> getSimilarMovies(int movieId, {int page = 1}) async {
    try {
      final response = await ApiClient.tmdb().get(
        '/movie/$movieId/similar',
        queryParameters: {'page': page},
      );
      return MovieResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<MovieResponse> getRecommendedMovies(int movieId, {int page = 1}) async {
    try {
      final response = await ApiClient.tmdb().get(
        '/movie/$movieId/recommendations',
        queryParameters: {'page': page},
      );
      return MovieResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Genres
  static Future<List<Genre>> getGenres() async {
    try {
      final response = await ApiClient.tmdb().get('/genre/movie/list');
      return (response.data['genres'] as List)
          .map((json) => Genre.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Person
  static Future<Map<String, dynamic>> getPersonDetails(int personId) async {
    try {
      print('Fetching person details for ID: $personId');
      
      // Try to get Vietnamese content first
      final response = await ApiClient.tmdb().get(
        '/person/$personId',
        queryParameters: {
          'append_to_response': 'movie_credits,tv_credits,images,external_ids',
          'language': 'vi-VN', // Override default language
        },
      );
      
      final personData = response.data as Map<String, dynamic>;
      print('Vietnamese response received for ${personData['name']}');
      print('Vietnamese biography length: ${(personData['biography'] as String?)?.length ?? 0}');
      
      // If biography is empty or very short, try to get English version
      final biography = personData['biography'] as String? ?? '';
      if (biography.isEmpty || biography.length < 20) {
        print('Vietnamese biography too short (${biography.length} chars), trying English...');
        try {
          final englishResponse = await ApiClient.tmdb().get(
            '/person/$personId',
            queryParameters: {
              'append_to_response': 'movie_credits,tv_credits,images,external_ids',
              'language': 'en-US', // Override default language
            },
          );
          
          final englishData = englishResponse.data as Map<String, dynamic>;
          final englishBio = englishData['biography'] as String? ?? '';
          
          print('English biography length: ${englishBio.length}');
          
          // Always use English biography if Vietnamese is empty/short
          if (englishBio.isNotEmpty) {
            // Try to translate to Vietnamese
            try {
              final translationService = TranslationService();
              final vietnameseBio = await translationService.translateToVietnamese(englishBio);
              
              if (vietnameseBio.isNotEmpty && vietnameseBio != englishBio) {
                personData['biography'] = vietnameseBio;
                personData['biography_language'] = 'vi';
                personData['original_biography'] = englishBio; // Keep original for reference
                print('✅ Using translated Vietnamese biography (${vietnameseBio.length} chars)');
              } else {
                personData['biography'] = englishBio;
                personData['biography_language'] = 'en';
                print('⚠️  Translation failed, using English biography (${englishBio.length} chars)');
              }
            } catch (e) {
              print('❌ Translation error: $e, using English biography');
              personData['biography'] = englishBio;
              personData['biography_language'] = 'en';
            }
          } else {
            personData['biography_language'] = 'vi';
            print('⚠️  No English biography available either');
          }
          
          // Also merge other English data that might be missing
          if (englishData['also_known_as'] != null && (personData['also_known_as'] == null || (personData['also_known_as'] as List).isEmpty)) {
            personData['also_known_as'] = englishData['also_known_as'];
          }
          
        } catch (e) {
          print('❌ Failed to fetch English biography for person $personId: $e');
          personData['biography_language'] = 'vi';
        }
      } else {
        personData['biography_language'] = 'vi';
        print('✅ Using Vietnamese biography (${biography.length} chars)');
      }
      
      print('Final biography length: ${(personData['biography'] as String?)?.length ?? 0}');
      return personData;
    } on DioException catch (e) {
      print('Error fetching person details: ${e.message}');
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> searchPeople(String query, {int page = 1}) async {
    try {
      final response = await ApiClient.tmdb().get(
        '/search/person',
        queryParameters: {
          'query': query,
          'page': page,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Configuration
  static Future<Map<String, dynamic>> getConfiguration() async {
    try {
      final response = await ApiClient.tmdb().get('/configuration');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get movie videos (trailers, teasers, etc.)
  static Future<Map<String, dynamic>> getMovieVideos(int movieId) async {
    try {
      print('🎬 Fetching movie videos for ID: $movieId');
      final response = await ApiClient.tmdb().get('/movie/$movieId/videos');
      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      
      print('📊 Found ${results.length} total videos for movie $movieId');
      
      // First try: YouTube trailers and teasers
      var videos = results.where((video) {
        final type = video['type']?.toString().toLowerCase() ?? '';
        final site = video['site']?.toString().toLowerCase() ?? '';
        return (type == 'trailer' || type == 'teaser') && site == 'youtube';
      }).toList();
      
      print('🎯 Found ${videos.length} YouTube trailers/teasers');
      
      // If no YouTube trailers, try any YouTube videos
      if (videos.isEmpty) {
        videos = results.where((video) {
          final site = video['site']?.toString().toLowerCase() ?? '';
          return site == 'youtube';
        }).toList();
        print('🔄 Fallback: Found ${videos.length} YouTube videos');
      }
      
      // If still no videos, try any trailers/teasers from any site
      if (videos.isEmpty) {
        videos = results.where((video) {
          final type = video['type']?.toString().toLowerCase() ?? '';
          return type == 'trailer' || type == 'teaser';
        }).toList();
        print('🔄 Fallback 2: Found ${videos.length} trailers/teasers from any site');
      }
      
      // If still no videos, try any clips
      if (videos.isEmpty) {
        videos = results.where((video) {
          final type = video['type']?.toString().toLowerCase() ?? '';
          return type == 'clip';
        }).toList();
        print('🔄 Fallback 3: Found ${videos.length} clips');
      }
      
      // Sort by priority: trailer > teaser > clip, then by size (prefer higher quality)
      videos.sort((a, b) {
        final aType = a['type']?.toString().toLowerCase() ?? '';
        final bType = b['type']?.toString().toLowerCase() ?? '';
        final aSize = a['size'] ?? 0;
        final bSize = b['size'] ?? 0;
        
        // Type priority: trailer > teaser > clip
        final typePriority = {'trailer': 3, 'teaser': 2, 'clip': 1};
        final aTypePriority = typePriority[aType] ?? 0;
        final bTypePriority = typePriority[bType] ?? 0;
        
        if (aTypePriority != bTypePriority) {
          return bTypePriority.compareTo(aTypePriority);
        }
        
        // Then sort by size (descending)
        return bSize.compareTo(aSize);
      });
      
      if (videos.isNotEmpty) {
        final bestVideo = videos.first;
        print('✅ Best video: ${bestVideo['name']} (${bestVideo['type']}) - ${bestVideo['site']} - Size: ${bestVideo['size']}');
      }
      
      // Return the processed data with best video info
      final processedData = Map<String, dynamic>.from(data);
      processedData['best_video'] = videos.isNotEmpty ? videos.first : null;
      processedData['all_videos'] = videos.cast<Map<String, dynamic>>();
      processedData['video_count'] = videos.length;
      
      return processedData;
    } on DioException catch (e) {
      print('❌ Error fetching movie videos: $e');
      throw _handleError(e);
    } catch (e) {
      print('❌ Unexpected error fetching movie videos: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // Translate movie content to Vietnamese
  static Future<Map<String, dynamic>> translateMovieContent(Map<String, dynamic> movieData) async {
    try {
      final translationService = TranslationService();
      final translatedData = Map<String, dynamic>.from(movieData);
      
      // Translate title if it's not empty
      if (movieData['title'] != null && movieData['title'].toString().isNotEmpty) {
        final translatedTitle = await translationService.translateToVietnamese(movieData['title']);
        if (translatedTitle != movieData['title']) {
          translatedData['title_vi'] = translatedTitle;
          translatedData['title_language'] = 'vi';
          print('✅ Translated title: ${movieData['title']} → $translatedTitle');
        }
      }
      
      // Translate overview if it's not empty
      if (movieData['overview'] != null && movieData['overview'].toString().isNotEmpty) {
        final translatedOverview = await translationService.translateToVietnamese(movieData['overview']);
        if (translatedOverview != movieData['overview']) {
          translatedData['overview_vi'] = translatedOverview;
          translatedData['overview_language'] = 'vi';
          print('✅ Translated overview (${translatedOverview.length} chars)');
        }
      }
      
      // Translate tagline if it's not empty
      if (movieData['tagline'] != null && movieData['tagline'].toString().isNotEmpty) {
        final translatedTagline = await translationService.translateToVietnamese(movieData['tagline']);
        if (translatedTagline != movieData['tagline']) {
          translatedData['tagline_vi'] = translatedTagline;
          translatedData['tagline_language'] = 'vi';
          print('✅ Translated tagline: ${movieData['tagline']} → $translatedTagline');
        }
      }
      
      return translatedData;
    } catch (e) {
      print('❌ Translation error: $e');
      return movieData; // Return original data if translation fails
    }
  }

  // Error handling
  static String _handleError(DioException e) {
    if (e.response?.data != null && e.response?.data['status_message'] != null) {
      return e.response!.data['status_message'];
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Kết nối bị timeout. Vui lòng thử lại.';
      case DioExceptionType.connectionError:
        return 'Không thể kết nối đến TMDB. Vui lòng kiểm tra kết nối mạng.';
      case DioExceptionType.badResponse:
        switch (e.response?.statusCode) {
          case 401:
            return 'API key không hợp lệ.';
          case 404:
            return 'Không tìm thấy nội dung.';
          case 429:
            return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
          case 500:
            return 'Lỗi server TMDB. Vui lòng thử lại sau.';
          default:
            return 'Đã xảy ra lỗi khi tải dữ liệu.';
        }
      default:
        return 'Đã xảy ra lỗi không xác định.';
    }
  }
}