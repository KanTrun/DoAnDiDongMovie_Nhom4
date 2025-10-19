import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/services/translation_service.dart';
import '../../core/widgets/subtitle_overlay.dart';
import '../../core/providers/tmdb_provider.dart';
import '../../core/providers/backend_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/movie.dart';
import '../person/person_detail_screen.dart';
import 'widgets/notes_section.dart';
import 'widgets/rating_section.dart';

class TvShowDetailScreen extends ConsumerStatefulWidget {
  final int tvShowId;

  const TvShowDetailScreen({
    Key? key,
    required this.tvShowId,
  }) : super(key: key);

  @override
  ConsumerState<TvShowDetailScreen> createState() => _TvShowDetailScreenState();
}

class _TvShowDetailScreenState extends ConsumerState<TvShowDetailScreen>
    with TickerProviderStateMixin {
  bool _isOverviewExpanded = false;
  bool _isOverviewTranslated = false;
  String _originalOverview = '';
  String _translatedOverview = '';

  // ScrollControllers
  final ScrollController _videoScrollController = ScrollController();
  final ScrollController _castScrollController = ScrollController();
  final ScrollController _crewScrollController = ScrollController();
  final ScrollController _similarTvShowsScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();

  // Animation Controllers
  late AnimationController _heroAnimationController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _heroAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _mainScrollController.addListener(() {
      setState(() {
        _scrollOffset = _mainScrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    _videoScrollController.dispose();
    _castScrollController.dispose();
    _crewScrollController.dispose();
    _similarTvShowsScrollController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  // =========================
  //    OVERVIEW TRANSLATION
  // =========================
  Future<void> _toggleOverviewTranslation() async {
    if (_isOverviewTranslated) {
      // Switch back to original
      setState(() {
        _isOverviewTranslated = false;
      });
    } else {
      // Translate to Vietnamese
      setState(() {
        _isOverviewTranslated = true;
      });
      
      // If we haven't translated yet, do it now
      if (_translatedOverview == _originalOverview) {
        try {
          final translationService = TranslationService();
          final translated = await translationService.translateToVietnamese(_originalOverview);
          setState(() {
            _translatedOverview = translated.isNotEmpty ? translated : _originalOverview;
          });
        } catch (e) {
          print('❌ Translation failed: $e');
          setState(() {
            _translatedOverview = _originalOverview;
            _isOverviewTranslated = false;
          });
        }
      }
    }
  }

  // =========================
  //          BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    final tvShowDetailsAsync = ref.watch(tvShowDetailProvider(widget.tvShowId));
    final tvShowVideosAsync = ref.watch(tvShowVideosProvider(widget.tvShowId));
    final tvShowCreditsAsync = ref.watch(tvShowCreditsProvider(widget.tvShowId));
    final similarTvShowsAsync =
        ref.watch(similarTvShowsProvider(widget.tvShowId));
    final authAsync = ref.watch(authProvider);
    final isAuthenticated = authAsync.isAuthenticated;
    
    print('🔍 AUTH DEBUG - isAuthenticated: $isAuthenticated');
    print('🔍 AUTH DEBUG - user: ${authAsync.user?.email}');
    print('🔍 AUTH DEBUG - token: ${authAsync.token != null ? "Present" : "NULL"}');

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: _scrollOffset > 100
            ? const Color(0xFF141414).withOpacity(0.95)
            : Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: AnimatedOpacity(
          opacity: _scrollOffset > 200 ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: const Text(
            'MoviePlus',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      body: tvShowDetailsAsync.when(
        data: (tvShow) {
          print('🔍 DEBUG: TV Show overview in UI: "${tvShow.overview}"');
          final bottomSafe = MediaQuery.of(context).padding.bottom;
          return SingleChildScrollView(
            controller: _mainScrollController,
            padding: EdgeInsets.only(bottom: bottomSafe + 72),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(tvShow),
                _buildActionButtons(tvShow, isAuthenticated),
                _buildOverview(tvShow.overview),
                _buildTvShowInfo(tvShow),
                // Temporarily show notes/ratings even when not authenticated for debugging
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: NotesSection(
                    tmdbId: widget.tvShowId,
                    mediaType: 'tv',
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: RatingSection(
                    tmdbId: widget.tvShowId,
                    mediaType: 'tv',
                  ),
                ),
                _buildVideoSection(tvShowVideosAsync),
                _buildCastSectionFromCredits(tvShowCreditsAsync),
                _buildCrewSectionFromCredits(tvShowCreditsAsync),
                _buildSimilarTvShows(similarTvShowsAsync),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
        loading: () => const Center(
      child: CircularProgressIndicator(
            color: Color(0xFFE50914),
            strokeWidth: 3,
          ),
        ),
        error: (error, stack) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
              const Icon(Icons.error_outline, color: Color(0xFFE50914), size: 64),
          const SizedBox(height: 16),
          Text(
                'Lỗi tải dữ liệu chương trình',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          ),
        ],
          ),
        ),
      ),
    );
  }


  // =========================
  //    HERO SECTION WITH PARALLAX
  // =========================
  Widget _buildHeroSection(TvShowDetail tvShow) {
    final parallaxOffset = _scrollOffset * 0.5;
    final opacity = (1 - (_scrollOffset / 400)).clamp(0.0, 1.0);

    return SizedBox(
      height: 600,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Animated Background với Parallax
          Transform.translate(
            offset: Offset(0, parallaxOffset),
            child: AnimatedBuilder(
              animation: _heroAnimationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _heroAnimationController.value,
                  child: child,
                );
              },
              child: Stack(
          fit: StackFit.expand,
          children: [
            if (tvShow.backdropPath.isNotEmpty)
              Image.network(
                      'https://image.tmdb.org/t/p/original${tvShow.backdropPath}',
                fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF141414), Color(0xFF000000)],
                          ),
                        ),
                        child: const Icon(Icons.tv, color: Colors.grey, size: 100),
                      ),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF141414), Color(0xFF000000)],
                        ),
                      ),
                      child: const Icon(Icons.tv, color: Colors.grey, size: 100),
                    ),
                ],
              ),
            ),
          ),

          // Gradient Overlays - Netflix Style (Stronger bottom gradient)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                  const Color(0xFF141414).withOpacity(0.95),
                  const Color(0xFF141414),
                  ],
                stops: const [0.0, 0.3, 0.5, 0.7, 0.9, 1.0],
                ),
              ),
            ),
            
          // Vignette Effect
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),

          // Content với Fade Animation
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
            child: Opacity(
              opacity: opacity,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title với Animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: Text(
                      tvShow.name,
                      style: const TextStyle(
                        color: Colors.white,
                          fontSize: 36,
                        fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          height: 1.1,
                        shadows: [
                          Shadow(
                              offset: Offset(0, 4),
                              blurRadius: 12,
                              color: Colors.black87,
                          ),
                        ],
                      ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                    ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Tagline với delay animation
                    if (tvShow.tagline.isNotEmpty)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 15 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: Text(
                        tvShow.tagline,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 15,
                          fontStyle: FontStyle.italic,
                            letterSpacing: 0.3,
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 6,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    // Info Row với Animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(opacity: value, child: child);
                      },
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                          // Rating Badge
                          if (tvShow.voteAverage > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE50914), Color(0xFFB20710)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE50914).withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                        Text(
                          tvShow.voteAverage.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                                      fontSize: 14,
                            fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                          ),
                        ),
                                ],
                              ),
                            ),
                        if (tvShow.firstAirDate.isNotEmpty)
                          Text(
                              '${_formatDate(tvShow.firstAirDate).split('/').last}',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          if (tvShow.numberOfSeasons > 0) ...[
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[500],
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              '${tvShow.numberOfSeasons} mùa',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Genres với Glass Effect
                    if (tvShow.genres.isNotEmpty)
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: tvShow.genres.take(5).length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final genre = tvShow.genres[index];
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 1200 + (index * 100)),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Opacity(opacity: value, child: child),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Text(
                            genre,
                            style: const TextStyle(
                              color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                            ),
                          ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                ),
              ),
            ),
          ],
      ),
    );
  }

  // =========================
  //    ACTION BUTTONS - Netflix Style
  // =========================
  Widget _buildActionButtons(TvShowDetail tvShow, bool isAuthenticated) {
    return Container(
      color: const Color(0xFF141414), // Solid background
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          if (isAuthenticated) ...[
            Consumer(
              builder: (context, ref, child) {
                final favoritesAsync = ref.watch(favoritesProvider);
                final isFavorite = favoritesAsync.when(
                  data: (favorites) => favorites.any((fav) => fav.tmdbId == widget.tvShowId && (fav.mediaType ?? 'movie') == 'tv'),
                  loading: () => false,
                  error: (_, __) => false,
                );

                return Expanded(
                  child: _AnimatedButton(
                    onPressed: () {
                      if (isFavorite) {
                        ref.read(favoritesProvider.notifier).removeFavorite(widget.tvShowId, mediaType: 'tv');
                      } else {
                        ref.read(favoritesProvider.notifier).addFavorite(widget.tvShowId, mediaType: 'tv');
                      }
                    },
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                    label: isFavorite ? 'Đã thích' : 'Thích',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE50914), Color(0xFFB20710)],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Consumer(
              builder: (context, ref, child) {
                final watchlistAsync = ref.watch(watchlistProvider);
                final isInWatchlist = watchlistAsync.when(
                  data: (watchlist) => watchlist.any((item) => item.tmdbId == widget.tvShowId && (item.mediaType ?? 'movie') == 'tv'),
                  loading: () => false,
                  error: (_, __) => false,
                );

                return Expanded(
                  child: _AnimatedButton(
                    onPressed: () {
                      if (isInWatchlist) {
                        ref.read(watchlistProvider.notifier).removeFromWatchlist(widget.tvShowId, mediaType: 'tv');
                      } else {
                        ref.read(watchlistProvider.notifier).addToWatchlist(widget.tvShowId, mediaType: 'tv');
                      }
                    },
                    icon: isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                    label: isInWatchlist ? 'Đã lưu' : 'Lưu',
                    gradient: LinearGradient(
                      colors: [Colors.grey[800]!, Colors.grey[850]!],
                    ),
                  ),
                );
              },
            ),
          ] else ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Center(
                  child: Text(
                    'Đăng nhập để thêm vào danh sách',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTvShowInfo(TvShowDetail tvShow) {
    return Container(
        color: const Color(0xFF141414),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chi tiết chương trình',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Trạng thái', tvShow.status),
            _buildInfoRow('Ngôn ngữ gốc', tvShow.originalLanguage),
            _buildInfoRow('Số mùa', tvShow.numberOfSeasons.toString()),
            _buildInfoRow('Số tập', tvShow.numberOfEpisodes.toString()),
            if (tvShow.networks.isNotEmpty)
              _buildInfoRow('Kênh phát sóng', tvShow.networks.join(', ')),
            if (tvShow.productionCountries.isNotEmpty)
              _buildInfoRow('Quốc gia sản xuất', tvShow.productionCountries.join(', ')),
          ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  //         OVERVIEW
  // =========================
  Widget _buildOverview(String overview) {
    print('🔍 DEBUG: _buildOverview called with: "$overview"');
    if (overview.isEmpty) return const SizedBox.shrink();
    
    // Store original overview on first load
    if (_originalOverview.isEmpty) {
      _originalOverview = overview;
      _translatedOverview = overview; // Default to original
    }
    
    final displayOverview = _isOverviewTranslated ? _translatedOverview : _originalOverview;
    
    return Container(
      color: const Color(0xFF141414), // Solid background
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
          children: [
            const Text(
              'Tóm tắt',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _toggleOverviewTranslation(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isOverviewTranslated 
                        ? const Color(0xFFE50914).withOpacity(0.2)
                        : Colors.grey[800]!.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isOverviewTranslated 
                          ? const Color(0xFFE50914)
                          : Colors.grey[600]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.translate,
                        color: _isOverviewTranslated 
                            ? const Color(0xFFE50914)
                            : Colors.grey[400],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isOverviewTranslated ? 'Tiếng Việt' : 'Dịch',
                        style: TextStyle(
                          color: _isOverviewTranslated 
                              ? const Color(0xFFE50914)
                              : Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
            AnimatedCrossFade(
              firstChild: Text(
              displayOverview,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 15,
                height: 1.6,
                letterSpacing: 0.2,
              ),
              maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(
              displayOverview,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 15,
                height: 1.6,
                letterSpacing: 0.2,
                ),
              ),
              crossFadeState: _isOverviewExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          if (displayOverview.length > 150)
              GestureDetector(
                onTap: () => setState(() => _isOverviewExpanded = !_isOverviewExpanded),
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isOverviewExpanded ? 'Thu gọn' : 'Đọc thêm',
                        style: const TextStyle(
                          color: Color(0xFFE50914),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isOverviewExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: const Color(0xFFE50914),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
          ],
      ),
    );
  }

  // =========================
  //     TRAILER & VIDEO
  // =========================
  Widget _buildVideoSection(AsyncValue<List<Video>> tvShowVideosAsync) {
    return tvShowVideosAsync.when(
            data: (videos) {
        if (videos.isEmpty) return const SizedBox.shrink();
              
              return Container(
          color: const Color(0xFF141414), // Solid background
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: Text(
                  'Trailer & Video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                        ),
                      ),
                    ),
              const SizedBox(height: 8),
                    SizedBox(
                height: 280,
                child: Scrollbar(
                  controller: _videoScrollController,
                  thumbVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(10),
                      child: ListView.builder(
                        controller: _videoScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          final video = videos[index];
                      return _VideoCard(
                        videoId: video.key,
                        videoName: video.name.isNotEmpty ? video.name : 'Trailer',
                        videoType: video.type.isNotEmpty ? video.type : 'Video',
                        videoSize: video.size,
                        index: index,
                        onTap: () => _openTrailerDialog(video.key, video.name),
                      );
                    },
                  ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
    );
  }

  // =========================
  //          CAST
  // =========================
  Widget _buildCastSectionFromCredits(AsyncValue<Credits> creditsAsync) {
    return creditsAsync.when(
            data: (credits) {
              final castList = credits.cast;
        if (castList.isEmpty) return const SizedBox.shrink();
              
              return Container(
          color: const Color(0xFF141414), // Solid background
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: Text(
                        'Diễn viên',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                child: Scrollbar(
                  controller: _castScrollController,
                  thumbVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(10),
                      child: ListView.builder(
                        controller: _castScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                        itemCount: castList.length,
                        itemBuilder: (context, index) {
                          final actor = castList[index];
                          return _CastCard(actor: actor, index: index);
                        },
                  ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          );
  }

  // =========================
  //          CREW
  // =========================
  Widget _buildCrewSectionFromCredits(AsyncValue<Credits> creditsAsync) {
    return creditsAsync.when(
      data: (credits) {
        final crewList = credits.crew;
        if (crewList.isEmpty) return const SizedBox.shrink();

        // Filter important crew members
        final importantCrew = crewList.where((crew) {
          final job = crew.job.toLowerCase();
          return job == 'director' || 
                 job == 'writer' || 
                 job == 'screenplay' || 
                 job == 'producer' || 
                 job == 'executive producer' ||
                 job == 'music' ||
                 job == 'composer' ||
                 job == 'cinematography' ||
                 job == 'editor';
        }).take(10).toList();

        if (importantCrew.isEmpty) return const SizedBox.shrink();

        return Container(
          color: const Color(0xFF141414), // Solid background
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  'Đội ngũ sản xuất',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100, // Increased height to prevent overflow
                child: Scrollbar(
                  controller: _crewScrollController,
                  thumbVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(10),
                  child: ListView.builder(
                    controller: _crewScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: importantCrew.length,
                    itemBuilder: (context, index) {
                      final crew = importantCrew[index];
                      return _CrewCard(crew: crew, index: index);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // =========================
  //       SIMILAR TV SHOWS
  // =========================
  Widget _buildSimilarTvShows(AsyncValue<List<TvShow>> similarTvShowsAsync) {
    return similarTvShowsAsync.when(
            data: (tvShows) {
        if (tvShows.isEmpty) return const SizedBox.shrink();
              
              return Container(
          color: const Color(0xFF141414), // Solid background
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: Text(
                        'Chương trình tương tự',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                height: 320,
                child: Scrollbar(
                  controller: _similarTvShowsScrollController,
                  thumbVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(10),
                      child: ListView.builder(
                        controller: _similarTvShowsScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                        itemCount: tvShows.length,
                        itemBuilder: (context, index) {
                          final tvShow = tvShows[index];
                      return _TvShowCard(tvShow: tvShow, index: index);
                        },
                  ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // =========================
  //     POPUP TRAILER
  // =========================
  Future<void> _openTrailerDialog(String videoId, String title) async {
    final controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        enableCaption: true,
        playsInline: true,
        enableJavaScript: true,
      ),
    );

    await showGeneralDialog(
      context: context,
      barrierLabel: 'Trailer',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOut),
            ),
            child: _VideoPlayerWithTranslation(
              controller: controller,
              title: title,
            ),
          ),
        );
      },
    );

    controller.close();
  }
}

// =========================
//    ANIMATED BUTTON
// =========================
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Gradient gradient;

  const _AnimatedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.gradient,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================
//       CREW CARD
// =========================
class _CrewCard extends StatefulWidget {
  final Crew crew;
  final int index;

  const _CrewCard({required this.crew, required this.index});

  @override
  State<_CrewCard> createState() => _CrewCardState();
}

class _CrewCardState extends State<_CrewCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
      onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PersonDetailScreen(personId: widget.crew.id),
            ),
          );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
            width: 100,
            margin: const EdgeInsets.only(right: 16),
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                        Container(
                  width: 50,
                  height: 50,
                          decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[900],
                    boxShadow: [
                      BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  child: widget.crew.profilePath.isNotEmpty
                      ? ClipOval(
                            child: Image.network(
                            'https://image.tmdb.org/t/p/w500${widget.crew.profilePath}',
                              fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _noPhoto(),
                          ),
                        )
                      : _noPhoto(),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    widget.crew.name,
                          style: const TextStyle(
                            color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                          ),
                    maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.crew.job.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Flexible(
                    child: Text(
                      _translateJob(widget.crew.job),
                      style: TextStyle(color: Colors.grey[500], fontSize: 8),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _noPhoto() => Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[900],
        ),
        child: const Icon(Icons.person, color: Colors.grey, size: 20),
      );

  String _translateJob(String job) {
    switch (job.toLowerCase()) {
      case 'director':
        return 'Đạo diễn';
      case 'writer':
        return 'Biên kịch';
      case 'screenplay':
        return 'Kịch bản';
      case 'producer':
        return 'Nhà sản xuất';
      case 'executive producer':
        return 'Giám đốc sản xuất';
      case 'music':
        return 'Âm nhạc';
      case 'composer':
        return 'Nhạc sĩ';
      case 'cinematography':
        return 'Quay phim';
      case 'editor':
        return 'Biên tập';
      case 'costume design':
        return 'Thiết kế trang phục';
      case 'art direction':
        return 'Đạo diễn nghệ thuật';
      case 'sound':
        return 'Âm thanh';
      case 'visual effects':
        return 'Hiệu ứng hình ảnh';
      default:
        return job;
    }
  }
}

// =========================
//       CAST CARD
// =========================
class _CastCard extends StatefulWidget {
  final Cast actor;
  final int index;

  const _CastCard({required this.actor, required this.index});

  @override
  State<_CastCard> createState() => _CastCardState();
}

class _CastCardState extends State<_CastCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PersonDetailScreen(personId: widget.actor.id),
            ),
          );
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            margin: const EdgeInsets.only(right: 16),
            transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[900],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                    child: widget.actor.profilePath.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            'https://image.tmdb.org/t/p/w500${widget.actor.profilePath}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _noPhoto(),
                          ),
                        )
                      : _noPhoto(),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.actor.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (widget.actor.character.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.actor.character,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _noPhoto() => Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[900],
        ),
        child: const Icon(Icons.person, color: Colors.grey, size: 40),
      );
}

// =========================
//       TV SHOW CARD
// =========================
class _TvShowCard extends StatefulWidget {
  final TvShow tvShow;
  final int index;

  const _TvShowCard({required this.tvShow, required this.index});

  @override
  State<_TvShowCard> createState() => _TvShowCardState();
}

class _TvShowCardState extends State<_TvShowCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 80)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => TvShowDetailScreen(tvShowId: widget.tvShow.id),
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
            width: 160,
          margin: const EdgeInsets.only(right: 16),
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[900],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: widget.tvShow.posterPath.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                            'https://image.tmdb.org/t/p/w500${widget.tvShow.posterPath}',
                            fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _noPoster(),
                            ),
                          )
                        : _noPoster(),
                  ),
                ),
                const SizedBox(height: 8),
                        Text(
                  widget.tvShow.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                    fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                  DateTime.parse(widget.tvShow.firstAirDate).year.toString(),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _noPoster() => Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(Icons.tv, color: Colors.grey, size: 50),
        ),
      );
}

// =========================
//       VIDEO CARD
// =========================
class _VideoCard extends StatefulWidget {
  final String videoId;
  final String videoName;
  final String videoType;
  final int videoSize;
  final int index;
  final VoidCallback onTap;

  const _VideoCard({
    required this.videoId,
    required this.videoName,
    required this.videoType,
    required this.videoSize,
    required this.index,
    required this.onTap,
  });

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 80)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 300,
            margin: const EdgeInsets.only(right: 16),
            transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildVideoThumb(widget.videoId),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(16),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                  ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE50914), Color(0xFFB20710)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.videoType,
                          style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (widget.videoSize > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${widget.videoSize}p',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                  widget.videoName,
                style: const TextStyle(
                  color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
                Text(
                  'YouTube • ${widget.videoSize}p',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoThumb(String videoId) {
    return Image.network(
      'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.network(
        'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[900],
          child: const Center(
            child: Icon(Icons.play_circle_filled, color: Color(0xFFE50914), size: 50),
          ),
        ),
      ),
    );
  }
}

// =========================
//    VIDEO PLAYER DIALOG
// =========================
class _VideoPlayerWithTranslation extends StatefulWidget {
  final YoutubePlayerController controller;
  final String title;

  const _VideoPlayerWithTranslation({
    required this.controller,
    required this.title,
  });

  @override
  State<_VideoPlayerWithTranslation> createState() => _VideoPlayerWithTranslationState();
}

class _VideoPlayerWithTranslationState extends State<_VideoPlayerWithTranslation> {
  final TranslationService _translationService = TranslationService();
  bool _isTranslationEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeTranslation();
  }

  Future<void> _initializeTranslation() async {
    await _translationService.initialize();
  }

  void _toggleTranslation() {
    setState(() {
      _isTranslationEnabled = !_isTranslationEnabled;
    });

    if (_isTranslationEnabled) {
      _startListening();
    } else {
      _stopListening();
    }
  }

  void _startListening() async {
    await _translationService.startListening();
  }

  void _stopListening() async {
    await _translationService.stopListening();
  }

  @override
  void dispose() {
    _translationService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width * 0.9 > 1052 ? 1052.0 : size.width * 0.9;
    final videoHeight = maxWidth * 9 / 16;
    final maxHeight = size.height * 0.85;
    final actualHeight = (videoHeight + 56) > maxHeight ? maxHeight : (videoHeight + 56);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: maxWidth,
          height: actualHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 30,
                spreadRadius: 8,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
                children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.9),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[800]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isTranslationEnabled ? Icons.translate : Icons.translate_outlined,
                            color: _isTranslationEnabled ? const Color(0xFFE50914) : Colors.white,
                          ),
                          onPressed: _toggleTranslation,
                          tooltip: _isTranslationEnabled ? 'Tắt dịch' : 'Bật dịch',
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Đóng',
                    ),
                  ),
                ],
                    ),
                  ),
                  Expanded(
                    child: YoutubePlayerScaffold(
                      controller: widget.controller,
                      builder: (context, player) => player,
                    ),
              ),
            ],
          ),
              if (_isTranslationEnabled)
                SubtitleOverlay(
                  isEnabled: _isTranslationEnabled,
                  onToggle: _toggleTranslation,
                  onClear: () {
                    _translationService.clearText();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}