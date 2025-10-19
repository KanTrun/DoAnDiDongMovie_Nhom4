import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/backend_models.dart';
import '../../core/models/movie.dart';
import '../../core/providers/tmdb_provider.dart';
import '../../core/providers/backend_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/translation_service.dart';
import '../../core/widgets/translatable_overview_card.dart';
import '../movie_detail/movie_detail_screen.dart';
import '../movie_detail/tv_show_detail_screen.dart';

class FavoritesTab extends ConsumerStatefulWidget {
  const FavoritesTab({super.key});

  @override
  ConsumerState<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends ConsumerState<FavoritesTab> {
  final TranslationService _translationService = TranslationService();

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (!isAuthenticated) {
      return _buildNotLoggedIn(context);
    }

    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Netflix-style App Bar with back button
          SliverAppBar(
            backgroundColor: const Color(0xFF141414),
            elevation: 0,
            floating: true,
            snap: true,
            pinned: true,
            leading: Navigator.canPop(context)
                ? Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  )
                : null,
            title: Row(
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
                  child:
                      const Icon(Icons.favorite, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Yêu Thích',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon:
                      const Icon(Icons.refresh, color: Colors.white, size: 20),
                  onPressed: () {
                    ref.read(favoritesProvider.notifier).loadFavorites();
                  },
                  tooltip: 'Làm mới',
                ),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: favoritesAsync.when(
              loading: () => Container(
                height: 400,
                child: Center(
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
                      const SizedBox(height: 16),
                      const Text(
                        'Đang tải...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              error: (error, stack) => Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Lỗi tải danh sách',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$error',
                      style: TextStyle(color: Colors.grey[400]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(favoritesProvider.notifier).loadFavorites();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE50914),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (favorites) {
                if (favorites.isEmpty) {
                  return _buildEmptyState(context);
                }
                return _buildFavoritesList(favorites, ref);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for handling both MovieDetail and TvShowDetail
  String _getMediaTitle(dynamic mediaDetail, String mediaType) {
    if (mediaDetail == null) return 'Unknown';
    if (mediaType == 'tv') {
      return (mediaDetail as TvShowDetail).name ?? 'Unknown Title';
    } else {
      return (mediaDetail as MovieDetail).title ?? 'Unknown Title';
    }
  }

  String _getMediaYear(dynamic mediaDetail, String mediaType) {
    if (mediaDetail == null) return 'N/A';
    if (mediaType == 'tv') {
      final tvShow = mediaDetail as TvShowDetail;
      return tvShow.firstAirDate.isNotEmpty
          ? DateTime.parse(tvShow.firstAirDate).year.toString()
          : 'N/A';
    } else {
      final movie = mediaDetail as MovieDetail;
      return movie.releaseDate.year.toString();
    }
  }

  String _getMediaRating(dynamic mediaDetail, String mediaType) {
    if (mediaDetail == null) return '0.0';
    if (mediaType == 'tv') {
      final tvShow = mediaDetail as TvShowDetail;
      return tvShow.voteAverage.toStringAsFixed(1);
    } else {
      final movie = mediaDetail as MovieDetail;
      return movie.voteAverage.toStringAsFixed(1);
    }
  }

  String _getMediaOverview(dynamic mediaDetail, String mediaType) {
    if (mediaDetail == null) return '';
    if (mediaType == 'tv') {
      final tvShow = mediaDetail as TvShowDetail;
      return tvShow.overview ?? '';
    } else {
      final movie = mediaDetail as MovieDetail;
      return movie.overview ?? '';
    }
  }

  String? _getMediaOverviewVi(dynamic mediaDetail, String mediaType) {
    if (mediaDetail == null) return null;
    if (mediaType == 'tv') {
      return null; // TvShowDetail doesn't have overview_vi field yet
    } else {
      final movie = mediaDetail as MovieDetail;
      return movie.overview_vi;
    }
  }

  String _getMediaPosterPath(dynamic mediaDetail, String mediaType) {
    if (mediaDetail == null) return '';
    if (mediaType == 'tv') {
      final tvShow = mediaDetail as TvShowDetail;
      return tvShow.posterPath ?? '';
    } else {
      final movie = mediaDetail as MovieDetail;
      return movie.posterPath ?? '';
    }
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        leading: Navigator.canPop(context)
            ? Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE50914).withOpacity(0.2),
                      const Color(0xFFB20710).withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFE50914).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.favorite_outline,
                  size: 64,
                  color: const Color(0xFFE50914).withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Đăng nhập để xem',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Lưu phim yêu thích để xem bất cứ lúc nào',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.favorite_outline,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Chưa có phim yêu thích',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Thêm phim vào danh sách để dễ tìm lại',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(List<Favorite> favorites, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                const Icon(
                  Icons.bookmark,
                  color: Color(0xFFE50914),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${favorites.length} phim',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final favorite = favorites[index];
            return _buildFavoriteCard(favorite);
          },
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildFavoriteCard(Favorite favorite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Consumer(
        builder: (context, ref, child) {
          // Use appropriate provider based on media type
          final mediaDetailsAsync = (favorite.mediaType ?? 'movie') == 'tv'
              ? ref.watch(tvShowDetailProvider(favorite.tmdbId))
              : ref.watch(movieDetailsProvider(favorite.tmdbId));

          return mediaDetailsAsync.when(
            loading: () => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 110,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE50914),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ),
            error: (error, stack) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Lỗi tải thông tin',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (mediaDetail) => InkWell(
              onTap: () {
                if ((favorite.mediaType ?? 'movie') == 'tv') {
                  context.push('/tv/${favorite.tmdbId}');
                } else {
                  context.push('/movie/${favorite.tmdbId}');
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Movie poster
                        Container(
                          width: 60,
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _getMediaPosterPath(mediaDetail, favorite.mediaType ?? 'movie').isNotEmpty
                                ? Image.network(
                                    'https://image.tmdb.org/t/p/w500${_getMediaPosterPath(mediaDetail, favorite.mediaType ?? 'movie')}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      color: Colors.grey[850],
                                      child: const Icon(
                                        Icons.movie,
                                        color: Colors.grey,
                                        size: 24,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[850],
                                    child: const Icon(
                                      Icons.movie,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Media info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getMediaTitle(mediaDetail, favorite.mediaType ?? 'movie'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
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
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getMediaYear(mediaDetail, favorite.mediaType ?? 'movie'),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
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
                                          _getMediaRating(mediaDetail, favorite.mediaType ?? 'movie'),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (_getMediaOverview(mediaDetail, favorite.mediaType ?? 'movie').isNotEmpty)
                                TranslatableOverviewCard(
                                  overview: _getMediaOverview(mediaDetail, favorite.mediaType ?? 'movie'),
                                  overviewVi: _getMediaOverviewVi(mediaDetail, favorite.mediaType ?? 'movie'),
                                  translationService: _translationService,
                                ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${favorite.addedAt.day}/${favorite.addedAt.month}/${favorite.addedAt.year}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Remove button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                              ref
                                  .read(favoritesProvider.notifier)
                                  .removeFavorite(favorite.tmdbId, mediaType: favorite.mediaType ?? 'movie');
                            },
                            icon: const Icon(
                              Icons.favorite,
                              color: Color(0xFFE50914),
                              size: 20,
                            ),
                            tooltip: 'Bỏ yêu thích',
                          ),
                        ),
                      ],
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
}
