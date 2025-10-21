import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_config.dart';

/// AI + TMDB recommender (entity-first → AI → multi-source, no DB)
/// - Tầng 0: Hiểu tiếng Việt & nhận diện thực thể (franchise/tựa phim/chủ đề)
/// - Tầng 1: Gemini trích genres/mood/keywords (auto chọn model, fallback)
/// - Tầng 2: TMDB rộng rãi: search/multi, search/movie, search/tv,
///           search/collection + collection parts, discover, similar, recommendations
///           → merge + dedupe + rerank mạnh theo title/tokens/mood.
class GeminiService {
  final Dio tmdb;
  GeminiService({required this.tmdb});

  // ---------------- Gemini model resolver (auto pick alive model) ----------------
  static GenerativeModel? _gemini;
  static String? _chosenModelName;
  static bool _isResolving = false;

  static const List<String> _modelPriority = [
    'gemini-2.5-flash','gemini-2.5-flash-latest',
    'gemini-2.5-pro','gemini-2.5-pro-latest',
    'gemini-2.0-flash','gemini-2.0-flash-latest',
    'gemini-2.0-pro','gemini-2.0-pro-latest',
    'gemini-1.5-flash','gemini-1.5-flash-latest',
    'gemini-1.5-pro','gemini-1.5-pro-latest',
  ];

  static Future<GenerativeModel> _ensureModel() async {
    if (_gemini != null) return _gemini!;
    if (_isResolving) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_gemini != null) return _gemini!;
    }
    _isResolving = true;
    try {
      final name = await _resolveAvailableModel();
      _chosenModelName = name;
      // ignore: avoid_print
      print('🔁 Gemini chosen model: $_chosenModelName');
      _gemini = GenerativeModel(
        model: name,
        apiKey: AppConfig.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.5, topK: 40, topP: 0.95, maxOutputTokens: 1024,
        ),
      );
      return _gemini!;
    } finally { _isResolving = false; }
  }

  static Future<String> _resolveAvailableModel() async {
    try {
      final resp = await Dio().get(
        'https://generativelanguage.googleapis.com/v1/models',
        queryParameters: {'key': AppConfig.geminiApiKey},
      );
      final models = ((resp.data?['models'] ?? []) as List).cast<Map<String, dynamic>>();
      final supported = <String>{};
      for (final m in models) {
        final name = (m['name'] as String?) ?? '';
        final methods = (m['supportedGenerationMethods'] ??
                         m['supported_generation_methods'] ?? []) as List?;
        final hasGen = (methods ?? []).map((e) => e.toString()).contains('generateContent');
        if (name.isNotEmpty && hasGen) {
          final short = name.contains('/') ? name.split('/').last : name;
          supported.add(short);
        }
      }
      for (final prefer in _modelPriority) {
        if (supported.contains(prefer)) return prefer;
      }
      if (supported.isNotEmpty) return supported.first;
      throw StateError('No Gemini model with generateContent available for this key.');
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ ListModels failed: $e');
      return 'gemini-2.5-flash';
    }
  }

  // ---------------- Public API ----------------

  Future<List<Map<String, dynamic>>> getMovieRecommendationsByDescription(
    String description, {
    String language = 'vi-VN',
    int page = 1,
    bool includeTv = true,
  }) async => _aiSearch(description, language: language, page: page, includeTv: includeTv);

  Future<List<Map<String, dynamic>>> getMoviesByMood(
    String mood, {
    String language = 'vi-VN',
    int page = 1,
    bool includeTv = true,
  }) async => _aiSearch("mood: $mood", language: language, page: page, includeTv: includeTv);

  Future<List<Map<String, dynamic>>> getMoviesByGenre(
    String genre, {
    String language = 'vi-VN',
    int page = 1,
    bool includeTv = true,
  }) async => _aiSearch(genre, language: language, page: page, includeTv: includeTv);

  Future<List<Map<String, dynamic>>> getMoviesByYearAndGenre(
    int year, String genre, {
    String language = 'vi-VN',
    int page = 1,
    bool includeTv = true,
  }) async => _aiSearch('$genre $year', language: language, page: page, includeTv: includeTv);

  Future<List<Map<String, dynamic>>> searchMoviesByNaturalLanguage(
    String query, {
    String language = 'vi-VN',
    int page = 1,
    bool includeTv = true,
  }) async => _aiSearch(query, language: language, page: page, includeTv: includeTv);

  // ---------------- Core pipeline ----------------

  Future<List<Map<String, dynamic>>> _aiSearch(
    String raw, {required String language, required int page, required bool includeTv}
  ) async {
    print('🔍 GeminiService: Bắt đầu tìm kiếm "$raw"');
    final ent = _EntityResolver.fromText(raw);
    final intent = _intentFromQuery(raw);

    // Luôn chạy AI
    print('🔍 Tầng 1: Gemini AI analysis');
    final spec = await _analyzeWithGemini(raw);

    // Tầng 0 (nếu có) chỉ là nguồn phụ
    List<Map<String, dynamic>> r0 = const [];
    if (ent.isStrongHit) {
      print('🔍 Tầng 0: Entity-first fetch');
      r0 = await _entityFirstFetch(ent, language: language, page: page, includeTv: includeTv);
    }

    // Tầng 2: multi-source theo AI + intent (ngôn ngữ/công ty)
    print('🔍 Tầng 2: Multi-source fetch');
    final rAI = await _multiSourceFetch(
      spec, language: language, page: page, fallbackQuery: raw, includeTv: includeTv,
      userTokens: _tokenize(_normalize(raw)), hardTitleBoost: ent.candidateTitles, intent: intent,
    );

    // Hợp nhất, ưu tiên AI + lọc bắt buộc "liên quan"
    final merged = _dedupeByIdAndType([
      ...rAI.map((m) => {...m, '__src': 'ai'}),
      ...r0.map((m)  => {...m, '__src': 'entity'}),
    ]);

    final filtered = _mustMatch(spec, intent, _tokenize(_normalize(raw)), merged);

    final scored = filtered.map((m) {
      final base = 0; // điểm sẽ cộng trong _rerankHybrid lại phía dưới
      final bonus = m['__src']=='ai' ? 8 : 0;
      return MapEntry(m, base + bonus);
    }).toList();

    // Dùng lại _rerankHybrid để sắp xếp cuối
    final reranked = _rerankHybrid(
      scored.map((e)=>e.key).toList(),
      queryTokens: _tokenize(_normalize(raw)),
      hardTitleBoost: ent.candidateTitles,
      spec: spec,
      intent: intent,
    );

    final result = reranked.take(30).map(_projectUnified).toList();
    print('🔍 AI Search: Final = ${result.length}');
    return result;
  }

  Future<_Spec> _analyzeWithGemini(String text) async {
    final prompt = '''
Bạn là chuyên gia gợi ý phim. Phân tích yêu cầu sau và trả về JSON **hợp lệ** duy nhất:
Yêu cầu: "$text"

JSON schema:
{
  "genres": ["romance","thriller",...],        // tối đa 3
  "mood": ["dark","feel-good","tense",...],    // 0-3
  "keywords": ["space","time travel",...],     // 0-6, tiếng Anh
  "year": 0,                                   // 0 nếu không rõ
  "avoid": ["gore","nudity", ...]              // 0-5
}
Chỉ in JSON, không giải thích thêm.
''';
    try {
      final model = await _ensureModel();
      final resp = await model.generateContent([Content.text(prompt)]);
      final txt = resp.text?.trim() ?? '';
      final jsonStr = _extractPureJson(txt);
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final spec = _Spec.fromMap(map);
      // ignore: avoid_print
      print('Gemini spec: ${json.encode({
        'model': _chosenModelName,
        'genres': spec.genres,
        'mood': spec.mood,
        'keywords': spec.keywords,
        'year': spec.year ?? 0,
        'avoid': spec.avoid
      })}');
      return spec;
    } catch (e) {
      // ignore: avoid_print
      print('Gemini analyze error: $e');
      return _Spec.empty();
    }
  }

  // ---------------- Entity-first fetch ----------------

  Future<List<Map<String, dynamic>>> _entityFirstFetch(
    _EntityResolver ent, {
    required String language,
    required int page,
    required bool includeTv,
  }) async {
    print('🔍 Entity-first: queries=${ent.queries}, keywordText=${ent.keywordText}');
    final all = <Map<String, dynamic>>[];

    // 1) Nếu có franchise/title → search multi + movie + tv
    for (final q in ent.queries) {
      print('🔍 Entity-first: Search query "$q"');
      final multi = await _safeFetch('/search/multi', {
        'language': language, 'page': 1, 'query': q,
      });
      print('🔍 Entity-first: Multi search = ${multi.length}');
      all.addAll(_tagMedia(multi, 'mixed'));
      
      final movie = await _safeFetch('/search/movie', {
        'language': language, 'page': 1, 'include_adult': false, 'query': q,
      });
      print('🔍 Entity-first: Movie search = ${movie.length}');
      all.addAll(_tagMedia(movie, 'movie'));
      
      if (includeTv) {
        final tv = await _safeFetch('/search/tv', {
          'language': language, 'page': 1, 'query': q,
        });
        print('🔍 Entity-first: TV search = ${tv.length}');
        all.addAll(_tagMedia(tv, 'tv'));
      }
      
      // 2) Collections (ví dụ Doraemon sẽ có cả series điện ảnh)
      final collections = await _safeFetch('/search/collection', {
        'language': language, 'page': 1, 'query': q,
      });
      print('🔍 Entity-first: Collections = ${collections.length}');
      for (final c in collections) {
        final colId = (c['id'] ?? -1) as int;
        if (colId > 0) {
          try {
            final r = await tmdb.get('/collection/$colId', queryParameters: {'language': language});
            final parts = (r.data['parts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
            print('🔍 Entity-first: Collection $colId parts = ${parts.length}');
            all.addAll(_tagMedia(parts, 'movie'));
          } catch (e) {
            print('❌ Entity-first: Collection error $colId: $e');
          }
        }
      }
    }

    // 3) Nếu có chủ đề (ví dụ "phim mẹ") → keywordIDs → discover
    if (ent.keywordText.isNotEmpty) {
      print('🔍 Entity-first: Resolving keywords "${ent.keywordText}"');
      final kIds = await _resolveKeywordIds(ent.keywordText);
      print('🔍 Entity-first: Keyword IDs = $kIds');
      if (kIds.isNotEmpty) {
        final discoverMovie = await _safeFetch('/discover/movie', {
          'language': language, 'page': page, 'include_adult': false,
          'with_keywords': kIds.join(','), 'vote_count.gte': 5, 'sort_by': 'popularity.desc',
        });
        print('🔍 Entity-first: Discover movie = ${discoverMovie.length}');
        all.addAll(_tagMedia(discoverMovie, 'movie'));
        
        if (includeTv) {
          final discoverTv = await _safeFetch('/discover/tv', {
            'language': language, 'page': page,
            'with_keywords': kIds.join(','), 'vote_count.gte': 5, 'sort_by': 'popularity.desc',
          });
          print('🔍 Entity-first: Discover TV = ${discoverTv.length}');
          all.addAll(_tagMedia(discoverTv, 'tv'));
        }
      }
    }

    print('🔍 Entity-first: Total before dedup = ${all.length}');
    final dedup = _dedupeByIdAndType(all);
    print('🔍 Entity-first: After dedup = ${dedup.length}');
    
    final reranked = _rerankStrongTitle(
      dedup,
      titles: ent.candidateTitles,
      tokens: _tokenize(_normalize(ent.originalText)),
      preferLang: ent.preferOriginalLang,
    );
    print('🔍 Entity-first: After rerank = ${reranked.length}');
    
    final result = reranked.take(30).map(_projectUnified).toList();
    print('🔍 Entity-first: Final result = ${result.length}');
    return result;
  }

  // ---------------- Multi-source (AI spec + rộng rãi) ----------------

  Future<List<Map<String, dynamic>>> _multiSourceFetch(
    _Spec spec, {
    required String language,
    required int page,
    required String fallbackQuery,
    required bool includeTv,
    required List<String> userTokens,
    required List<String> hardTitleBoost,
    required _Intent intent,
  }) async {
    final genreNames = _expandRelatedGenres(spec.genres);
    final genreIdsMovie = _mapMovieGenresToIds(genreNames);
    final genreIdsTv = _mapTvGenresToIds(genreNames);
    
    // Chỉ dùng with_keywords khi đến từ AI-spec, và nếu có >1 ID thì dùng OR (|) thay vì , (AND)
    final bool useAiKeywords = spec.keywords.isNotEmpty;
    final keywordText = useAiKeywords ? spec.keywords.join(' ') : ''; // ❗️không fallback sang raw
    final keywordIds = useAiKeywords ? await _resolveKeywordIds(keywordText) : const <int>[];

    String? withKeywordsParam() {
      if (keywordIds.isEmpty) return null;
      // Dùng OR để mở rộng phủ (id1|id2|id3) thay vì AND (id1,id2,id3)
      return keywordIds.take(4).join('|');
    }

    // Helper cho năm
    String? _y(int? y) => (y != null && y > 0) ? y.toString() : null;

    Map<String, dynamic> baseMovie(int? year) => {
      'language': language,
      'page': page,
      'include_adult': false,
      if (genreIdsMovie.isNotEmpty) 'with_genres': genreIdsMovie.join(','),
      if (withKeywordsParam() != null) 'with_keywords': withKeywordsParam(),
      if (_y(spec.year) != null) ...{
        'primary_release_date.gte': '${spec.year}-01-01',
        'primary_release_date.lte': '${spec.year}-12-31',
      },
      if (intent.originalLang != null) 'with_original_language': intent.originalLang,
      if (intent.originCountry != null) 'with_origin_country': intent.originCountry,
      if (intent.companies.isNotEmpty) 'with_companies': intent.companies.join(','), // Disney/Pixar/Marvel...
      'vote_count.gte': 5,
      'sort_by': _sortByForMood(spec.mood),
    };

    Map<String, dynamic> baseTv(int? year) => {
      'language': language,
      'page': page,
      if (genreIdsTv.isNotEmpty) 'with_genres': genreIdsTv.join(','),
      if (withKeywordsParam() != null) 'with_keywords': withKeywordsParam(),
      if (_y(spec.year) != null) ...{
        'first_air_date.gte': '${spec.year}-01-01',
        'first_air_date.lte': '${spec.year}-12-31',
      },
      if (intent.originalLang != null) 'with_original_language': intent.originalLang,
      if (intent.originCountry != null) 'with_origin_country': intent.originCountry,
      if (intent.networks.isNotEmpty) 'with_networks': intent.networks.join(','), // Disney+ / Netflix...
      'vote_count.gte': 5,
      'sort_by': _sortByForMood(spec.mood),
    };

    // 1) discover/search movie
    final discoverMovies = await _safeFetch('/discover/movie', baseMovie(spec.year));
    final searchMovies = await _safeFetch('/search/movie', {
      'language': language, 'page': 1, 'include_adult': false,
      // nếu không có AI keywords, tìm với 1 từ khóa "an toàn", VD: "2024"
      'query': useAiKeywords && keywordText.isNotEmpty
               ? keywordText
               : (spec.year != null ? spec.year.toString() : 'movie'),
    });

    // 2) similar/recommendations (movie) từ vài seed
    final seedsMovie = _topSeeds(discoverMovies, searchMovies, max: 3);
    final similarMovies = <Map<String, dynamic>>[];
    final recommendMovies = <Map<String, dynamic>>[];
    for (final id in seedsMovie) {
      similarMovies.addAll(await _safeFetch('/movie/$id/similar', {'language': language}));
      recommendMovies.addAll(await _safeFetch('/movie/$id/recommendations', {'language': language}));
    }

    // 3) TV (optional)
    List<Map<String, dynamic>> discoverTv = [];
    List<Map<String, dynamic>> searchTv = [];
    List<Map<String, dynamic>> similarTv = [];
    List<Map<String, dynamic>> recommendTv = [];
    if (includeTv) {
      discoverTv = await _safeFetch('/discover/tv', baseTv(spec.year));
      searchTv = await _safeFetch('/search/tv', {
        'language': language, 'page': 1,
        'query': useAiKeywords && keywordText.isNotEmpty
                 ? keywordText
                 : (spec.year != null ? spec.year.toString() : 'tv'),
      });
      final seedsTv = _topSeeds(discoverTv, searchTv, max: 3);
      for (final id in seedsTv) {
        similarTv.addAll(await _safeFetch('/tv/$id/similar', {'language': language}));
        recommendTv.addAll(await _safeFetch('/tv/$id/recommendations', {'language': language}));
      }
    }

    final combined = <Map<String, dynamic>>[
      ..._tagMedia(discoverMovies, 'movie'),
      ..._tagMedia(searchMovies, 'movie'),
      ..._tagMedia(similarMovies, 'movie'),
      ..._tagMedia(recommendMovies, 'movie'),
      if (includeTv) ..._tagMedia(discoverTv, 'tv'),
      if (includeTv) ..._tagMedia(searchTv, 'tv'),
      if (includeTv) ..._tagMedia(similarTv, 'tv'),
      if (includeTv) ..._tagMedia(recommendTv, 'tv'),
    ];

    final deduped = _dedupeByIdAndType(combined);
    final reranked = _rerankHybrid(
      deduped,
      queryTokens: userTokens,
      hardTitleBoost: hardTitleBoost,
      spec: spec,
      intent: intent,
    );
    return reranked.take(30).map(_projectUnified).toList();
  }

  // Bộ lọc "bắt buộc liên quan" sau khi merge (loại item lạc đề)
  List<Map<String, dynamic>> _mustMatch(_Spec spec, _Intent intent, List<String> qTokens, List<Map<String, dynamic>> items) {
    final wantHorror = spec.genres.map((e)=>e.toLowerCase()).contains('horror');
    final qSet = qTokens.toSet();

    bool langOk(Map m) {
      final ol = (m['original_language'] ?? '').toString().toLowerCase();
      if (intent.originalLang != null && intent.originalLang!.isNotEmpty) {
        if (ol != intent.originalLang) return false;
      }
      return true;
    }

    bool genreOk(Map m) {
      if (!wantHorror) return true;
      final g = ((m['genre_ids'] ?? []) as List).cast<int>();
      return g.contains(27); // TMDB horror
    }

    bool relevanceOk(Map m) {
      final title = _normalize((m['title'] ?? m['name'] ?? '').toString());
      final ov = _normalize((m['overview'] ?? '').toString());
      final overlap = _tokenize(title).where(qSet.contains).length + (_tokenize(ov).where(qSet.contains).length ~/ 2);
      // Yêu cầu tối thiểu: có khớp 1 token hoặc đúng genre khi có yêu cầu genre
      return overlap >= 1 || genreOk(m);
    }

    return items.where((m) => langOk(m) && relevanceOk(m)).toList();
  }

  // ---------------- Low-level helpers ----------------

  Future<List<Map<String, dynamic>>> _safeFetch(String path, Map<String, dynamic> params) async {
    try {
      final r = await tmdb.get(path, queryParameters: params);
      final list = (r.data['results'] as List?) ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (_) { return []; }
  }


  static String _extractPureJson(String text) {
    final codeBlock = RegExp(r'```json\s*([\s\S]*?)```', multiLine: true);
    final m = codeBlock.firstMatch(text);
    if (m != null) return m.group(1)!.trim();
    final start = text.indexOf('{'); final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) return text.substring(start, end + 1);
    return '{"genres":[],"mood":[],"keywords":[],"year":0,"avoid":[]}';
  }

  static const Map<String, int> _movieGenreId = {
    'action': 28, 'adventure': 12, 'animation': 16, 'comedy': 35, 'crime': 80,
    'documentary': 99, 'drama': 18, 'family': 10751, 'fantasy': 14, 'history': 36,
    'horror': 27, 'music': 10402, 'mystery': 9648, 'romance': 10749,
    'science fiction': 878, 'sci-fi': 878, 'tv movie': 10770, 'thriller': 53,
    'war': 10752, 'western': 37,
  };
  static const Map<String, int> _tvGenreId = {
    'action': 10759, 'adventure': 10759, 'animation': 16, 'comedy': 35, 'crime': 80,
    'documentary': 99, 'drama': 18, 'family': 10751, 'kids': 10762, 'mystery': 9648,
    'news': 10763, 'reality': 10764, 'sci-fi': 10765, 'science fiction': 10765,
    'soap': 10766, 'talk': 10767, 'war': 10768, 'war & politics': 10768, 'western': 37,
  };

  List<int> _mapMovieGenresToIds(List<String> names) {
    final ids = <int>[]; for (final n in names) { final k = n.trim().toLowerCase(); if (_movieGenreId.containsKey(k)) ids.add(_movieGenreId[k]!); }
    return ids.toSet().toList();
  }
  List<int> _mapTvGenresToIds(List<String> names) {
    final ids = <int>[]; for (final n in names) { final k = n.trim().toLowerCase(); if (_tvGenreId.containsKey(k)) ids.add(_tvGenreId[k]!); }
    return ids.toSet().toList();
  }

  List<String> _expandRelatedGenres(List<String> base) {
    const related = {
      'romance': ['drama', 'comedy'],
      'comedy': ['romance', 'family'],
      'horror': ['thriller', 'mystery'],
      'thriller': ['crime', 'mystery', 'horror'],
      'science fiction': ['sci-fi', 'adventure'],
      'sci-fi': ['science fiction', 'adventure'],
      'action': ['adventure', 'thriller'],
      'drama': ['romance', 'family'],
      'family': ['animation', 'comedy'],
      'animation': ['family', 'adventure'],
    };
    final out = <String>{...base.map((e) => e.toLowerCase())};
    for (final g in base) { for (final r in (related[g.toLowerCase()] ?? const [])) out.add(r); }
    return out.toList();
  }

  String _sortByForMood(List<String> mood) {
    final m = mood.map((e) => e.toLowerCase()).toList();
    if (m.contains('feel-good') || m.contains('happy') || m.contains('uplifting')) {
      return 'vote_average.desc';
    }
    if (m.contains('dark') || m.contains('tense')) return 'popularity.desc';
    return 'popularity.desc';
  }

  List<int> _topSeeds(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b, {
    int max = 3,
  }) {
    final merged = [...a, ...b];
    merged.sort((x, y) {
      final vx = (x['vote_average'] ?? 0).toDouble();
      final vy = (y['vote_average'] ?? 0).toDouble();
      final px = (x['popularity'] ?? 0).toDouble();
      final py = (y['popularity'] ?? 0).toDouble();
      return (vy + py / 50).compareTo(vx + px / 50);
    });
    final ids = <int>[];
    for (final m in merged) {
      final id = (m['id'] ?? -1) as int;
      if (id > 0) ids.add(id);
      if (ids.length >= max) break;
    }
    return ids;
  }

  List<Map<String, dynamic>> _tagMedia(List<Map<String, dynamic>> list, String type) =>
    list.map((m) => {...m, 'media_type': type}).toList();

  List<Map<String, dynamic>> _dedupeByIdAndType(List<Map<String, dynamic>> items) {
    final seen = <String, Map<String, dynamic>>{};
    for (final m in items) {
      final id = (m['id'] ?? -1).toString();
      final t = (m['media_type'] ?? (m.containsKey('name') ? 'tv' : 'movie')).toString();
      seen['$t/$id'] = m;
    }
    return seen.values.toList();
  }

  // Hard boost cho title match (chỉ khi khớp mạnh)
  int _hardBoostFor(String h, String title) {
    if (h.isEmpty) return 0;
    final hTokens = _tokenize(h);
    if (hTokens.isEmpty) return 0;
    final titleTokens = _tokenize(title).toSet();
    final overlap = hTokens.where(titleTokens.contains).length;
    final ratio = overlap / hTokens.length;
    if (ratio >= 0.6) return 40;            // khớp mạnh
    if (ratio >= 0.4) return 20;            // khớp vừa
    return 0;                               // không khớp thì không boost
  }

  // Rerank mạnh theo title match + token overlap + score + recency + mood/avoid
  List<Map<String, dynamic>> _rerankHybrid(
    List<Map<String, dynamic>> items, {
    required List<String> queryTokens,
    required List<String> hardTitleBoost,
    required _Spec spec,
    _Intent? intent,
  }) {
    final qSet = queryTokens.toSet();
    final avoid = spec.avoid.map((e) => e.toLowerCase()).toList();
    final mood = spec.mood.map((e) => e.toLowerCase()).toList();
    final hard = hardTitleBoost.map(_normalize).toSet();

    int scoreOf(Map<String, dynamic> m) {
      int s = 0;
      final title = _normalize((m['title'] ?? m['name'] ?? '').toString());
      final ov = _normalize((m['overview'] ?? '').toString());

      for (final h in hard) { s += _hardBoostFor(h, title); }
      final tks = _tokenize(title);
      final ovTks = _tokenize(ov);
      final overlap = tks.where(qSet.contains).length + (ovTks.where(qSet.contains).length ~/ 2);
      s += overlap * 8; // ↑ tăng trọng số liên quan

      final va = (m['vote_average'] ?? 0).toDouble().clamp(0.0, 10.0);
      final pop = (m['popularity'] ?? 0).toDouble();
      s += va.round() as int;         // ↓
      s += (pop > 1000 ? 25 : (pop/50).round() as int); // ↓ nén popularity

      final date = (m['release_date'] ?? m['first_air_date'] ?? '').toString();
      if (date.length >= 4) {
        final y = int.tryParse(date.substring(0, 4)) ?? 0;
        if (y >= 2020) s += 3;
        if (y >= 2023) s += 2;
      }

      final gIds = ((m['genre_ids'] ?? []) as List).cast<int>();
      if (mood.contains('feel-good')) if (gIds.any((g) => [35, 10751, 16].contains(g))) s += 3;
      if (mood.contains('dark') || mood.contains('tense')) if (gIds.any((g) => [27, 53, 80, 9648].contains(g))) s += 2;

      // Thưởng nếu trùng original_language/khu vực từ intent
      if (intent != null) {
        final ol = (m['original_language'] ?? '').toString().toLowerCase();
        if (intent.originalLang != null && ol == intent.originalLang) s += 6;
        if (intent.originCountry != null) {
          final prodCountries = ((m['production_countries'] ?? []) as List).cast<Map<String, dynamic>>();
          if (prodCountries.any((c) => (c['iso_3166_1'] ?? '').toString() == intent.originCountry)) s += 6;
        }
      }

      for (final a in avoid) { if (a.isNotEmpty && ov.contains(a)) s -= 6; }
      return s;
    }

    final scored = items.map((m) => MapEntry(m, scoreOf(m))).toList();
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  // Rerank cho entity-first: ưu tiên chính xác tựa/franchise & ngôn ngữ gốc nếu có
  List<Map<String, dynamic>> _rerankStrongTitle(
    List<Map<String, dynamic>> items, {
    required List<String> titles,
    required List<String> tokens,
    String? preferLang,
  }) {
    final hard = titles.map(_normalize).toSet();
    final qSet = tokens.toSet();

    int scoreOf(Map<String, dynamic> m) {
      int s = 0;
      final title = _normalize((m['title'] ?? m['name'] ?? '').toString());
      final ov = _normalize((m['overview'] ?? '').toString());
      for (final h in hard) { s += (_hardBoostFor(h, title) * 1.5).round(); } // boost mạnh hơn cho entity-first
      s += _tokenize(title).where(qSet.contains).length * 8;
      s += _tokenize(ov).where(qSet.contains).length * 3;

      final va = (m['vote_average'] ?? 0).toDouble();
      final pop = (m['popularity'] ?? 0).toDouble();
      s += ((va * 2).round() as int);
      s += ((pop / 40).round() as int);

      final ol = (m['original_language'] ?? '').toString();
      if (preferLang != null && preferLang.isNotEmpty && ol == preferLang) s += 5;
      return s;
    }

    final scored = items.map((m) => MapEntry(m, scoreOf(m))).toList();
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  Future<List<int>> _resolveKeywordIds(String text) async {
    final stop = {'phim','movie','nam','nam2024','xem','theloai','genre'};
    final tokens = _tokenize(_normalize(text))
        .where((t) => t.length >= 3 && !RegExp(r'^\d+$').hasMatch(t) && !stop.contains(t))
        .toList();

    final ids = <int>[];
    for (final t in tokens.take(5)) {
      try {
        final r = await tmdb.get('/search/keyword', queryParameters: {'query': t});
        final list = (r.data['results'] as List?) ?? [];
        if (list.isNotEmpty) {
          final id = (list.first['id'] ?? -1) as int;
          if (id > 0) ids.add(id);
        }
      } catch (_) {}
    }
    return ids.toSet().toList();
  }

  Map<String, dynamic> _projectUnified(Map<String, dynamic> m) {
    final isTv = (m['media_type'] ?? (m.containsKey('name') ? 'tv' : 'movie')) == 'tv';
    return {
      'id': m['id'],
      'media_type': isTv ? 'tv' : 'movie',
      'title': isTv ? (m['name'] ?? '') : (m['title'] ?? ''),
      'overview': m['overview'],
      'poster_path': m['poster_path'],
      'backdrop_path': m['backdrop_path'],
      'release_date': isTv ? m['first_air_date'] : m['release_date'],
      'vote_average': m['vote_average'],
      'vote_count': m['vote_count'],
      'popularity': m['popularity'],
      'genre_ids': m['genre_ids'],
      'original_language': m['original_language'],
    };
  }

  // ---------------- Vietnamese understanding (entity-first) ----------------

  static String _normalize(String s) {
    try {
      final lower = s.toLowerCase().trim();
      const vi = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
      const en = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiioooooooooooooooouuuuuuuuuuuyyyyyd';
      var out = lower;
      
      // Safe character replacement
      for (var i = 0; i < vi.length && i < en.length; i++) { 
        out = out.replaceAll(vi[i], en[i]); 
      }
      
      out = out.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      return out;
    } catch (e) {
      print('❌ Normalize error: $e for input: "$s"');
      // Fallback: simple normalization
      return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    }
  }

  static List<String> _tokenize(String s) {
    try {
      return _normalize(s).split(' ').where((t) => t.isNotEmpty).toList();
    } catch (e) {
      print('❌ Tokenize error: $e for input: "$s"');
      return [];
    }
  }

  // alias/franchise phổ biến (loại bỏ ký tự non-Latin để tránh normalize rỗng)
  static const Map<String, List<String>> _titleAliases = {
    'doraemon': ['doraemon','do re mon','do re mon','doremon','đôrêmon','đô rê mon'],
    'conan': ['conan','detective conan'],
    'harry potter': ['harry potter'],
    'fast and furious': ['fast and furious','fast & furious','fast furious'],
    'avengers': ['avengers','marvel avengers'],
    'spider man': ['spiderman','spider man','spider-man'],
    'batman': ['batman'],
    'naruto': ['naruto'],
    'one piece': ['one piece'],
  };

  // chủ đề tiếng Việt → keyword tiếng Anh
  static const Map<String, List<String>> _topicKeywords = {
    'me': ['mother','mom','motherhood','parenting','family','maternal'],
    'bo': ['father','dad','parenting','family','paternal'],
    'tinh ban': ['friendship','friends','buddy'],
    'hoc duong': ['school','high school','student','campus'],
    'gia dinh': ['family','parenting','kids'],
    'du hanh thoi gian': ['time travel','time-travel'],
    'robot': ['robot','android'],
    'khoa hoc vien tuong': ['science fiction','sci-fi','space'],
  };
}

/// Cấu trúc đặc tả từ Gemini
class _Spec {
  final List<String> genres;
  final List<String> mood;
  final List<String> keywords;
  final int? year;
  final List<String> avoid;

  _Spec({ this.genres = const [], this.mood = const [], this.keywords = const [], this.year, this.avoid = const [] });

  factory _Spec.fromMap(Map<String, dynamic> m) => _Spec(
    genres: (m['genres'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? const [],
    mood: (m['mood'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? const [],
    keywords: (m['keywords'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? const [],
    year: (m['year'] is int && (m['year'] as int) > 0) ? m['year'] as int : null,
    avoid: (m['avoid'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? const [],
  );

  factory _Spec.empty() => _Spec();
}

class _Intent {
  final String? originalLang;     // ví dụ: 'ja'
  final String? originCountry;    // ví dụ: 'JP'
  final List<int> companies;      // ví dụ: [2] (Walt Disney Pictures)
  final List<int> networks;       // ví dụ: [2739] (Disney+)
  
  _Intent({
    this.originalLang, 
    this.originCountry, 
    this.companies = const [], 
    this.networks = const []
  });
  
  bool get isEmpty => originalLang==null && originCountry==null && companies.isEmpty && networks.isEmpty;
}

_Intent _intentFromQuery(String raw) {
  final t = GeminiService._tokenize(raw);
  bool hasAll(List<String> w) => w.every(t.contains);
  String? lang; String? country;
  final companies = <int>[]; final networks = <int>[];

  // Quốc gia/ngôn ngữ phổ biến
  if (hasAll(['nhat','ban']) || t.contains('nhatban') || t.contains('japan') || t.contains('japanese')) { 
    lang='ja'; country='JP'; 
  }
  if (t.contains('han') || hasAll(['han','quoc']) || t.contains('korea') || t.contains('korean')) { 
    lang='ko'; country='KR'; 
  }
  if (t.contains('my') || t.contains('usa') || t.contains('american')) { 
    country ??= 'US'; 
  }
  if (t.contains('anh') || t.contains('uk') || t.contains('british')) { 
    country ??= 'GB'; 
  }

  // Hãng/nhà phát hành
  if (t.contains('disney')) { 
    companies.add(2); /* Walt Disney Pictures */ 
    networks.add(2739); /* Disney+ */ 
  }
  if (t.contains('ghibli') || hasAll(['studio','ghibli'])) { 
    companies.addAll([10342, 21092]); 
  } // Studio Ghibli / GKids
  if (t.contains('pixar')) { 
    companies.add(3); 
  }   // Pixar
  if (t.contains('marvel')) { 
    companies.addAll([420, 7505]); 
  } // Marvel Studios / Marvel Ent.
  if (t.contains('netflix')) { 
    networks.add(213); 
  } // Netflix

  return _Intent(
    originalLang: lang, 
    originCountry: country, 
    companies: companies.toSet().toList(), 
    networks: networks.toSet().toList()
  );
}

/// Bộ nhận diện thực thể tiếng Việt (không LLM)
class _EntityResolver {
  final String originalText;
  final List<String> queries;           // câu truy vấn title/franchise
  final String keywordText;             // chủ đề tiếng Anh (đã map)
  final String? preferOriginalLang;     // ví dụ 'ja' cho Doraemon
  final List<String> candidateTitles;   // để rerank hard-boost

  _EntityResolver({
    required this.originalText,
    required this.queries,
    required this.keywordText,
    required this.preferOriginalLang,
    required this.candidateTitles,
  });

  bool get isStrongHit => queries.isNotEmpty || keywordText.isNotEmpty;

  factory _EntityResolver.fromText(String raw) {
    try {
      print('🔍 EntityResolver: Processing "$raw"');
      final norm = GeminiService._normalize(raw);
      print('🔍 EntityResolver: Normalized to "$norm"');
      final tokens = GeminiService._tokenize(norm);
      print('🔍 EntityResolver: Tokens = $tokens');
      
      final candidates = <String>[];
      final q = <String>[];
      String? preferLang;

      // 1) franchise/title aliases (token-based match + guard)
      for (final entry in GeminiService._titleAliases.entries) {
        for (final al in entry.value) {
          try {
            final aNorm = GeminiService._normalize(al);
            if (aNorm.isEmpty || aNorm.length < 2) continue; // ❗️bỏ alias rỗng/siêu ngắn

            final aTokens = GeminiService._tokenize(aNorm).toSet();
            if (aTokens.isEmpty) continue;

            // match nếu ÍT NHẤT 2 token alias cùng xuất hiện (hoặc alias 1 token thì phải khớp nguyên từ)
            final tokenHits = aTokens.where(tokens.contains).length;
            final strongOneToken = aTokens.length == 1 && tokens.contains(aTokens.first);

            if (tokenHits >= 2 || strongOneToken) {
              q.add(al);                 // giữ nguyên alias để search
              candidates.add(entry.key); // canonical title cho rerank
              if (['doraemon','conan','naruto','one piece'].contains(entry.key)) {
                preferLang = 'ja';
              }
            }
          } catch (e) {
            print('❌ EntityResolver: Error processing alias "$al": $e');
          }
        }
      }

      // 2) topic Vietnamese → English keywords (chặt hơn, theo cụm/tokens)
      final kw = <String>[];

      bool hasAll(List<String> words) => words.every(tokens.contains);

      // Cụm chuẩn ("phim me", "phim bo", "hoc duong", ...)
      try {
        if (hasAll(['phim','me'])) kw.addAll(GeminiService._topicKeywords['me']!);
        if (hasAll(['phim','bo'])) kw.addAll(GeminiService._topicKeywords['bo']!);
        if (hasAll(['hoc','duong'])) kw.addAll(GeminiService._topicKeywords['hoc duong'] ?? const []);
        if (hasAll(['gia','dinh'])) kw.addAll(GeminiService._topicKeywords['gia dinh'] ?? const []);
        if (hasAll(['du','hanh','thoi','gian'])) kw.addAll(GeminiService._topicKeywords['du hanh thoi gian'] ?? const []);
        if (tokens.contains('robot')) kw.addAll(GeminiService._topicKeywords['robot'] ?? const []);
        if (hasAll(['khoa','hoc','vien','tuong'])) kw.addAll(GeminiService._topicKeywords['khoa hoc vien tuong'] ?? const []);
      } catch (e) {
        print('❌ EntityResolver: Error processing heuristics: $e');
      }

      final result = _EntityResolver(
        originalText: raw,
        queries: q.toSet().toList(),
        keywordText: kw.toSet().join(' '),
        preferOriginalLang: preferLang,
        candidateTitles: candidates.toSet().toList(),
      );
      
      print('🔍 EntityResolver: Result = queries=${result.queries}, keywordText=${result.keywordText}, isStrongHit=${result.isStrongHit}');
      return result;
    } catch (e) {
      print('❌ EntityResolver: Error processing "$raw": $e');
      return _EntityResolver(
        originalText: raw,
        queries: const [],
        keywordText: '',
        preferOriginalLang: null,
        candidateTitles: const [],
      );
    }
  }
}