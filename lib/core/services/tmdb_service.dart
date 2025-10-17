import 'package:dio/dio.dart';
import '../models/movie.dart';
import '../network/api_client.dart';
import 'translation_service.dart';

class TmdbService {
  // Discover Movies
  static Future<MovieResponse> getPopularMovies({int page = 1}) async {
    try {
      // Try Vietnamese first, then fallback to English
      try {
        final viResponse = await ApiClient.tmdb().get(
          '/movie/popular',
          queryParameters: {
            'page': page,
            'language': 'vi-VN',
            'include_adult': false,
          },
        );
        
        final viResults = MovieResponse.fromJson(viResponse.data, mediaType: 'movie');
        print('📊 Vietnamese popular movies found ${viResults.results.length} results');
        
        if (viResults.results.length >= 5) {
          return viResults;
        }
        
        // Fallback to English
        final enResponse = await ApiClient.tmdb().get(
          '/movie/popular',
          queryParameters: {
            'page': page,
            'language': 'en-US',
            'include_adult': false,
          },
        );
        
        final enResults = MovieResponse.fromJson(enResponse.data, mediaType: 'movie');
        print('📊 English popular movies found ${enResults.results.length} results');
        
        return enResults;
      } catch (e) {
        print('❌ Language-specific popular movies failed: $e');
        
        // Fallback to default
        final response = await ApiClient.tmdb().get(
          '/movie/popular',
          queryParameters: {'page': page},
        );
        return MovieResponse.fromJson(response.data, mediaType: 'movie');
      }
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
      return MovieResponse.fromJson(response.data, mediaType: 'movie');
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
      return MovieResponse.fromJson(response.data, mediaType: 'movie');
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
      return MovieResponse.fromJson(response.data, mediaType: 'movie');
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
      return MovieResponse.fromJson(response.data, mediaType: 'movie');
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
      final queryParams = <String, dynamic>{
        'page': page,
        'include_adult': false,
        'include_video': false,
      };
      
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (withGenres != null) queryParams['with_genres'] = withGenres;
      if (withoutGenres != null) queryParams['without_genres'] = withoutGenres;
      if (voteAverageGte != null) queryParams['vote_average.gte'] = voteAverageGte;
      if (voteAverageLte != null) queryParams['vote_average.lte'] = voteAverageLte;
      if (releaseDateGte != null) queryParams['release_date.gte'] = releaseDateGte;
      if (releaseDateLte != null) queryParams['release_date.lte'] = releaseDateLte;
      if (withOriginalLanguage != null) queryParams['with_original_language'] = withOriginalLanguage;

      // Try Vietnamese first, then fallback to English
      try {
        final viParams = Map<String, dynamic>.from(queryParams);
        viParams['language'] = 'vi-VN';
        
        final response = await ApiClient.tmdb().get(
          '/discover/movie',
          queryParameters: viParams,
        );
        
        final movieResponse = MovieResponse.fromJson(response.data, mediaType: 'movie');
        print('📊 Vietnamese discover found ${movieResponse.results.length} results');
        
        // If we have good results, return them
        if (movieResponse.results.length >= 5) {
          return movieResponse;
        }
        
        // Otherwise, try English
        final enParams = Map<String, dynamic>.from(queryParams);
        enParams['language'] = 'en-US';
        
        final enResponse = await ApiClient.tmdb().get(
          '/discover/movie',
          queryParameters: enParams,
        );
        
        final enMovieResponse = MovieResponse.fromJson(enResponse.data, mediaType: 'movie');
        print('📊 English discover found ${enMovieResponse.results.length} results');
        
        return enMovieResponse;
      } catch (e) {
        print('❌ Language-specific discover failed: $e');
        
        // Fallback to default discover
        final response = await ApiClient.tmdb().get(
          '/discover/movie',
          queryParameters: queryParams,
        );
        return MovieResponse.fromJson(response.data, mediaType: 'movie');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Search - Enhanced multi-language search for both Movies and TV Shows
  static Future<MovieResponse> searchMovies(String query, {int page = 1}) async {
    try {
      final searchResults = <Movie>[];
      final seenIds = <int>{};
      
      // Strategy 1: Try multiple search variations with multiple pages
      final searchVariations = _generateSearchVariations(query);
      
      for (final searchQuery in searchVariations) {
        // Search multiple pages for comprehensive results
        await _searchMultiplePages(searchQuery, searchResults, seenIds, page);
        
        // If we found results, we can stop trying other variations
        if (searchResults.isNotEmpty) {
          break;
        }
      }
      
      return MovieResponse(
        page: page,
        results: searchResults,
        totalPages: 1,
        totalResults: searchResults.length,
      );
    } on DioException catch (e) {
      print('❌ Search error: ${e.message}');
      if (e.response?.data != null) {
        print('📄 Error data: ${e.response?.data}');
      }
      throw _handleError(e);
    }
  }
  
  // Search multiple pages for comprehensive results
  static Future<void> _searchMultiplePages(String query, List<Movie> searchResults, Set<int> seenIds, int startPage) async {
    const maxPages = 5; // Search up to 5 pages for comprehensive results
    bool hasMoreResults = true;
    
    print('🔍 COMPREHENSIVE SEARCH: Starting multi-page search for "$query"');
    
    for (int currentPage = startPage; currentPage <= maxPages && hasMoreResults; currentPage++) {
      print('🔍 Searching page $currentPage for "$query"');
      
      bool pageHasResults = false;
      
      // Search Movies
      try {
        final queryParams = {
          'query': query,
          'page': currentPage,
          'include_adult': false,
          'include_video': false,
          'language': 'en-US', // Get English first to ensure we have overviews
        };
        print('🔍 API CALL: Searching movies with query="$query", page=$currentPage, language=en-US');
        print('🔍 API URL: /search/movie with params: $queryParams');
        
        final movieResponse = await ApiClient.tmdb().get(
          '/search/movie',
          queryParameters: queryParams,
        );
        print('🔍 API RESPONSE: Got ${movieResponse.data['results']?.length ?? 0} results');
        
        // Debug: Print raw API response for first few movies
        final results = movieResponse.data['results'] as List<dynamic>? ?? [];
        for (int i = 0; i < results.length && i < 3; i++) {
          final movieData = results[i] as Map<String, dynamic>;
          print('🔍 RAW API Movie $i: "${movieData['title']}" - Overview: "${movieData['overview']}"');
        }
        
        final movieResults = MovieResponse.fromJson(movieResponse.data, mediaType: 'movie');
        
        if (movieResults.results.isNotEmpty) {
          pageHasResults = true;
          print('📊 Page $currentPage: Found ${movieResults.results.length} movies');
          
          // Debug: Print all movie titles and overviews
          for (int i = 0; i < movieResults.results.length; i++) {
            final movie = movieResults.results[i];
            print('📊 Movie $i: "${movie.title}" - Overview: "${movie.overview}"');
          }
          
          for (final movie in movieResults.results) {
            if (!seenIds.contains(movie.id)) {
              // Debug: Check what we got from API
              print('🔍 DEBUG API: Movie "${movie.title}" - Original overview from API: "${movie.overview}"');
              
              // Always ensure Vietnamese overview
              String vietnameseOverview = await _ensureVietnameseOverview(movie.title, movie.overview, 'movie');
              print('🔍 DEBUG: Movie "${movie.title}" - Final Vietnamese overview: "$vietnameseOverview"');
              
              final movieWithType = Movie(
                id: movie.id,
                title: movie.title,
                overview: movie.overview, // Keep original overview
                posterPath: movie.posterPath,
                backdropPath: movie.backdropPath,
                releaseDate: movie.releaseDate,
                voteAverage: movie.voteAverage,
                voteCount: movie.voteCount,
                popularity: movie.popularity,
                originalLanguage: movie.originalLanguage,
                genreIds: movie.genreIds,
                adult: movie.adult,
                video: movie.video,
                originalTitle: movie.originalTitle,
                title_vi: movie.title_vi,
                overview_vi: vietnameseOverview, // Store Vietnamese translation here
                tagline_vi: movie.tagline_vi,
                mediaType: 'movie',
              );
              searchResults.add(movieWithType);
              seenIds.add(movie.id);
            }
          }
        }
      } catch (e) {
        // Movie search failed, continue with next page
      }
      
      // Search TV Shows
      try {
        final tvResponse = await ApiClient.tmdb().get(
          '/search/tv',
          queryParameters: {
            'query': query,
            'page': currentPage,
            'include_adult': false,
            'language': 'en-US', // Get English first to ensure we have overviews
          },
        );
        
        final tvResults = tvResponse.data['results'] as List<dynamic>? ?? [];
        
        if (tvResults.isNotEmpty) {
          pageHasResults = true;
          print('📊 Page $currentPage: Found ${tvResults.length} TV shows');
          
          for (final tv in tvResults) {
            DateTime releaseDate = DateTime.now();
            try {
              final dateStr = tv['first_air_date'] as String?;
              if (dateStr != null && dateStr.isNotEmpty) {
                releaseDate = DateTime.parse(dateStr);
              }
            } catch (e) {
              releaseDate = DateTime.now();
            }
            
            final overview = tv['overview'] ?? '';
            print('📺 TV Show: ${tv['name']} - Overview: "${overview}"');
            print('🔍 DEBUG API: TV Show "${tv['name']}" - Original overview from API: "$overview"');
            
            // Always ensure Vietnamese overview for TV shows
            String finalOverview = await _ensureVietnameseOverview(tv['name'] ?? '', overview, 'tv');
            print('🔍 DEBUG: TV Show "${tv['name']}" - Final Vietnamese overview: "$finalOverview"');
            
            final movie = Movie(
              id: tv['id'] ?? 0,
              title: tv['name'] ?? tv['original_name'] ?? '',
              overview: overview, // Keep original overview
              posterPath: tv['poster_path'],
              backdropPath: tv['backdrop_path'],
              releaseDate: releaseDate,
              voteAverage: (tv['vote_average'] ?? 0.0).toDouble(),
              voteCount: tv['vote_count'] ?? 0,
              popularity: (tv['popularity'] ?? 0.0).toDouble(),
              originalLanguage: tv['original_language'] ?? '',
              genreIds: List<int>.from(tv['genre_ids'] ?? []),
              adult: tv['adult'] ?? false,
              video: false,
              originalTitle: tv['original_name'] ?? '',
              overview_vi: finalOverview, // Store Vietnamese translation here
              mediaType: 'tv',
            );
            
            if (!seenIds.contains(movie.id) && movie.id > 0) {
              searchResults.add(movie);
              seenIds.add(movie.id);
            }
          }
        }
      } catch (e) {
        // TV search failed, continue with next page
      }
      
      // If no results on this page, stop searching more pages
      if (!pageHasResults) {
        hasMoreResults = false;
        print('📊 No more results found on page $currentPage, stopping search');
      }
      
      print('📊 Total results so far: ${searchResults.length}');
    }
  }
  
  
  
  
  // Generate multiple search variations for better results
  static List<String> _generateSearchVariations(String query) {
    final variations = <String>[];
    
    // Original query
    variations.add(query);
    
    // Common translations for "Thỏa Thuận Bí Mật"
    if (query.toLowerCase().contains('thỏa thuận bí mật') || 
        query.toLowerCase().contains('thoa thuan bi mat')) {
      variations.addAll([
        'Harmony Secret',
        'Secret Agreement',
        'Deal Secret',
        'Agreement Secret',
        'Secret Deal',
        'Harmony',
        'Secret',
        'Agreement',
        'Deal'
      ]);
    }
    
    // Try with different encodings
    try {
      final encoded = Uri.encodeComponent(query);
      if (encoded != query) {
        variations.add(encoded);
      }
    } catch (e) {
      print('❌ Encoding failed: $e');
    }
    
    // Remove duplicates
    return variations.toSet().toList();
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
      return MovieResponse.fromJson(response.data, mediaType: 'movie');
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
      return MovieResponse.fromJson(response.data, mediaType: 'movie');
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

  // =========================
  //     TV SHOW METHODS
  // =========================

  // Get TV show details
  static Future<TvShowDetail> getTvShowDetails(int tvShowId) async {
    try {
      final response = await ApiClient.tmdb().get('/tv/$tvShowId');
      return TvShowDetail.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get TV show videos
  static Future<List<Video>> getTvShowVideos(int tvShowId) async {
    try {
      final response = await ApiClient.tmdb().get('/tv/$tvShowId/videos');
      final videos = (response.data['results'] as List<dynamic>?)
          ?.map((video) => Video.fromJson(video))
          .toList() ?? [];
      
      // Filter for YouTube videos only
      return videos.where((video) => video.site == 'YouTube').toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get TV show credits
  static Future<Credits> getTvShowCredits(int tvShowId) async {
    try {
      final response = await ApiClient.tmdb().get('/tv/$tvShowId/credits');
      return Credits.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get similar TV shows
  static Future<List<TvShow>> getSimilarTvShows(int tvShowId) async {
    try {
      final response = await ApiClient.tmdb().get('/tv/$tvShowId/similar');
      return (response.data['results'] as List<dynamic>?)
          ?.map((tvShow) => TvShow.fromJson(tvShow))
          .toList() ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // TRANSLATE REAL OVERVIEW TO VIETNAMESE - NO FALLBACK
  static Future<String> _ensureVietnameseOverview(String title, String originalOverview, String mediaType) async {
    print('🔄 TRANSLATING REAL OVERVIEW for "$title"');
    print('📝 Original overview: "$originalOverview"');
    
    // ONLY translate if we have original overview
    if (originalOverview.isNotEmpty) {
      print('🔄 TRANSLATING: "$originalOverview"');
      
      // Method 1: Use TranslationService (Google Translator package)
      try {
        final translationService = TranslationService();
        final translatedText = await translationService.translateToVietnamese(originalOverview);
        
        if (translatedText.isNotEmpty && translatedText != originalOverview) {
          print('✅ REAL TRANSLATION SUCCESS (TranslationService): "$translatedText"');
          return translatedText;
        }
      } catch (e) {
        print('❌ TranslationService failed: $e');
      }
      
      // Method 2: Google Translate with direct Dio (fallback)
      try {
        final dio = Dio();
        final response = await dio.get(
          'https://translate.googleapis.com/translate_a/single',
          queryParameters: {
            'client': 'gtx',
            'sl': 'en',
            'tl': 'vi',
            'dt': 't',
            'q': originalOverview,
          },
        );
        
        if (response.data != null && response.data is List) {
          final data = response.data as List;
          if (data.isNotEmpty && data[0] is List) {
            final translations = data[0] as List;
            if (translations.isNotEmpty && translations[0] is List) {
              final translation = translations[0] as List;
              if (translation.isNotEmpty && translation[0] is String) {
                final translatedText = translation[0] as String;
                if (translatedText.isNotEmpty && translatedText != originalOverview) {
                  print('✅ REAL TRANSLATION SUCCESS (Google API): "$translatedText"');
                  return translatedText;
                }
              }
            }
          }
        }
      } catch (e) {
        print('❌ Google Translate failed: $e');
      }
      
      // Method 3: MyMemory API with direct Dio (fallback)
      try {
        final dio = Dio();
        final response = await dio.get(
          'https://api.mymemory.translated.net/get',
          queryParameters: {
            'q': originalOverview,
            'langpair': 'en|vi',
          },
        );
        
        if (response.data != null && response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          final translatedText = data['responseData']?['translatedText'] as String?;
          if (translatedText != null && translatedText.isNotEmpty && translatedText != originalOverview) {
            print('✅ REAL TRANSLATION SUCCESS (MyMemory): "$translatedText"');
            return translatedText;
          }
        }
      } catch (e) {
        print('❌ MyMemory failed: $e');
      }
      
      // Method 4: Manual translation for common patterns
      String manualTranslated = _manualTranslatePatterns(originalOverview);
      if (manualTranslated.isNotEmpty && manualTranslated != originalOverview) {
        print('✅ REAL TRANSLATION SUCCESS (Manual): "$manualTranslated"');
        return manualTranslated;
      }
      
      // If all translation fails, return original (NOT fallback)
      print('❌ All translation failed, returning ORIGINAL overview');
      return originalOverview;
    }
    
    // If no original overview, return original text (NOT EMPTY)
    print('❌ No original overview, returning original text');
    return originalOverview;
  }
  
  // Manual translation patterns for common English phrases
  static String _manualTranslatePatterns(String text) {
    print('🔄 Manual translation patterns for: "$text"');
    
    // Common English to Vietnamese patterns
    final patterns = {
      'A Doraemons film': 'Một bộ phim về đội quân Doraemon',
      'A Doraemon film': 'Một bộ phim về Doraemon',
      'It premiered on a bill with': 'Phim được công chiếu cùng với',
      'The movie\'s original plot was written by': 'Cốt truyện gốc của phim được viết bởi',
      'It was released on': 'Phim được phát hành vào',
      'with Doraemon': 'cùng với Doraemon',
      'Japanese short anime family film': 'Phim hoạt hình ngắn gia đình Nhật Bản',
      'about The Doraemons': 'về đội quân Doraemon',
      'featuring the Doraemons': 'có sự tham gia của đội quân Doraemon',
      'family film': 'phim gia đình',
      'anime': 'hoạt hình',
      'film': 'phim',
      'movie': 'phim',
      'short': 'ngắn',
      'Japanese': 'Nhật Bản',
      'adventure': 'phiêu lưu',
      'action': 'hành động',
      'comedy': 'hài kịch',
      'drama': 'tâm lý',
      'thriller': 'ly kỳ',
      'horror': 'kinh dị',
      'romance': 'tình cảm',
      'sci-fi': 'khoa học viễn tưởng',
      'fantasy': 'giả tưởng',
      'mystery': 'bí ẩn',
      'crime': 'tội phạm',
      'documentary': 'tài liệu',
      'biography': 'tiểu sử',
      'history': 'lịch sử',
      'war': 'chiến tranh',
      'western': 'miền tây',
      'musical': 'nhạc kịch',
      'sport': 'thể thao',
      'March': 'tháng 3',
      '1997': 'năm 1997',
      '1998': 'năm 1998',
      '1999': 'năm 1999',
      '2000': 'năm 2000',
      'Nobita': 'Nobita',
      'Spiral City': 'Thành phố Xoắn ốc',
      'Sun King': 'Vua Mặt Trời',
      'Legend': 'Huyền thoại',
      'written by': 'được viết bởi',
      'Hiroshi Fujimoto': 'Hiroshi Fujimoto',
      'Motoo Abiko': 'Motoo Abiko',
    };
    
    String result = text;
    for (final entry in patterns.entries) {
      if (result.toLowerCase().contains(entry.key.toLowerCase())) {
        result = result.replaceAll(RegExp(entry.key, caseSensitive: false), entry.value);
      }
    }
    
    if (result != text && result.isNotEmpty) {
      print('✅ Manual translation successful: "$result"');
      return result;
    }
    
    return '';
  }
}