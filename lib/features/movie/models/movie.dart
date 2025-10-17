class Movie {
  final int id;
  final String title;
  final String? originalTitle;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final int voteCount;
  final double popularity;
  final bool adult;
  final String? originalLanguage;
  final List<int>? genreIds;
  final List<Genre>? genres;
  final int? runtime;
  final int? budget;
  final int? revenue;
  final String? status;
  final String? tagline;
  final Credits? credits;
  final Images? images;
  final Videos? videos;
  final MovieResponse? similar;

  const Movie({
    required this.id,
    required this.title,
    this.originalTitle,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.popularity = 0.0,
    this.adult = false,
    this.originalLanguage,
    this.genreIds,
    this.genres,
    this.runtime,
    this.budget,
    this.revenue,
    this.status,
    this.tagline,
    this.credits,
    this.images,
    this.videos,
    this.similar,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      originalTitle: json['original_title'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      releaseDate: json['release_date'],
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      popularity: (json['popularity'] ?? 0.0).toDouble(),
      adult: json['adult'] ?? false,
      originalLanguage: json['original_language'],
      genreIds: (json['genre_ids'] as List<dynamic>?)?.cast<int>(),
      genres: (json['genres'] as List<dynamic>?)?.map((e) => Genre.fromJson(e)).toList(),
      runtime: json['runtime'],
      budget: json['budget'],
      revenue: json['revenue'],
      status: json['status'],
      tagline: json['tagline'],
      credits: json['credits'] != null ? Credits.fromJson(json['credits']) : null,
      images: json['images'] != null ? Images.fromJson(json['images']) : null,
      videos: json['videos'] != null ? Videos.fromJson(json['videos']) : null,
      similar: json['similar'] != null ? MovieResponse.fromJson(json['similar']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'original_title': originalTitle,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'release_date': releaseDate,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'popularity': popularity,
      'adult': adult,
      'original_language': originalLanguage,
      'genre_ids': genreIds,
      'genres': genres?.map((e) => e.toJson()).toList(),
      'runtime': runtime,
      'budget': budget,
      'revenue': revenue,
      'status': status,
      'tagline': tagline,
      'credits': credits?.toJson(),
      'images': images?.toJson(),
      'videos': videos?.toJson(),
      'similar': similar?.toJson(),
    };
  }
}

class TvShow {
  final int id;
  final String name;
  final String? originalName;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? firstAirDate;
  final String? lastAirDate;
  final double voteAverage;
  final int voteCount;
  final double popularity;
  final bool adult;
  final String? originalLanguage;
  final List<int>? genreIds;
  final List<Genre>? genres;
  final int? numberOfEpisodes;
  final int? numberOfSeasons;
  final String? status;
  final String? type;
  final bool inProduction;
  final List<Creator>? createdBy;
  final List<int>? episodeRunTime;
  final Credits? aggregateCredits;
  final Images? images;
  final Videos? videos;
  final TvResponse? similar;

  const TvShow({
    required this.id,
    required this.name,
    this.originalName,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.firstAirDate,
    this.lastAirDate,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.popularity = 0.0,
    this.adult = false,
    this.originalLanguage,
    this.genreIds,
    this.genres,
    this.numberOfEpisodes,
    this.numberOfSeasons,
    this.status,
    this.type,
    this.inProduction = false,
    this.createdBy,
    this.episodeRunTime,
    this.aggregateCredits,
    this.images,
    this.videos,
    this.similar,
  });

  factory TvShow.fromJson(Map<String, dynamic> json) {
    return TvShow(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      originalName: json['original_name'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      firstAirDate: json['first_air_date'],
      lastAirDate: json['last_air_date'],
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      popularity: (json['popularity'] ?? 0.0).toDouble(),
      adult: json['adult'] ?? false,
      originalLanguage: json['original_language'],
      genreIds: (json['genre_ids'] as List<dynamic>?)?.cast<int>(),
      genres: (json['genres'] as List<dynamic>?)?.map((e) => Genre.fromJson(e)).toList(),
      numberOfEpisodes: json['number_of_episodes'],
      numberOfSeasons: json['number_of_seasons'],
      status: json['status'],
      type: json['type'],
      inProduction: json['in_production'] ?? false,
      createdBy: (json['created_by'] as List<dynamic>?)?.map((e) => Creator.fromJson(e)).toList(),
      episodeRunTime: (json['episode_run_time'] as List<dynamic>?)?.cast<int>(),
      aggregateCredits: json['aggregate_credits'] != null ? Credits.fromJson(json['aggregate_credits']) : null,
      images: json['images'] != null ? Images.fromJson(json['images']) : null,
      videos: json['videos'] != null ? Videos.fromJson(json['videos']) : null,
      similar: json['similar'] != null ? TvResponse.fromJson(json['similar']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'original_name': originalName,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'first_air_date': firstAirDate,
      'last_air_date': lastAirDate,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'popularity': popularity,
      'adult': adult,
      'original_language': originalLanguage,
      'genre_ids': genreIds,
      'genres': genres?.map((e) => e.toJson()).toList(),
      'number_of_episodes': numberOfEpisodes,
      'number_of_seasons': numberOfSeasons,
      'status': status,
      'type': type,
      'in_production': inProduction,
      'created_by': createdBy?.map((e) => e.toJson()).toList(),
      'episode_run_time': episodeRunTime,
      'aggregate_credits': aggregateCredits?.toJson(),
      'images': images?.toJson(),
      'videos': videos?.toJson(),
      'similar': similar?.toJson(),
    };
  }
}

class Genre {
  final int id;
  final String name;

  const Genre({
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

class Credits {
  final List<Cast>? cast;
  final List<Crew>? crew;

  const Credits({
    this.cast,
    this.crew,
  });

  factory Credits.fromJson(Map<String, dynamic> json) {
    return Credits(
      cast: (json['cast'] as List<dynamic>?)?.map((e) => Cast.fromJson(e)).toList(),
      crew: (json['crew'] as List<dynamic>?)?.map((e) => Crew.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cast': cast?.map((e) => e.toJson()).toList(),
      'crew': crew?.map((e) => e.toJson()).toList(),
    };
  }
}

class Cast {
  final int id;
  final String name;
  final String? originalName;
  final String? profilePath;
  final String? character;
  final String? creditId;
  final int? order;
  final int? gender;
  final String? knownForDepartment;
  final double popularity;

  const Cast({
    required this.id,
    required this.name,
    this.originalName,
    this.profilePath,
    this.character,
    this.creditId,
    this.order,
    this.gender,
    this.knownForDepartment,
    this.popularity = 0.0,
  });

  factory Cast.fromJson(Map<String, dynamic> json) {
    return Cast(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      originalName: json['original_name'],
      profilePath: json['profile_path'],
      character: json['character'],
      creditId: json['credit_id'],
      order: json['order'],
      gender: json['gender'],
      knownForDepartment: json['known_for_department'],
      popularity: (json['popularity'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'original_name': originalName,
      'profile_path': profilePath,
      'character': character,
      'credit_id': creditId,
      'order': order,
      'gender': gender,
      'known_for_department': knownForDepartment,
      'popularity': popularity,
    };
  }
}

class Crew {
  final int id;
  final String name;
  final String? originalName;
  final String? profilePath;
  final String? job;
  final String? department;
  final String? creditId;
  final int? gender;
  final String? knownForDepartment;
  final double popularity;

  const Crew({
    required this.id,
    required this.name,
    this.originalName,
    this.profilePath,
    this.job,
    this.department,
    this.creditId,
    this.gender,
    this.knownForDepartment,
    this.popularity = 0.0,
  });

  factory Crew.fromJson(Map<String, dynamic> json) {
    return Crew(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      originalName: json['original_name'],
      profilePath: json['profile_path'],
      job: json['job'],
      department: json['department'],
      creditId: json['credit_id'],
      gender: json['gender'],
      knownForDepartment: json['known_for_department'],
      popularity: (json['popularity'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'original_name': originalName,
      'profile_path': profilePath,
      'job': job,
      'department': department,
      'credit_id': creditId,
      'gender': gender,
      'known_for_department': knownForDepartment,
      'popularity': popularity,
    };
  }
}

class Creator {
  final int id;
  final String name;
  final String? originalName;
  final String? profilePath;
  final String? creditId;
  final int? gender;

  const Creator({
    required this.id,
    required this.name,
    this.originalName,
    this.profilePath,
    this.creditId,
    this.gender,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      originalName: json['original_name'],
      profilePath: json['profile_path'],
      creditId: json['credit_id'],
      gender: json['gender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'original_name': originalName,
      'profile_path': profilePath,
      'credit_id': creditId,
      'gender': gender,
    };
  }
}

class Images {
  final List<ImageData>? backdrops;
  final List<ImageData>? posters;

  const Images({
    this.backdrops,
    this.posters,
  });

  factory Images.fromJson(Map<String, dynamic> json) {
    return Images(
      backdrops: (json['backdrops'] as List<dynamic>?)?.map((e) => ImageData.fromJson(e)).toList(),
      posters: (json['posters'] as List<dynamic>?)?.map((e) => ImageData.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'backdrops': backdrops?.map((e) => e.toJson()).toList(),
      'posters': posters?.map((e) => e.toJson()).toList(),
    };
  }
}

class ImageData {
  final String filePath;
  final int? width;
  final int? height;
  final double voteAverage;
  final int voteCount;
  final String? iso6391;

  const ImageData({
    required this.filePath,
    this.width,
    this.height,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.iso6391,
  });

  factory ImageData.fromJson(Map<String, dynamic> json) {
    return ImageData(
      filePath: json['file_path'] ?? '',
      width: json['width'],
      height: json['height'],
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      iso6391: json['iso_639_1'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_path': filePath,
      'width': width,
      'height': height,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'iso_639_1': iso6391,
    };
  }
}

class Videos {
  final List<Video>? results;

  const Videos({
    this.results,
  });

  factory Videos.fromJson(Map<String, dynamic> json) {
    return Videos(
      results: (json['results'] as List<dynamic>?)?.map((e) => Video.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results?.map((e) => e.toJson()).toList(),
    };
  }
}

class Video {
  final String id;
  final String iso6391;
  final String iso31661;
  final String key;
  final String name;
  final String site;
  final int size;
  final String type;
  final bool official;
  final String? publishedAt;

  const Video({
    required this.id,
    required this.iso6391,
    required this.iso31661,
    required this.key,
    required this.name,
    required this.site,
    required this.size,
    required this.type,
    this.official = false,
    this.publishedAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? '',
      iso6391: json['iso_639_1'] ?? '',
      iso31661: json['iso_3166_1'] ?? '',
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      site: json['site'] ?? '',
      size: json['size'] ?? 0,
      type: json['type'] ?? '',
      official: json['official'] ?? false,
      publishedAt: json['published_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'iso_639_1': iso6391,
      'iso_3166_1': iso31661,
      'key': key,
      'name': name,
      'site': site,
      'size': size,
      'type': type,
      'official': official,
      'published_at': publishedAt,
    };
  }
}

class MovieResponse {
  final int? page;
  final List<Movie>? results;
  final int? totalPages;
  final int? totalResults;

  const MovieResponse({
    this.page,
    this.results,
    this.totalPages,
    this.totalResults,
  });

  factory MovieResponse.fromJson(Map<String, dynamic> json) {
    return MovieResponse(
      page: json['page'],
      results: (json['results'] as List<dynamic>?)?.map((e) => Movie.fromJson(e)).toList(),
      totalPages: json['total_pages'],
      totalResults: json['total_results'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'results': results?.map((e) => e.toJson()).toList(),
      'total_pages': totalPages,
      'total_results': totalResults,
    };
  }
}

class TvResponse {
  final int? page;
  final List<TvShow>? results;
  final int? totalPages;
  final int? totalResults;

  const TvResponse({
    this.page,
    this.results,
    this.totalPages,
    this.totalResults,
  });

  factory TvResponse.fromJson(Map<String, dynamic> json) {
    return TvResponse(
      page: json['page'],
      results: (json['results'] as List<dynamic>?)?.map((e) => TvShow.fromJson(e)).toList(),
      totalPages: json['total_pages'],
      totalResults: json['total_results'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'results': results?.map((e) => e.toJson()).toList(),
      'total_pages': totalPages,
      'total_results': totalResults,
    };
  }
}