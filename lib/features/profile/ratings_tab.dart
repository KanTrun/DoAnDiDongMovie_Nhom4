import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/ratings_provider.dart';
import '../../core/models/rating.dart';

class RatingsTab extends ConsumerStatefulWidget {
  const RatingsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<RatingsTab> createState() => _RatingsTabState();
}

class _RatingsTabState extends ConsumerState<RatingsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ratingsProvider.notifier).loadRatings(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(ratingsProvider.notifier).loadMoreRatings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingsState = ref.watch(ratingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        title: const Text('Đánh giá của tôi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              ref.read(ratingsProvider.notifier).loadRatings(refresh: true);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm đánh giá...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Ratings list
          Expanded(
            child: ratingsState.isLoading && ratingsState.ratings.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ratingsState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Lỗi: ${ratingsState.error}',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref.read(ratingsProvider.notifier).loadRatings(refresh: true);
                              },
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : ratingsState.ratings.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Chưa có đánh giá nào',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Hãy xem phim và đánh giá!',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              ref.read(ratingsProvider.notifier).loadRatings(refresh: true);
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: ratingsState.ratings.length + (ratingsState.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == ratingsState.ratings.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final rating = ratingsState.ratings[index];
                                return _buildRatingCard(rating);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(Rating rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: rating.mediaType == 'movie' ? Colors.blue : Colors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      rating.mediaType == 'movie' ? 'Phim' : 'TV',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ID: ${rating.tmdbId}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                _formatDate(rating.createdAt),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Rating display
          Row(
            children: [
              // Stars
              Row(
                children: List.generate(10, (index) {
                  final starRating = (index + 1) * 0.5;
                  final isSelected = starRating <= rating.score;
                  final isHalf = starRating - 0.5 <= rating.score && rating.score < starRating;

                  return Icon(
                    isHalf ? Icons.star_half : Icons.star,
                    color: isSelected ? Colors.amber : Colors.grey,
                    size: 20,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                '${rating.score.toStringAsFixed(1)}/10',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (rating.updatedAt != null)
                Text(
                  'Cập nhật: ${_formatDate(rating.updatedAt!)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                )
              else
                const SizedBox.shrink(),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _viewMovie(rating.tmdbId, rating.mediaType),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Xem phim'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteRating(rating),
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _viewMovie(int tmdbId, String mediaType) {
    if (mediaType == 'tv') {
      context.go('/tv/$tmdbId');
    } else {
      context.go('/movie/$tmdbId');
    }
  }

  void _deleteRating(Rating rating) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Xóa đánh giá', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bạn có chắc chắn muốn xóa đánh giá này?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(ratingsProvider.notifier).deleteRating(rating.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
