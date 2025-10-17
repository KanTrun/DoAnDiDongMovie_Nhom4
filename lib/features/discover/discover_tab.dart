import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/movie.dart';
import '../../core/providers/tmdb_provider.dart';
import '../../core/providers/backend_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../movie_detail/movie_detail_screen.dart';

class DiscoverTab extends ConsumerStatefulWidget {
  const DiscoverTab({super.key});

  @override
  ConsumerState<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends ConsumerState<DiscoverTab> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;
  Timer? _autoRotateTimer;
  int _currentFeaturedIndex = 0;
  int _selectedCategoryIndex = 0; // Track selected category
  String? _currentGenreFilter; // Track current genre filter

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _startAutoRotate();
  }

  void _startAutoRotate() {
    _autoRotateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentFeaturedIndex = (_currentFeaturedIndex + 1) % 5;
        });
      }
    });
  }

  void _onScroll() {
    if (_scrollController.offset > 300 && !_showTitle) {
      setState(() => _showTitle = true);
    } else if (_scrollController.offset <= 300 && _showTitle) {
      setState(() => _showTitle = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _autoRotateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Debug authentication state
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final authToken = ref.watch(authTokenProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    print('DEBUG AUTH - isAuthenticated: $isAuthenticated');
    print('DEBUG AUTH - token: ${authToken?.substring(0, 20)}...');
    print('DEBUG AUTH - user: ${currentUser?.email}');
    
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Space for fixed AppBar
              const SliverToBoxAdapter(
                child: SizedBox(height: 80), // Space cho AppBar
              ),

              // Main content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Debug info
                    if (!isAuthenticated)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.red.withOpacity(0.8),
                        child: Column(
                          children: [
                            const Text(
                              'CHƯA ĐĂNG NHẬP - Hãy đăng nhập để sử dụng tính năng yêu thích',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  await ref.read(authProvider.notifier).login(
                                    'test@test.com',
                                    '123456',
                                  );
                                  
                                  // Force reload favorites and watchlist after login
                                  print('DEBUG AUTH - Login successful, reloading favorites and watchlist');
                                  ref.read(favoritesProvider.notifier).forceReload();
                                  ref.read(watchlistProvider.notifier).forceReload();
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đăng nhập thành công!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Lỗi đăng nhập: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Đăng nhập test@test.com'),
                            ),
                          ],
                        ),
                      ),
                    
                    // Featured movie section
                    _buildFeaturedSection(),

                    const SizedBox(height: 30),

                    // Category chips
                    _buildCategoryChips(),

                    const SizedBox(height: 30),

                    // Popular movies section - dynamically filtered
                    _buildMovieSection(
                      title: 'Phổ Biến',
                      provider: _currentGenreFilter == null
                          ? popularMoviesProvider(1)
                          : discoverMoviesProvider(DiscoverRequest(
                              page: 1,
                              withGenres: _currentGenreFilter,
                              sortBy: 'popularity.desc',
                            )),
                    ),

                    const SizedBox(height: 30),

                    // Trending movies section - dynamically filtered
                    _buildMovieSection(
                      title: 'Xu Hướng',
                      provider: _currentGenreFilter == null
                          ? nowPlayingMoviesProvider(1)
                          : discoverMoviesProvider(DiscoverRequest(
                              page: 1,
                              withGenres: _currentGenreFilter,
                              sortBy: 'release_date.desc',
                            )),
                    ),

                    const SizedBox(height: 30),

                    // Top rated movies section - dynamically filtered
                    _buildMovieSection(
                      title: 'Xếp Hạng Cao',
                      provider: _currentGenreFilter == null
                          ? topRatedMoviesProvider(1)
                          : discoverMoviesProvider(DiscoverRequest(
                              page: 1,
                              withGenres: _currentGenreFilter,
                              sortBy: 'vote_average.desc',
                            )),
                    ),

                    const SizedBox(height: 30),

                    // Upcoming movies section - dynamically filtered
                    _buildMovieSection(
                      title: 'Sắp Ra Mắt',
                      provider: _currentGenreFilter == null
                          ? upcomingMoviesProvider(1)
                          : discoverMoviesProvider(DiscoverRequest(
                              page: 1,
                              withGenres: _currentGenreFilter,
                              sortBy: 'release_date.asc',
                            )),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),

          // Fixed AppBar on top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _showTitle
                      ? [
                          const Color(0xFF141414),
                          const Color(0xFF141414).withOpacity(0.95),
                          const Color(0xFF141414).withOpacity(0.8),
                          Colors.transparent,
                        ]
                      : [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Logo
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE50914), Color(0xFFB20710)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.movie, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      AnimatedOpacity(
                        opacity: _showTitle ? 1.0 : 0.8,
                        duration: const Duration(milliseconds: 200),
                        child: const Text(
                          'MoviePlus',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Action buttons
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.search, color: Colors.white, size: 24),
                          onPressed: () {
                            context.go('/search');
                          },
                          tooltip: 'Tìm kiếm',
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 24),
                          onPressed: () {},
                          tooltip: 'Thông báo',
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE50914), Color(0xFFB20710)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.account_circle,
                              color: Colors.white, size: 24),
                          onPressed: () {
                            context.go('/profile');
                          },
                          tooltip: 'Tài khoản',
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

  Widget _buildCategoryChips() {
    final categories = [
      'Tất cả',
      'Hành động',
      'Phiêu lưu',
      'Hài',
      'Tâm lý',
      'Kinh dị',
      'Khoa học viễn tưởng',
    ];

    // Map categories to TMDB genre IDs
    final genreMapping = {
      'Tất cả': null,
      'Hành động': '28',      // Action
      'Phiêu lưu': '12',      // Adventure  
      'Hài': '35',            // Comedy
      'Tâm lý': '18',         // Drama
      'Kinh dị': '27',        // Horror
      'Khoa học viễn tưởng': '878', // Science Fiction
    };

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          return Container(
            margin: const EdgeInsets.only(right: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final selectedGenre = genreMapping[categories[index]];
                  setState(() {
                    _selectedCategoryIndex = index;
                    _currentGenreFilter = selectedGenre;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(selectedGenre == null 
                        ? 'Hiển thị tất cả phim' 
                        : 'Lọc phim: ${categories[index]}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFFE50914), Color(0xFFB20710)],
                          )
                        : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    categories[index],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Consumer(
      builder: (context, ref, child) {
        final popularMoviesAsync = ref.watch(popularMoviesProvider(1));

        return popularMoviesAsync.when(
          loading: () => _buildFeaturedShimmer(),
          error: (error, stack) => Container(
            height: 500,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Không thể tải phim: $error',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          data: (movieResponse) {
            if (movieResponse.results.isEmpty) {
              return const SizedBox();
            }

            final featuredMovies = movieResponse.results.take(5).toList();
            final featuredMovie = featuredMovies[
                _currentFeaturedIndex % featuredMovies.length];

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              child: Container(
                key: ValueKey(featuredMovie.id),
                height: 580,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Background image
                      if (featuredMovie.backdropPath.isNotEmpty)
                        Positioned.fill(
                          child: Image.network(
                            'https://image.tmdb.org/t/p/original${featuredMovie.backdropPath}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[900],
                                child: const Center(
                                  child: Icon(Icons.movie,
                                      size: 64, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),

                      // Gradient overlay - Professional and clear
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                                Colors.black.withOpacity(0.85),
                                Colors.black.withOpacity(0.95),
                              ],
                              stops: const [0.0, 0.2, 0.5, 0.75, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Movie info - Well positioned
                      Positioned(
                        bottom: 30,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Featured badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE50914), Color(0xFFB20710)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE50914).withOpacity(0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'NỔI BẬT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Title
                            Text(
                              featuredMovie.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                    color: Colors.black,
                                  ),
                                  Shadow(
                                    offset: Offset(0, 4),
                                    blurRadius: 16,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // Rating and year
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star,
                                          color: Colors.amber, size: 14),
                                      const SizedBox(width: 3),
                                      Text(
                                        featuredMovie.voteAverage
                                            .toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${featuredMovie.releaseDate.year}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Overview
                            if (featuredMovie.overview.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.65),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  featuredMovie.overview,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.3,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            const SizedBox(height: 12),

                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => MovieDetailScreen(
                                              movieId: featuredMovie.id),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 2,
                                    ),
                                    icon: const Icon(Icons.play_arrow, size: 24),
                                    label: const Text(
                                      'Phát',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      final watchlistNotifier =
                                          ref.read(watchlistProvider.notifier);
                                      watchlistNotifier
                                          .addToWatchlist(featuredMovie.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                              'Đã thêm vào danh sách'),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: const Color(0xFFE50914),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.white, width: 2),
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add, size: 22),
                                    label: const Text(
                                      'Danh sách',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => MovieDetailScreen(
                                              movieId: featuredMovie.id),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.info_outline,
                                        color: Colors.white),
                                    iconSize: 24,
                                    tooltip: 'Chi tiết',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Indicator dots
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            featuredMovies.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: index == _currentFeaturedIndex ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: index == _currentFeaturedIndex
                                    ? const Color(0xFFE50914)
                                    : Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeaturedShimmer() {
    return Container(
      height: 580,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[850]!,
                    Colors.grey[900]!,
                    Colors.grey[850]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFFE50914),
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieSection({
    required String title,
    required FutureProvider<MovieResponse> provider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFE50914),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: Consumer(
            builder: (context, ref, child) {
              final moviesAsync = ref.watch(provider);

              return moviesAsync.when(
                loading: () => _buildMovieShimmer(),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Lỗi: $error',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                data: (movieResponse) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: movieResponse.results.length,
                  itemBuilder: (context, index) {
                    final movie = movieResponse.results[index];
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      child: ModernMovieCard(movie: movie),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMovieShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFE50914),
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }
}

class ModernMovieCard extends ConsumerStatefulWidget {
  final Movie movie;

  const ModernMovieCard({
    super.key,
    required this.movie,
  });

  @override
  ConsumerState<ModernMovieCard> createState() => _ModernMovieCardState();
}

class _ModernMovieCardState extends ConsumerState<ModernMovieCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final favoritesState = ref.watch(favoritesProvider);
    final watchlistState = ref.watch(watchlistProvider);
    final favoritesNotifier = ref.watch(favoritesProvider.notifier);
    final watchlistNotifier = ref.watch(watchlistProvider.notifier);

    final isFavorite = isAuthenticated && favoritesState.maybeWhen(
      data: (favorites) {
        return favorites.any((f) => f.movieId == widget.movie.id);
      },
      orElse: () => false,
    );
    
    final isInWatchlist = isAuthenticated && watchlistState.maybeWhen(
      data: (watchlist) {
        return watchlist.any((w) => w.movieId == widget.movie.id);
      },
      orElse: () => false,
    );

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    MovieDetailScreen(movieId: widget.movie.id),
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE50914).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Movie poster
                  if (widget.movie.posterPath.isNotEmpty)
                    Positioned.fill(
                      child: Image.network(
                        widget.movie.fullPosterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[850],
                            child: const Center(
                              child: Icon(
                                Icons.movie,
                                color: Colors.grey,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey[850],
                      child: const Center(
                        child: Icon(
                          Icons.movie,
                          color: Colors.grey,
                          size: 48,
                        ),
                      ),
                    ),

                  // Darker gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.75),
                            Colors.black.withOpacity(0.95),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Rating badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE50914), Color(0xFFB20710)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            widget.movie.voteAverage.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action buttons
                  if (isAuthenticated)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Column(
                        children: [
                          // Favorite button
                          GestureDetector(
                            onTap: () {
                              print('DEBUG FAVORITE - Button tapped for movie ${widget.movie.id}');
                              print('DEBUG FAVORITE - Current isFavorite: $isFavorite');
                              print('DEBUG FAVORITE - User authenticated: $isAuthenticated');
                              
                              if (isFavorite) {
                                print('DEBUG FAVORITE - Removing from favorites');
                                favoritesNotifier.removeFavorite(widget.movie.id);
                              } else {
                                print('DEBUG FAVORITE - Adding to favorites');
                                favoritesNotifier.addFavorite(widget.movie.id);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isFavorite
                                      ? const Color(0xFFE50914)
                                      : Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite
                                    ? const Color(0xFFE50914)
                                    : Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Watchlist button
                          GestureDetector(
                            onTap: () {
                              print('DEBUG WATCHLIST - Button tapped for movie ${widget.movie.id}');
                              print('DEBUG WATCHLIST - Current isInWatchlist: $isInWatchlist');
                              print('DEBUG WATCHLIST - User authenticated: $isAuthenticated');
                              
                              if (isInWatchlist) {
                                print('DEBUG WATCHLIST - Removing from watchlist');
                                watchlistNotifier
                                    .removeFromWatchlist(widget.movie.id);
                              } else {
                                print('DEBUG WATCHLIST - Adding to watchlist');
                                watchlistNotifier.addToWatchlist(widget.movie.id);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isInWatchlist
                                      ? Colors.blue
                                      : Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                isInWatchlist
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: isInWatchlist ? Colors.blue : Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Movie title at bottom
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.movie.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 4,
                                color: Colors.black,
                              ),
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 8,
                                color: Colors.black,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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
