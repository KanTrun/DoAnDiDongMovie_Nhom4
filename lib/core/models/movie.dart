class Movie {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final DateTime releaseDate;
  final double voteAverage;
  final int voteCount;
  final double popularity;
  final String originalLanguage;
  final List<int> genreIds;
  final bool adult;
  final bool video;
  final String? originalTitle;
  final String? title_vi;
  final String? overview_vi;
  final String? tagline_vi;
  final String? mediaType; // 'movie' or 'tv'

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
    required this.voteCount,
    required this.popularity,
    required this.originalLanguage,
    required this.genreIds,
    required this.adult,
    required this.video,
    this.originalTitle,
    this.title_vi,
    this.overview_vi,
    this.tagline_vi,
    this.mediaType = 'movie',
  });

  factory Movie.fromJson(Map<String, dynamic> json, {String mediaType = 'movie'}) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      releaseDate: _parseReleaseDate(json['release_date']),
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      popularity: (json['popularity'] ?? 0).toDouble(),
      originalLanguage: json['original_language'] ?? '',
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      adult: json['adult'] ?? false,
      video: json['video'] ?? false,
      originalTitle: json['original_title'],
      title_vi: json['title_vi'],
      overview_vi: json['overview_vi'],
      tagline_vi: json['tagline_vi'],
      mediaType: mediaType,
    );
  }

  static DateTime _parseReleaseDate(dynamic releaseDate) {
    if (releaseDate == null || releaseDate.toString().isEmpty) {
      return DateTime.now();
    }
    
    try {
      final dateStr = releaseDate.toString();
      if (dateStr.length >= 4) {
        // Handle various date formats
        if (dateStr.contains('-')) {
          return DateTime.parse(dateStr);
        } else if (dateStr.length == 4) {
          // Only year provided
          return DateTime(int.parse(dateStr));
        }
      }
      return DateTime.now();
    } catch (e) {
      // Fallback to current date if parsing fails
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'release_date': releaseDate.toIso8601String().split('T')[0],
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'popularity': popularity,
      'original_language': originalLanguage,
      'genre_ids': genreIds,
      'adult': adult,
      'video': video,
      'original_title': originalTitle,
    };
  }

  String get fullPosterUrl => 'https://image.tmdb.org/t/p/w500$posterPath';
  String get fullBackdropUrl => 'https://image.tmdb.org/t/p/w1280$backdropPath';
}

class MovieResponse {
  final int page;
  final List<Movie> results;
  final int totalResults;
  final int totalPages;

  MovieResponse({
    required this.page,
    required this.results,
    required this.totalResults,
    required this.totalPages,
  });

  factory MovieResponse.fromJson(Map<String, dynamic> json, {String mediaType = 'movie'}) {
    return MovieResponse(
      page: json['page'] ?? 1,
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => Movie.fromJson(e as Map<String, dynamic>, mediaType: mediaType))
              .toList() ?? [],
      totalResults: json['total_results'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
    );
  }
}

class Genre {
  final int id;
  final String name;

  Genre({
    required this.id,
    required this.name,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Cast {
  final int id;
  final String name;
  final String character;
  final String profilePath;
  final int order;

  const Cast({
    required this.id,
    required this.name,
    required this.character,
    required this.profilePath,
    required this.order,
  });

  factory Cast.fromJson(Map<String, dynamic> json) {
    return Cast(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      character: json['character'] ?? '',
      profilePath: json['profile_path'] ?? '',
      order: json['order'] ?? 0,
    );
  }
}

class Crew {
  final int id;
  final String name;
  final String job;
  final String department;
  final String profilePath;

  const Crew({
    required this.id,
    required this.name,
    required this.job,
    required this.department,
    required this.profilePath,
  });

  factory Crew.fromJson(Map<String, dynamic> json) {
    return Crew(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      job: json['job'] ?? '',
      department: json['department'] ?? '',
      profilePath: json['profile_path'] ?? '',
    );
  }
}

class MovieDetail extends Movie {
  final int budget;
  final List<Genre> genres;
  final String homepage;
  final String imdbId;
  final int revenue;
  final int runtime;
  final String status;
  final String tagline;
  final List<ProductionCompany> productionCompanies;
  final List<ProductionCountry> productionCountries;
  final List<SpokenLanguage> spokenLanguages;
  final List<Cast> cast;
  final List<Crew> crew;

  MovieDetail({
    required super.id,
    required super.title,
    required super.overview,
    required super.posterPath,
    required super.backdropPath,
    required super.releaseDate,
    required super.voteAverage,
    required super.voteCount,
    required super.popularity,
    required super.originalLanguage,
    required super.genreIds,
    required super.adult,
    required super.video,
    super.originalTitle,
    super.title_vi,
    super.overview_vi,
    super.tagline_vi,
    required this.budget,
    required this.genres,
    required this.homepage,
    required this.imdbId,
    required this.revenue,
    required this.runtime,
    required this.status,
    required this.tagline,
    required this.productionCompanies,
    required this.productionCountries,
    required this.spokenLanguages,
    required this.cast,
    required this.crew,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) {
    return MovieDetail(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      releaseDate: json['release_date'] != null 
          ? DateTime.parse(json['release_date'])
          : DateTime.now(),
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      popularity: (json['popularity'] ?? 0).toDouble(),
      originalLanguage: json['original_language'] ?? '',
      genreIds: (json['genres'] as List<dynamic>?)
          ?.map((e) => e['id'] as int)
          .toList() ?? [],
      adult: json['adult'] ?? false,
      video: json['video'] ?? false,
      originalTitle: json['original_title'],
      title_vi: json['title_vi'],
      overview_vi: json['overview_vi'],
      tagline_vi: json['tagline_vi'],
      budget: json['budget'] ?? 0,
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      homepage: json['homepage'] ?? '',
      imdbId: json['imdb_id'] ?? '',
      revenue: json['revenue'] ?? 0,
      runtime: json['runtime'] ?? 0,
      status: json['status'] ?? '',
      tagline: json['tagline'] ?? '',
      productionCompanies: (json['production_companies'] as List<dynamic>?)
          ?.map((e) => ProductionCompany.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      productionCountries: (json['production_countries'] as List<dynamic>?)
          ?.map((e) => ProductionCountry.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      spokenLanguages: (json['spoken_languages'] as List<dynamic>?)
          ?.map((e) => SpokenLanguage.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      cast: (json['cast'] as List<dynamic>?)
          ?.map((e) => Cast.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      crew: (json['crew'] as List<dynamic>?)
          ?.map((e) => Crew.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class ProductionCompany {
  final int id;
  final String logoPath;
  final String name;
  final String originCountry;

  ProductionCompany({
    required this.id,
    required this.logoPath,
    required this.name,
    required this.originCountry,
  });

  factory ProductionCompany.fromJson(Map<String, dynamic> json) {
    return ProductionCompany(
      id: json['id'] ?? 0,
      logoPath: json['logo_path'] ?? '',
      name: json['name'] ?? '',
      originCountry: json['origin_country'] ?? '',
    );
  }
}

class ProductionCountry {
  final String iso;
  final String name;

  ProductionCountry({
    required this.iso,
    required this.name,
  });

  factory ProductionCountry.fromJson(Map<String, dynamic> json) {
    return ProductionCountry(
      iso: json['iso_3166_1'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class SpokenLanguage {
  final String englishName;
  final String iso;
  final String name;

  SpokenLanguage({
    required this.englishName,
    required this.iso,
    required this.name,
  });

  factory SpokenLanguage.fromJson(Map<String, dynamic> json) {
    return SpokenLanguage(
      englishName: json['english_name'] ?? '',
      iso: json['iso_639_1'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

// =========================
//     TV SHOW MODELS
// =========================

class TvShowDetail {
  final int id;
  final String name;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final int voteCount;
  final String firstAirDate;
  final String lastAirDate;
  final int numberOfSeasons;
  final int numberOfEpisodes;
  final String status;
  final String tagline;
  final List<String> genres;
  final List<String> networks;
  final List<String> productionCountries;
  final String originalLanguage;
  final String originalName;
  final double popularity;
  final List<String> createdBy;
  final List<String> languages;

  TvShowDetail({
    required this.id,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    required this.firstAirDate,
    required this.lastAirDate,
    required this.numberOfSeasons,
    required this.numberOfEpisodes,
    required this.status,
    required this.tagline,
    required this.genres,
    required this.networks,
    required this.productionCountries,
    required this.originalLanguage,
    required this.originalName,
    required this.popularity,
    required this.createdBy,
    required this.languages,
  });

  factory TvShowDetail.fromJson(Map<String, dynamic> json) {
    return TvShowDetail(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['original_name'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      firstAirDate: json['first_air_date'] ?? '',
      lastAirDate: json['last_air_date'] ?? '',
      numberOfSeasons: json['number_of_seasons'] ?? 0,
      numberOfEpisodes: json['number_of_episodes'] ?? 0,
      status: json['status'] ?? '',
      tagline: json['tagline'] ?? '',
      genres: (json['genres'] as List<dynamic>?)
          ?.map((genre) => genre['name'] as String)
          .toList() ?? [],
      networks: (json['networks'] as List<dynamic>?)
          ?.map((network) => network['name'] as String)
          .toList() ?? [],
      productionCountries: (json['production_countries'] as List<dynamic>?)
          ?.map((country) => country['name'] as String)
          .toList() ?? [],
      originalLanguage: json['original_language'] ?? '',
      originalName: json['original_name'] ?? '',
      popularity: (json['popularity'] ?? 0.0).toDouble(),
      createdBy: (json['created_by'] as List<dynamic>?)
          ?.map((creator) => creator['name'] as String)
          .toList() ?? [],
      languages: (json['languages'] as List<dynamic>?)
          ?.map((lang) => lang as String)
          .toList() ?? [],
    );
  }
}

class TvShow {
  final int id;
  final String name;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final int voteCount;
  final String firstAirDate;
  final String originalLanguage;
  final String originalName;
  final double popularity;
  final List<int> genreIds;
  final bool adult;

  TvShow({
    required this.id,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    required this.firstAirDate,
    required this.originalLanguage,
    required this.originalName,
    required this.popularity,
    required this.genreIds,
    required this.adult,
  });

  factory TvShow.fromJson(Map<String, dynamic> json) {
    return TvShow(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['original_name'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      firstAirDate: json['first_air_date'] ?? '',
      originalLanguage: json['original_language'] ?? '',
      originalName: json['original_name'] ?? '',
      popularity: (json['popularity'] ?? 0.0).toDouble(),
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      adult: json['adult'] ?? false,
    );
  }
}

class Video {
  final String id;
  final String key;
  final String name;
  final String site;
  final int size;
  final String type;
  final bool official;
  final String publishedAt;
  final String thumbnailUrl;

  Video({
    required this.id,
    required this.key,
    required this.name,
    required this.site,
    required this.size,
    required this.type,
    required this.official,
    required this.publishedAt,
    required this.thumbnailUrl,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? '',
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      site: json['site'] ?? '',
      size: json['size'] ?? 0,
      type: json['type'] ?? '',
      official: json['official'] ?? false,
      publishedAt: json['published_at'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
    );
  }
}

class Credits {
  final List<Cast> cast;
  final List<Crew> crew;

  Credits({
    required this.cast,
    required this.crew,
  });

  factory Credits.fromJson(Map<String, dynamic> json) {
    return Credits(
      cast: (json['cast'] as List<dynamic>?)
          ?.map((cast) => Cast.fromJson(cast))
          .toList() ?? [],
      crew: (json['crew'] as List<dynamic>?)
          ?.map((crew) => Crew.fromJson(crew))
          .toList() ?? [],
    );
  }
}