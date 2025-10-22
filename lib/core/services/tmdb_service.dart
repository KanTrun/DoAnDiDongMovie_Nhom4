import 'package:dio/dio.dart';
import '../models/movie.dart';
import '../network/api_client.dart';
import 'translation_service.dart';
import 'package:translator/translator.dart';

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
        // Vietnamese popular movies found
        
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
        // English popular movies found
        
        return enResults;
      } catch (e) {
        // Language-specific popular movies failed
        
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
        // Vietnamese discover found
        
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
        // English discover found
        
        return enMovieResponse;
      } catch (e) {
        // Language-specific discover failed
        
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

  // Search - Fast parallel search like TMDB
  static Future<MovieResponse> searchMovies(String query, {int page = 1}) async {
    try {
      final searchResults = <Movie>[];
      final seenIds = <int>{};
      
      // Fast parallel search - search all pages and languages simultaneously
      final futures = <Future<void>>[];
      
      // Search all 5 pages in parallel
      for (int currentPage = 1; currentPage <= 5; currentPage++) {
        futures.add(_searchPageParallel(query, searchResults, seenIds, currentPage));
      }
      
      // Wait for all searches to complete
      await Future.wait(futures);
      
      return MovieResponse(
        page: page,
        results: searchResults,
        totalPages: 1,
        totalResults: searchResults.length,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Search a single page with both languages in parallel
  static Future<void> _searchPageParallel(String query, List<Movie> searchResults, Set<int> seenIds, int page) async {
    try {
      // Search both Vietnamese and English simultaneously
      final futures = <Future<void>>[];
      
      // Vietnamese search
      futures.add(_searchLanguageFast(query, searchResults, seenIds, page, 'vi-VN'));
      
      // English search
      futures.add(_searchLanguageFast(query, searchResults, seenIds, page, 'en-US'));
      
      // Wait for both to complete
      await Future.wait(futures);
      
    } catch (e) {
      // Page search failed, continue
    }
  }
  
  // Fast language search
  static Future<void> _searchLanguageFast(String query, List<Movie> searchResults, Set<int> seenIds, int page, String language) async {
    try {
      final response = await ApiClient.tmdb().get('/search/multi', queryParameters: {
        'query': query,
        'page': page,
        'language': language,
        'include_adult': false,
      });
      
      final data = response.data;
      if (data['results'] != null) {
        for (final item in data['results']) {
          if (item['id'] != null && !seenIds.contains(item['id'])) {
            seenIds.add(item['id']);
            final movie = Movie.fromJson(item, mediaType: item['media_type'] ?? 'movie');
            searchResults.add(movie);
          }
        }
      }
    } catch (e) {
      // Language search failed, continue
    }
  }
  
  // Search multiple pages for comprehensive results
  static Future<void> _searchMultiplePages(String query, List<Movie> searchResults, Set<int> seenIds, int startPage) async {
    const maxPages = 5; // Search up to 5 pages for comprehensive results
    bool hasMoreResults = true;
    
    // Starting comprehensive search
    
    for (int currentPage = startPage; currentPage <= maxPages && hasMoreResults; currentPage++) {
      // Searching page $currentPage
      
      bool pageHasResults = false;
      
      // Search Movies - Get Vietnamese titles and English overviews
      try {
        // First get Vietnamese titles
        final viQueryParams = {
          'query': query,
          'page': currentPage,
          'include_adult': false,
          'include_video': false,
          'language': 'vi-VN', // Get Vietnamese titles
        };
        // Searching movies with Vietnamese language
        
        final viMovieResponse = await ApiClient.tmdb().get(
          '/search/movie',
          queryParameters: viQueryParams,
        );
        // Vietnamese API response received
        
        // Debug: Print Vietnamese API response for first few movies
        final viResults = viMovieResponse.data['results'] as List<dynamic>? ?? [];
        for (int i = 0; i < viResults.length && i < 3; i++) {
          final movieData = viResults[i] as Map<String, dynamic>;
          // Vietnamese API movie data
        }
        
        // Then get English overviews
        final enQueryParams = {
          'query': query,
          'page': currentPage,
          'include_adult': false,
          'include_video': false,
          'language': 'en-US', // Get English overviews
        };
        // Searching movies with English language
        
        final enMovieResponse = await ApiClient.tmdb().get(
          '/search/movie',
          queryParameters: enQueryParams,
        );
        // English API response received
        
        // Merge Vietnamese titles with English overviews
        final enResults = enMovieResponse.data['results'] as List<dynamic>? ?? [];
        
        // Create a map of English results by ID for quick lookup
        final enResultsMap = <int, Map<String, dynamic>>{};
        for (final enMovie in enResults) {
          final movieData = enMovie as Map<String, dynamic>;
          enResultsMap[movieData['id']] = movieData;
        }
        
        // Combine Vietnamese titles with English overviews
        final combinedResults = <Map<String, dynamic>>[];
        for (final viMovie in viResults) {
          final movieData = Map<String, dynamic>.from(viMovie as Map<String, dynamic>);
          final movieId = movieData['id'];
          
          // Get English overview if available
          if (enResultsMap.containsKey(movieId)) {
            final enMovie = enResultsMap[movieId]!;
            movieData['overview_en'] = enMovie['overview'] ?? '';
            movieData['title_en'] = enMovie['title'] ?? '';
          }
          
          combinedResults.add(movieData);
        }
        
        // Debug: Print combined results
        for (int i = 0; i < combinedResults.length && i < 3; i++) {
          final movieData = combinedResults[i];
          // Combined movie data
        }
        
        // Create fake response data with combined results
        final fakeResponseData = {
          'page': viMovieResponse.data['page'],
          'results': combinedResults,
          'total_pages': viMovieResponse.data['total_pages'],
          'total_results': viMovieResponse.data['total_results'],
        };
        
        final movieResults = MovieResponse.fromJson(fakeResponseData, mediaType: 'movie');
        
        if (movieResults.results.isNotEmpty) {
          pageHasResults = true;
          // Page results found
          
          // Debug: Print all movie titles and overviews
          for (int i = 0; i < movieResults.results.length; i++) {
            final movie = movieResults.results[i];
            // Movie data
          }
          
          for (final movie in movieResults.results) {
            if (!seenIds.contains(movie.id)) {
              // Debug: Check what we got from API
              // Original overview from API
              
              // Get English overview from the combined data
              String englishOverview = '';
              final combinedData = combinedResults.firstWhere(
                (data) => data['id'] == movie.id,
                orElse: () => {},
              );
              if (combinedData.isNotEmpty) {
                englishOverview = combinedData['overview_en'] ?? '';
                // English overview
              }
              
              // Always ensure Vietnamese overview using English overview
              String vietnameseOverview = await _ensureVietnameseOverview(movie.title, englishOverview.isNotEmpty ? englishOverview : movie.overview, 'movie');
              // Final Vietnamese overview
              
              // Check if title needs translation (if it's in English/Japanese/Chinese, translate to Vietnamese)
              String finalTitle = movie.title;
              if (_needsTitleTranslation(movie.title)) {
                try {
                  final titleTranslation = await _translateTitle(movie.title);
                  if (titleTranslation.isNotEmpty && titleTranslation != movie.title) {
                    finalTitle = titleTranslation;
                    // Title translated
                  }
                } catch (e) {
                  // Title translation failed
                }
              }
              
              final movieWithType = Movie(
                id: movie.id,
                title: finalTitle, // Vietnamese title (translated if needed)
                overview: englishOverview.isNotEmpty ? englishOverview : movie.overview, // English overview for translation
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
      
      // Search TV Shows - Get Vietnamese titles and English overviews
      try {
        // First get Vietnamese titles
        final viTvResponse = await ApiClient.tmdb().get(
          '/search/tv',
          queryParameters: {
            'query': query,
            'page': currentPage,
            'include_adult': false,
            'language': 'vi-VN', // Get Vietnamese titles
          },
        );
        
        // Then get English overviews
        final enTvResponse = await ApiClient.tmdb().get(
          '/search/tv',
          queryParameters: {
            'query': query,
            'page': currentPage,
            'include_adult': false,
            'language': 'en-US', // Get English overviews
          },
        );
        
        // Merge Vietnamese titles with English overviews
        final viTvResults = viTvResponse.data['results'] as List<dynamic>? ?? [];
        final enTvResults = enTvResponse.data['results'] as List<dynamic>? ?? [];
        
        // Create a map of English results by ID for quick lookup
        final enTvResultsMap = <int, Map<String, dynamic>>{};
        for (final enTv in enTvResults) {
          final tvData = enTv as Map<String, dynamic>;
          enTvResultsMap[tvData['id']] = tvData;
        }
        
        final tvResults = viTvResults;
        
        if (tvResults.isNotEmpty) {
          pageHasResults = true;
          // TV shows found
          
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
            // Debug log removed for production
            // TV show original overview
            
            // Get English overview from the combined data
            String englishOverview = '';
            final tvId = tv['id'];
            if (enTvResultsMap.containsKey(tvId)) {
              final enTv = enTvResultsMap[tvId]!;
              englishOverview = enTv['overview'] ?? '';
              // TV show English overview
            }
            
            // Always ensure Vietnamese overview for TV shows using English overview
            String finalOverview = await _ensureVietnameseOverview(tv['name'] ?? '', englishOverview.isNotEmpty ? englishOverview : overview, 'tv');
            // TV show final Vietnamese overview
            
            // Check if title needs translation (if it's in English/Japanese/Chinese, translate to Vietnamese)
            String finalTitle = tv['name'] ?? '';
            if (_needsTitleTranslation(finalTitle)) {
              try {
                final titleTranslation = await _translateTitle(finalTitle);
                if (titleTranslation.isNotEmpty && titleTranslation != finalTitle) {
                  finalTitle = titleTranslation;
                  // TV title translated
                }
              } catch (e) {
                // TV title translation failed
              }
            }
            
            final movie = Movie(
              id: tv['id'] ?? 0,
              title: finalTitle, // Vietnamese title (translated if needed)
              overview: englishOverview.isNotEmpty ? englishOverview : overview, // English overview for translation
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
        // No more results found
      }
      
      // Total results so far
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
      // Encoding failed
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
                // Using translated Vietnamese biography
              } else {
                personData['biography'] = englishBio;
                personData['biography_language'] = 'en';
                print('⚠️  Translation failed, using English biography (${englishBio.length} chars)');
              }
            } catch (e) {
              // Translation error, using English biography
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
          // Failed to fetch English biography
          personData['biography_language'] = 'vi';
        }
      } else {
        personData['biography_language'] = 'vi';
        // Using Vietnamese biography
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
      
      // Found total videos
      
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
        // Best video found
      }
      
      // Return the processed data with best video info
      final processedData = Map<String, dynamic>.from(data);
      processedData['best_video'] = videos.isNotEmpty ? videos.first : null;
      processedData['all_videos'] = videos.cast<Map<String, dynamic>>();
      processedData['video_count'] = videos.length;
      
      return processedData;
    } on DioException catch (e) {
      // Error fetching movie videos
      throw _handleError(e);
    } catch (e) {
      // Unexpected error fetching movie videos
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
          // Translated title
        }
      }
      
      // Translate overview if it's not empty
      if (movieData['overview'] != null && movieData['overview'].toString().isNotEmpty) {
        final translatedOverview = await translationService.translateToVietnamese(movieData['overview']);
        if (translatedOverview != movieData['overview']) {
          translatedData['overview_vi'] = translatedOverview;
          translatedData['overview_language'] = 'vi';
          // Translated overview
        }
      }
      
      // Translate tagline if it's not empty
      if (movieData['tagline'] != null && movieData['tagline'].toString().isNotEmpty) {
        final translatedTagline = await translationService.translateToVietnamese(movieData['tagline']);
        if (translatedTagline != movieData['tagline']) {
          translatedData['tagline_vi'] = translatedTagline;
          translatedData['tagline_language'] = 'vi';
          // Translated tagline
        }
      }
      
      return translatedData;
    } catch (e) {
      // Translation error
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

  // Translate real overview to Vietnamese - silent mode
  static Future<String> _ensureVietnameseOverview(String title, String originalOverview, String mediaType) async {
    // Debug log removed
    // Debug log removed
    
    // ONLY translate if we have original overview
    if (originalOverview.isNotEmpty) {
      // Debug log removed
      
      // Method 1: Use TranslationService (Google Translator package)
      try {
        final translationService = TranslationService();
        final translatedText = await translationService.translateToVietnamese(originalOverview);
        
        if (translatedText.isNotEmpty && translatedText != originalOverview) {
          // TranslationService success
          return translatedText;
        }
      } catch (e) {
        // TranslationService failed
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
                  // Google API success
                  return translatedText;
                }
              }
            }
          }
        }
      } catch (e) {
        // Google Translate failed
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
            // MyMemory success
            return translatedText;
          }
        }
      } catch (e) {
        // MyMemory failed
      }
      
      // Method 4: Manual translation for common patterns
      String manualTranslated = _manualTranslatePatterns(originalOverview);
      if (manualTranslated.isNotEmpty && manualTranslated != originalOverview) {
        // Manual translation success
        return manualTranslated;
      }
      
      // If all translation fails, return original (NOT fallback)
      // All translation failed, returning original
      return originalOverview;
    }
    
    // If no original overview, return original text (NOT EMPTY)
    // No original overview, returning original text
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
      // Manual translation successful
      return result;
    }
    
    return '';
  }

  // Check if text contains Vietnamese characters
  static bool _containsVietnameseCharacters(String text) {
    // Vietnamese Unicode ranges
    final vietnamesePattern = RegExp(r'[\u00C0-\u024F\u1E00-\u1EFF\u0100-\u017F\u0180-\u024F]');
    return vietnamesePattern.hasMatch(text);
  }

  // Check if title needs translation (contains English, Japanese, Chinese characters)
  static bool _needsTitleTranslation(String title) {
    // If already contains Vietnamese characters, don't translate
    if (_containsVietnameseCharacters(title)) {
      return false;
    }
    
    // Check for English, Japanese, Chinese characters
    final needsTranslationPattern = RegExp(r'[a-zA-Z\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');
    return needsTranslationPattern.hasMatch(title);
  }

  // Translate title to Vietnamese
  static Future<String> _translateTitle(String title) async {
    try {
      final translator = GoogleTranslator();
      final translation = await translator.translate(title, from: 'auto', to: 'vi');
      
      if (translation.text.isNotEmpty && translation.text != title) {
        // Title translation success
        return translation.text;
      }
      
      return title; // Return original if translation failed
    } catch (e) {
      // Title translation error
      return title;
    }
  }
}