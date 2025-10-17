import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/movie.dart';
import '../../core/providers/tmdb_provider.dart';
import '../movie_detail/movie_detail_screen.dart';

class AdvancedSearchTab extends ConsumerStatefulWidget {
  const AdvancedSearchTab({super.key});

  @override
  ConsumerState<AdvancedSearchTab> createState() => _AdvancedSearchTabState();
}

class _AdvancedSearchTabState extends ConsumerState<AdvancedSearchTab> {
  int? _selectedYear;
  String? _selectedGenre;
  double _minRating = 0.0;
  double _maxRating = 10.0;
  String _sortBy = 'popularity.desc';

  List<Movie> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  final List<String> _sortOptions = [
    'popularity.desc',
    'popularity.asc',
    'vote_average.desc',
    'vote_average.asc',
    'primary_release_date.desc',
    'primary_release_date.asc',
    'title.asc',
    'title.desc',
  ];

  final Map<String, String> _sortLabels = {
    'popularity.desc': 'Phổ biến giảm dần',
    'popularity.asc': 'Phổ biến tăng dần',
    'vote_average.desc': 'Điểm cao nhất',
    'vote_average.asc': 'Điểm thấp nhất',
    'primary_release_date.desc': 'Mới nhất',
    'primary_release_date.asc': 'Cũ nhất',
    'title.asc': 'Tên A-Z',
    'title.desc': 'Tên Z-A',
  };

  final Map<String, int> _genres = {
    'Hành động': 28,
    'Phiêu lưu': 12,
    'Hoạt hình': 16,
    'Hài': 35,
    'Tội phạm': 80,
    'Tài liệu': 99,
    'Chính kịch': 18,
    'Gia đình': 10751,
    'Giả tưởng': 14,
    'Lịch sử': 36,
    'Kinh dị': 27,
    'Âm nhạc': 10402,
    'Bí ẩn': 9648,
    'Lãng mạn': 10749,
    'Khoa học viễn tưởng': 878,
    'Phim truyền hình': 10770,
    'Gây cấn': 53,
    'Chiến tranh': 10752,
    'Miền Tây': 37,
  };

  Future<void> _performAdvancedSearch() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final request = DiscoverRequest(
        page: 1,
        sortBy: _sortBy,
        withGenres:
            _selectedGenre != null ? _genres[_selectedGenre].toString() : null,
        voteAverageGte: _minRating,
        voteAverageLte: _maxRating,
        releaseDateGte:
            _selectedYear != null ? '$_selectedYear-01-01' : null,
        releaseDateLte:
            _selectedYear != null ? '$_selectedYear-12-31' : null,
      );

      final response = await ref.read(discoverMoviesProvider(request).future);
      setState(() {
        _searchResults = response.results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tìm kiếm: $e'),
            backgroundColor: const Color(0xFFE50914),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedYear = null;
      _selectedGenre = null;
      _minRating = 0.0;
      _maxRating = 10.0;
      _sortBy = 'popularity.desc';
      _searchResults = [];
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Column(
        children: [
          // Filter Section - More compact
          Container(
            constraints: const BoxConstraints(maxHeight: 360),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF141414),
                  const Color(0xFF141414).withOpacity(0.95),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compact Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE50914), Color(0xFFB20710)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE50914).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.tune, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Bộ Lọc',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _resetFilters,
                        icon: const Icon(Icons.refresh, size: 14),
                        label: const Text('Đặt lại', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE50914),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Compact Filters
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactDropdown(
                          label: 'Năm',
                          value: _selectedYear?.toString() ?? 'Tất cả',
                          items: [
                            'Tất cả',
                            ...List.generate(75, (index) => (2025 - index).toString()),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedYear = value == 'Tất cả' ? null : int.parse(value);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCompactDropdown(
                          label: 'Thể loại',
                          value: _selectedGenre ?? 'Tất cả',
                          items: ['Tất cả', ..._genres.keys],
                          onChanged: (value) {
                            setState(() {
                              _selectedGenre = value == 'Tất cả' ? null : value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Compact Rating Slider
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Điểm đánh giá',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFE50914), Color(0xFFB20710)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${_minRating.toStringAsFixed(1)} - ${_maxRating.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFFE50914),
                                inactiveTrackColor: Colors.white.withOpacity(0.2),
                                thumbColor: Colors.white,
                                overlayColor: const Color(0xFFE50914).withOpacity(0.2),
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              ),
                              child: RangeSlider(
                                values: RangeValues(_minRating, _maxRating),
                                min: 0.0,
                                max: 10.0,
                                divisions: 20,
                                onChanged: (values) {
                                  setState(() {
                                    _minRating = values.start;
                                    _maxRating = values.end;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Sort and Search Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildCompactDropdown(
                          label: 'Sắp xếp',
                          value: _sortLabels[_sortBy]!,
                          items: _sortOptions.map((e) => _sortLabels[e]!).toList(),
                          onChanged: (value) {
                            setState(() {
                              _sortBy = _sortLabels.entries
                                  .firstWhere((e) => e.value == value)
                                  .key;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _performAdvancedSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE50914),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Results Section
          Expanded(
            child: _buildResultsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: const Color(0xFF1F1F1F),
                style: const TextStyle(color: Colors.white, fontSize: 11),
                underline: const SizedBox(),
                icon: Icon(Icons.arrow_drop_down,
                    color: Colors.white.withOpacity(0.7), size: 18),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) onChanged(val);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: const Icon(Icons.filter_alt_outlined,
                  color: Colors.grey, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bắt đầu tìm kiếm',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Chọn bộ lọc và nhấn tìm kiếm',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
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
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Đang tìm kiếm...',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: Icon(Icons.movie_outlined, color: Colors.grey[400], size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy phim',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Thử thay đổi bộ lọc',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
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
                const Icon(Icons.check_circle_outline, color: Color(0xFFE50914), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Tìm thấy ${_searchResults.length} kết quả',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final movie = _searchResults[index];
              return _buildMovieCard(movie);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMovieCard(Movie movie) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MovieDetailScreen(movieId: movie.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Movie poster
              if (movie.posterPath.isNotEmpty)
                Image.network(
                  movie.fullPosterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                )
              else
                _buildPlaceholderImage(),

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
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.95),
                      ],
                    ),
                  ),
                ),
              ),

              // Rating badge
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE50914), Color(0xFFB20710)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 10),
                      const SizedBox(width: 3),
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
              ),

              // Movie title
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Text(
                  movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 4,
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

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[850],
      child: const Center(
        child: Icon(Icons.movie, color: Colors.grey, size: 32),
      ),
    );
  }
}
