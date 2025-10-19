import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/movie.dart';
import '../../core/providers/tmdb_provider.dart';
import '../../core/services/translation_service.dart';
import '../movie_detail/movie_detail_screen.dart';
import '../movie_detail/tv_show_detail_screen.dart';

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  bool _isSearchFocused = false;
  final TranslationService _translationService = TranslationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Stack(
        children: [
          // Main content
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: SizedBox(height: _tabController.index == 0 ? 190 : 150),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildQuickSearchTab(),
                _buildMoviesTab(),
                _buildTvShowsTab(),
              ],
            ),
          ),

          // Fixed header on top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF141414),
                    const Color(0xFF141414).withOpacity(0.95),
                    const Color(0xFF141414).withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE50914), Color(0xFFB20710)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE50914).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.search, size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Tìm Kiếm',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Search bar (only for Quick Search tab)
                      if (_tabController.index == 0)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isSearchFocused
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFE50914).withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.15),
                                      Colors.white.withOpacity(0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isSearchFocused
                                        ? const Color(0xFFE50914)
                                        : Colors.white.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onTap: () => setState(() => _isSearchFocused = true),
                                  onTapOutside: (_) =>
                                      setState(() => _isSearchFocused = false),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Tìm kiếm phim...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: _isSearchFocused
                                          ? const Color(0xFFE50914)
                                          : Colors.white.withOpacity(0.6),
                                      size: 20,
                                    ),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.clear,
                                              color: Colors.white.withOpacity(0.6),
                                              size: 18,
                                            ),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {});
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  onChanged: (query) {
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Tab bar
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE50914), Color(0xFFB20710)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE50914).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white.withOpacity(0.6),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 13,
                          ),
                          dividerColor: Colors.transparent,
                          padding: const EdgeInsets.all(3),
                          labelPadding: EdgeInsets.zero,
                          onTap: (index) {
                            setState(() {});
                          },
                          tabs: const [
                            Tab(text: 'Tất Cả'),
                            Tab(text: 'Phim'),
                            Tab(text: 'TV Show'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSearchTab() {
    if (_searchController.text.trim().isEmpty) {
      return _buildTrendingSection();
    }

    return Consumer(
      builder: (context, ref, child) {
        final searchRequest = SearchRequest(query: _searchController.text.trim());
        final searchResults = ref.watch(searchMoviesProvider(searchRequest));

        return searchResults.when(
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE50914).withOpacity(0.2),
                        const Color(0xFFB20710).withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: const CircularProgressIndicator(
                    color: Color(0xFFE50914),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Đang tìm kiếm...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Lỗi tìm kiếm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    error.toString(),
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          data: (searchResponse) {
            if (searchResponse.results.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.movie_outlined,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Không tìm thấy kết quả',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thử tìm kiếm với từ khóa khác',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }

            return _buildSearchResults(searchResponse.results);
          },
        );
      },
    );
  }

  Widget _buildMoviesTab() {
    if (_searchController.text.trim().isEmpty) {
      return _buildEmptyState('Nhập từ khóa để tìm kiếm phim');
    }

    return Consumer(
      builder: (context, ref, child) {
        final searchRequest = SearchRequest(query: _searchController.text.trim());
        final searchResults = ref.watch(searchMoviesProvider(searchRequest));

        return searchResults.when(
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error.toString()),
          data: (searchResponse) {
            // Filter only movies
            final movieResults = searchResponse.results.where((m) => m.mediaType != 'tv').toList();
            
            if (movieResults.isEmpty) {
              return _buildEmptyState('Không tìm thấy phim nào');
            }

            return _buildFilteredResults(movieResults, 'Phim');
          },
        );
      },
    );
  }

  Widget _buildTvShowsTab() {
    if (_searchController.text.trim().isEmpty) {
      return _buildEmptyState('Nhập từ khóa để tìm kiếm chương trình TV');
    }

    return Consumer(
      builder: (context, ref, child) {
        final searchRequest = SearchRequest(query: _searchController.text.trim());
        final searchResults = ref.watch(searchMoviesProvider(searchRequest));

        return searchResults.when(
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error.toString()),
          data: (searchResponse) {
            // Filter only TV shows
            final tvResults = searchResponse.results.where((m) => m.mediaType == 'tv').toList();
            
            if (tvResults.isEmpty) {
              return _buildEmptyState('Không tìm thấy chương trình TV nào');
            }

            return _buildFilteredResults(tvResults, 'Chương trình TV');
          },
        );
      },
    );
  }

  Widget _buildTrendingSection() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE50914), Color(0xFFB20710)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xu Hướng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Phim được yêu thích nhất',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Consumer(
          builder: (context, ref, child) {
            final trendingMoviesAsync = ref.watch(popularMoviesProvider(1));

            return trendingMoviesAsync.when(
              loading: () => SliverToBoxAdapter(
                child: Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(
                    color: Color(0xFFE50914),
                    strokeWidth: 2,
                  ),
                ),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Lỗi: $error',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
              data: (movieResponse) => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 5 : 4,
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final movie = movieResponse.results[index];
                      return _buildTrendingMovieCard(movie);
                    },
                    childCount: movieResponse.results.length,
                  ),
                ),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildTrendingMovieCard(Movie movie) {
    return GestureDetector(
      onTap: () {
        // Navigate based on mediaType
        if (movie.mediaType == 'tv') {
          context.go('/tv/${movie.id}');
        } else {
          context.go('/movie/${movie.id}');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Poster image
              if (movie.posterPath.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    movie.fullPosterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[850],
                      child: const Icon(Icons.movie, color: Colors.grey, size: 24),
                    ),
                  ),
                )
              else
                Container(
                  color: Colors.grey[850],
                  child: const Center(
                    child: Icon(Icons.movie, color: Colors.grey, size: 24),
                  ),
                ),

              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
              ),

              // Rating badge
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE50914), Color(0xFFB20710)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 8),
                      const SizedBox(width: 2),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Movie title
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Text(
                  movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<Movie> movies) {
    // Separate movies and TV shows
    final movieResults = movies.where((m) => m.mediaType != 'tv').toList();
    final tvShowResults = movies.where((m) => m.mediaType == 'tv').toList();
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Movies Section
        if (movieResults.isNotEmpty) ...[
          _buildSectionHeader('Phim', movieResults.length),
          ...movieResults.map((movie) => _buildSearchResultCard(movie, 'movie')),
          const SizedBox(height: 20),
        ],
        
        // TV Shows Section
        if (tvShowResults.isNotEmpty) ...[
          _buildSectionHeader('Chương trình TV', tvShowResults.length),
          ...tvShowResults.map((movie) => _buildSearchResultCard(movie, 'tv')),
        ],
      ],
    );
  }

  Widget _buildFilteredResults(List<Movie> movies, String title) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildSectionHeader(title, movies.length),
        ...movies.map((movie) => _buildSearchResultCard(movie, movie.mediaType ?? 'movie')),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE50914).withOpacity(0.2),
                  const Color(0xFFB20710).withOpacity(0.1),
                ],
              ),
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFFE50914),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Đang tìm kiếm...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Lỗi tìm kiếm',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
            child: Icon(
              Icons.movie_outlined,
              color: Colors.grey[400],
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE50914), Color(0xFFB20710)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count kết quả)',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(Movie movie, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          // Navigate based on mediaType, with fallback
          final mediaType = movie.mediaType ?? 'movie';
          
          if (mediaType == 'tv') {
            context.go('/tv/${movie.id}');
          } else {
            context.go('/movie/${movie.id}');
          }
        },
            borderRadius: BorderRadius.circular(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Poster - Smaller size
                      Container(
                        width: 55,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: movie.posterPath.isNotEmpty
                              ? Image.network(
                                  movie.fullPosterUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey[850],
                                    child: const Icon(Icons.movie,
                                        color: Colors.grey, size: 24),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[850],
                                  child: const Icon(Icons.movie,
                                      color: Colors.grey, size: 24),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    movie.releaseDate.year.toString(),
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFE50914),
                                        Color(0xFFB20710)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star,
                                          color: Colors.white, size: 10),
                                      const SizedBox(width: 2),
                                      Text(
                                        movie.voteAverage.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Auto-translatable overview
                            _TranslatableOverview(
                              movie: movie,
                              translationService: _translationService,
                            ),
                          ],
                        ),
                      ),

                      // Arrow icon
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.4),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
  }
}

// =========================
//   TRANSLATABLE OVERVIEW WIDGET
// =========================
class _TranslatableOverview extends StatefulWidget {
  final Movie movie;
  final TranslationService translationService;

  const _TranslatableOverview({
    required this.movie,
    required this.translationService,
  });

  @override
  State<_TranslatableOverview> createState() => _TranslatableOverviewState();
}

class _TranslatableOverviewState extends State<_TranslatableOverview> {
  String? _translatedOverview;
  bool _isTranslating = false;
  bool _hasTriedTranslation = false;

  @override
  void initState() {
    super.initState();
    _autoTranslateIfNeeded();
  }

  Future<void> _autoTranslateIfNeeded() async {
    // Only auto-translate if we don't have Vietnamese overview and have English overview
    if (widget.movie.overview_vi?.isNotEmpty == true) {
      return; // Already have Vietnamese
    }
    
    if (widget.movie.overview.isEmpty) {
      return; // No overview to translate
    }
    
    if (_hasTriedTranslation) {
      return; // Already tried
    }

    setState(() {
      _isTranslating = true;
      _hasTriedTranslation = true;
    });

    try {
      final translated = await widget.translationService.translateToVietnamese(widget.movie.overview);
      if (mounted && translated.isNotEmpty && translated != widget.movie.overview) {
        setState(() {
          _translatedOverview = translated;
          _isTranslating = false;
        });
      } else {
        setState(() {
          _isTranslating = false;
        });
      }
    } catch (e) {
      print('❌ Auto-translation failed for "${widget.movie.title}": $e');
      setState(() {
        _isTranslating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Priority: Vietnamese original > Translated > English original > "No description"
    String displayText;
    
    if (widget.movie.overview_vi?.isNotEmpty == true) {
      displayText = widget.movie.overview_vi!;
    } else if (_translatedOverview?.isNotEmpty == true) {
      displayText = _translatedOverview!;
    } else if (widget.movie.overview.isNotEmpty) {
      displayText = widget.movie.overview;
    } else {
      displayText = 'Không có mô tả';
    }

    // Debug log to help troubleshoot
    print('🔍 _TranslatableOverview for "${widget.movie.title}":');
    print('  - overview_vi: "${widget.movie.overview_vi}"');
    print('  - _translatedOverview: "$_translatedOverview"');
    print('  - overview: "${widget.movie.overview}"');
    print('  - displayText: "$displayText"');
    print('  - _isTranslating: $_isTranslating');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            displayText,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 11,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_isTranslating) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey[400],
            ),
          ),
        ],
      ],
    );
  }
}
