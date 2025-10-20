import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/ratings_provider.dart';
import '../../../core/models/rating.dart';

class RatingSection extends ConsumerStatefulWidget {
  final int tmdbId;
  final String mediaType;

  const RatingSection({
    Key? key,
    required this.tmdbId,
    required this.mediaType,
  }) : super(key: key);

  @override
  ConsumerState<RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends ConsumerState<RatingSection> {
  double _selectedRating = 0.0;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final providerKey = '${widget.tmdbId}_${widget.mediaType}';
    final ratingState = ref.watch(movieRatingProvider(providerKey));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đánh giá của tôi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        if (ratingState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (ratingState.error != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Lỗi: ${ratingState.error}',
              style: const TextStyle(color: Colors.white),
            ),
          )
        else
          _buildRatingContent(ratingState.rating),
      ],
    );
  }

  Widget _buildRatingContent(Rating? rating) {
    final currentRating = rating?.score ?? 0.0;
    final displayRating = _selectedRating > 0 ? _selectedRating : currentRating;

    return Container(
      width: double.infinity, // Ensure full width
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        children: [
          // Star rating display (10 stars = 1.0 to 10.0) - Fixed overflow
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(10, (index) {
                final starValue = (index + 1).toDouble();
                final isSelected = starValue <= displayRating;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = starValue;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    child: Icon(
                      Icons.star,
                      color: isSelected ? Colors.amber : Colors.grey,
                      size: 28, // Reduced from 32 to 28
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),

          // Rating text
          Text(
            displayRating > 0 ? '${displayRating.toStringAsFixed(1)}/10' : 'Chưa đánh giá',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: displayRating > 0 ? Colors.amber : Colors.grey,
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons - Fixed overflow with responsive design
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 300;
              
              if (isWideScreen) {
                // Wide screen: use Row with Expanded
                return Row(
                  children: [
                    if (rating != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _deleteRating,
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Xóa đánh giá'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectedRating > 0 && !_isSubmitting ? _submitRating : null,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save, size: 16),
                        label: Text(_isSubmitting ? 'Đang lưu...' : 'Lưu đánh giá'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Narrow screen: use Column
                return Column(
                  children: [
                    if (rating != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _deleteRating,
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Xóa đánh giá'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _selectedRating > 0 && !_isSubmitting ? _submitRating : null,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save, size: 16),
                        label: Text(_isSubmitting ? 'Đang lưu...' : 'Lưu đánh giá'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),

          if (rating != null) ...[
            const SizedBox(height: 12),
            Text(
              'Đã đánh giá: ${_formatDate(rating.createdAt)}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            if (rating.updatedAt != null)
              Text(
                'Cập nhật: ${_formatDate(rating.updatedAt!)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _submitRating() async {
    if (_selectedRating <= 0) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(movieRatingProvider('${widget.tmdbId}_${widget.mediaType}').notifier)
          .upsertRating(_selectedRating);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đánh giá đã được lưu!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _deleteRating() async {
    final confirmed = await showDialog<bool>(
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        await ref.read(movieRatingProvider('${widget.tmdbId}_${widget.mediaType}').notifier)
            .deleteRating();

        if (mounted) {
          setState(() {
            _selectedRating = 0.0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đánh giá đã được xóa!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
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
