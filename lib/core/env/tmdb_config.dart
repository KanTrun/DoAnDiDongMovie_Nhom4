class TmdbConfig {
  static const String apiKey = String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: '2daf813d8e3ba7435e678ee33d90d6e9',
  );
  
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://192.168.1.80:5127/api',
  );
  
  static const String tmdbLanguage = String.fromEnvironment(
    'TMDB_LANGUAGE',
    defaultValue: 'vi-VN',
  );
  
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/';
  
  // Image sizes
  static const String posterSizeW185 = 'w185';
  static const String posterSizeW342 = 'w342';
  static const String posterSizeW500 = 'w500';
  static const String posterSizeW780 = 'w780';
  static const String posterSizeOriginal = 'original';
  
  static const String backdropSizeW300 = 'w300';
  static const String backdropSizeW780 = 'w780';
  static const String backdropSizeW1280 = 'w1280';
  static const String backdropSizeOriginal = 'original';
  
  static const String profileSizeW45 = 'w45';
  static const String profileSizeW185 = 'w185';
  static const String profileSizeH632 = 'h632';
  static const String profileSizeOriginal = 'original';
  
  static String getPosterUrl(String? posterPath, {String size = posterSizeW500}) {
    if (posterPath == null || posterPath.isEmpty) return '';
    return '$imageBaseUrl$size$posterPath';
  }
  
  static String getBackdropUrl(String? backdropPath, {String size = backdropSizeW1280}) {
    if (backdropPath == null || backdropPath.isEmpty) return '';
    return '$imageBaseUrl$size$backdropPath';
  }
  
  static String getProfileUrl(String? profilePath, {String size = profileSizeW185}) {
    if (profilePath == null || profilePath.isEmpty) return '';
    return '$imageBaseUrl$size$profilePath';
  }
}