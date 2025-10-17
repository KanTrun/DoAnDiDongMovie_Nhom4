import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/providers/tmdb_provider.dart';
import '../../core/models/movie.dart';
import '../person/person_detail_screen.dart';

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

  // ScrollControllers
  final ScrollController _videoScrollController = ScrollController();
  final ScrollController _castScrollController = ScrollController();
  final ScrollController _similarTvShowsScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();

  // Animation Controllers
  late AnimationController _heroAnimationController;

  @override
  void initState() {
    super.initState();
    _heroAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    _videoScrollController.dispose();
    _castScrollController.dispose();
    _similarTvShowsScrollController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Consumer(
        builder: (context, ref, child) {
          final tvShowAsync = ref.watch(tvShowDetailProvider(widget.tvShowId));
          
          return tvShowAsync.when(
            data: (tvShow) => _buildTvShowContent(tvShow),
            loading: () => _buildLoadingState(),
            error: (error, stack) => _buildErrorState(error),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Lỗi tải thông tin: $error',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildTvShowContent(TvShowDetail tvShow) {
    return CustomScrollView(
      controller: _mainScrollController,
      slivers: [
        // Hero Section with Backdrop
        _buildHeroSection(tvShow),
        
        // TV Show Info
        _buildTvShowInfo(tvShow),
        
        // Overview Section
        if (tvShow.overview.isNotEmpty) _buildOverviewSection(tvShow),
        
        // Videos Section
        _buildVideosSection(tvShow.id),
        
        // Cast Section
        _buildCastSection(tvShow.id),
        
        // Similar TV Shows Section
        _buildSimilarTvShowsSection(tvShow.id),
        
        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildHeroSection(TvShowDetail tvShow) {
    return SliverAppBar(
      expandedHeight: 500,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop Image
            if (tvShow.backdropPath.isNotEmpty)
              Image.network(
                'https://image.tmdb.org/t/p/w1280${tvShow.backdropPath}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Icon(
                      Icons.tv,
                      size: 100,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            
            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      tvShow.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Tagline
                    if (tvShow.tagline.isNotEmpty)
                      Text(
                        tvShow.tagline,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Rating and Info
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.yellow, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          tvShow.voteAverage.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (tvShow.firstAirDate.isNotEmpty)
                          Text(
                            'Ngày phát sóng: ${_formatDate(tvShow.firstAirDate)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Genres
                    if (tvShow.genres.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: tvShow.genres.map((genre) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE50914),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            genre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTvShowInfo(TvShowDetail tvShow) {
    return SliverToBoxAdapter(
      child: Container(
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

  Widget _buildOverviewSection(TvShowDetail tvShow) {
    return SliverToBoxAdapter(
      child: Container(
        color: const Color(0xFF141414),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tóm tắt',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedCrossFade(
              firstChild: Text(
                tvShow.overview,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(
                tvShow.overview,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              crossFadeState: _isOverviewExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
            if (tvShow.overview.length > 150)
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
      ),
    );
  }

  Widget _buildVideosSection(int tvShowId) {
    return SliverToBoxAdapter(
      child: Consumer(
        builder: (context, ref, child) {
          final videosAsync = ref.watch(tvShowVideosProvider(tvShowId));
          
          return videosAsync.when(
            data: (videos) {
              if (videos.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Container(
                color: const Color(0xFF141414),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: Text(
                        'Video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        controller: _videoScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          final video = videos[index];
                          return Container(
                            width: 300,
                            margin: const EdgeInsets.only(right: 16),
                            child: _VideoCard(video: video),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  Widget _buildCastSection(int tvShowId) {
    return SliverToBoxAdapter(
      child: Consumer(
        builder: (context, ref, child) {
          final castAsync = ref.watch(tvShowCreditsProvider(tvShowId));
          
          return castAsync.when(
            data: (credits) {
              final castList = credits.cast;
              if (castList.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Container(
                color: const Color(0xFF141414),
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
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        controller: _castScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: castList.length,
                        itemBuilder: (context, index) {
                          final actor = castList[index];
                          return _CastCard(actor: actor, index: index);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  Widget _buildSimilarTvShowsSection(int tvShowId) {
    return SliverToBoxAdapter(
      child: Consumer(
        builder: (context, ref, child) {
          final similarAsync = ref.watch(similarTvShowsProvider(tvShowId));
          
          return similarAsync.when(
            data: (tvShows) {
              if (tvShows.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Container(
                color: const Color(0xFF141414),
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
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        controller: _similarTvShowsScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: tvShows.length,
                        itemBuilder: (context, index) {
                          final tvShow = tvShows[index];
                          return _SimilarTvShowCard(tvShow: tvShow);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          );
        },
      ),
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
}

// =========================
//       VIDEO CARD
// =========================
class _VideoCard extends StatefulWidget {
  final Video video;

  const _VideoCard({required this.video});

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle video tap
        _showVideoPlayer(context, widget.video);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF1A1A1A),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      color: const Color(0xFF2A2A2A),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (widget.video.thumbnailUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            child: Image.network(
                              widget.video.thumbnailUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFF2A2A2A),
                                  child: const Icon(Icons.play_circle_outline, size: 50, color: Colors.white),
                                );
                              },
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                        ),
                        const Icon(
                          Icons.play_circle_filled,
                          size: 50,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Video Info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.video.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.video.type,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVideoPlayer(BuildContext context, Video video) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.6,
          child: YoutubePlayer(
            controller: YoutubePlayerController.fromVideoId(
              videoId: video.key,
              autoPlay: true,
              params: const YoutubePlayerParams(
                showControls: true,
                mute: false,
              ),
            ),
          ),
        ),
      ),
    );
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
                  child: ClipOval(
                    child: widget.actor.profilePath.isNotEmpty
                        ? Image.network(
                            'https://image.tmdb.org/t/p/w500${widget.actor.profilePath}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.actor.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.actor.character.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.actor.character,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================
//   SIMILAR TV SHOW CARD
// =========================
class _SimilarTvShowCard extends StatefulWidget {
  final TvShow tvShow;

  const _SimilarTvShowCard({required this.tvShow});

  @override
  State<_SimilarTvShowCard> createState() => _SimilarTvShowCardState();
}

class _SimilarTvShowCardState extends State<_SimilarTvShowCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TvShowDetailScreen(tvShowId: widget.tvShow.id),
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 200,
          margin: const EdgeInsets.only(right: 16),
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF2A2A2A),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.tvShow.posterPath.isNotEmpty
                        ? Image.network(
                            'https://image.tmdb.org/t/p/w500${widget.tvShow.posterPath}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF2A2A2A),
                                child: const Icon(
                                  Icons.tv,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFF2A2A2A),
                            child: const Icon(
                              Icons.tv,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Title
              Text(
                widget.tvShow.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Rating
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.yellow, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    widget.tvShow.voteAverage.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}