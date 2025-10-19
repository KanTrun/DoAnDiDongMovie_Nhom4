import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/history_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/backend_models.dart';
import '../movie_detail/movie_detail_screen.dart';
import '../movie_detail/tv_show_detail_screen.dart';

class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  String _selectedFilter = 'All';
  String _selectedMediaType = 'All';
  int _currentPage = 1;
  final int _pageSize = 20;

  final List<String> _actionFilters = [
    'All',
    'TrailerView',
    'DetailOpen',
    'ProviderClick',
    'NoteCreated',
    'RatingGiven',
    'FavoriteAdded',
    'FavoriteRemoved',
    'WatchlistAdded',
    'WatchlistRemoved',
    'ShareClick',
  ];

  final List<String> _mediaTypeFilters = ['All', 'movie', 'tv'];

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (!isAuthenticated) {
      return _buildNotLoggedIn(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        title: const Text('Lịch sử hoạt động'),
        backgroundColor: const Color(0xFF141414),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _showClearHistoryDialog,
            tooltip: 'Xóa tất cả lịch sử',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'Đăng nhập để xem lịch sử hoạt động',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navigate to login screen
                Navigator.of(context).pushNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Đăng nhập',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Action filter
          Row(
            children: [
              const Text(
                'Hành động:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _actionFilters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            _getActionDisplayName(filter),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[300],
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                              _currentPage = 1;
                            });
                            _loadHistory();
                          },
                          backgroundColor: Colors.grey[800],
                          selectedColor: const Color(0xFFE50914),
                          checkmarkColor: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Media type filter
          Row(
            children: [
              const Text(
                'Loại:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _mediaTypeFilters.map((filter) {
                      final isSelected = _selectedMediaType == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            _getMediaTypeDisplayName(filter),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[300],
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedMediaType = filter;
                              _currentPage = 1;
                            });
                            _loadHistory();
                          },
                          backgroundColor: Colors.grey[800],
                          selectedColor: const Color(0xFFE50914),
                          checkmarkColor: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return Consumer(
      builder: (context, ref, child) {
        final historyAsync = ref.watch(historyProvider);

        return historyAsync.when(
          data: (histories) {
            if (histories.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              itemCount: histories.length,
              itemBuilder: (context, index) {
                final history = histories[index];
                return _buildHistoryItem(history);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Lỗi tải lịch sử: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadHistory,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có hoạt động nào',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy khám phá phim và chương trình TV để tạo lịch sử hoạt động',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(History history) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.grey[900],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActionColor(history.action),
          child: Icon(
            _getActionIcon(history.action),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          _getActionDisplayName(history.action),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${history.mediaType.toUpperCase()} ID: ${history.tmdbId}',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            Text(
              _formatDateTime(history.watchedAt),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
            if (history.extra != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatExtra(history.extra!),
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) {
            if (value == 'view') {
              _viewMedia(history);
            } else if (value == 'delete') {
              _deleteHistoryItem(history);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Text('Xem chi tiết'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Xóa'),
            ),
          ],
        ),
        onTap: () => _viewMedia(history),
      ),
    );
  }

  String _getActionDisplayName(String action) {
    switch (action) {
      case 'TrailerView':
        return 'Xem trailer';
      case 'DetailOpen':
        return 'Mở chi tiết';
      case 'ProviderClick':
        return 'Click nhà cung cấp';
      case 'NoteCreated':
        return 'Tạo ghi chú';
      case 'RatingGiven':
        return 'Đánh giá';
      case 'FavoriteAdded':
        return 'Thêm yêu thích';
      case 'FavoriteRemoved':
        return 'Bỏ yêu thích';
      case 'WatchlistAdded':
        return 'Thêm danh sách';
      case 'WatchlistRemoved':
        return 'Bỏ danh sách';
      case 'ShareClick':
        return 'Chia sẻ';
      default:
        return action;
    }
  }

  String _getMediaTypeDisplayName(String mediaType) {
    switch (mediaType) {
      case 'movie':
        return 'Phim';
      case 'tv':
        return 'TV Show';
      default:
        return 'Tất cả';
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'TrailerView':
        return Colors.blue;
      case 'DetailOpen':
        return Colors.green;
      case 'ProviderClick':
        return Colors.orange;
      case 'NoteCreated':
        return Colors.purple;
      case 'RatingGiven':
        return Colors.yellow[700]!;
      case 'FavoriteAdded':
        return Colors.red;
      case 'FavoriteRemoved':
        return Colors.grey;
      case 'WatchlistAdded':
        return Colors.teal;
      case 'WatchlistRemoved':
        return Colors.grey;
      case 'ShareClick':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'TrailerView':
        return Icons.play_circle;
      case 'DetailOpen':
        return Icons.info;
      case 'ProviderClick':
        return Icons.link;
      case 'NoteCreated':
        return Icons.note;
      case 'RatingGiven':
        return Icons.star;
      case 'FavoriteAdded':
        return Icons.favorite;
      case 'FavoriteRemoved':
        return Icons.favorite_border;
      case 'WatchlistAdded':
        return Icons.bookmark;
      case 'WatchlistRemoved':
        return Icons.bookmark_border;
      case 'ShareClick':
        return Icons.share;
      default:
        return Icons.history;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatExtra(String extra) {
    try {
      // Try to parse JSON and format nicely
      // For now, just return the raw string
      return extra;
    } catch (e) {
      return extra;
    }
  }

  void _loadHistory() {
    ref.read(historyProvider.notifier).loadHistory(
      page: _currentPage,
      pageSize: _pageSize,
      action: _selectedFilter == 'All' ? null : _selectedFilter,
      mediaType: _selectedMediaType == 'All' ? null : _selectedMediaType,
    );
  }

  void _viewMedia(History history) {
    if (history.mediaType == 'tv') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TvShowDetailScreen(tvShowId: history.tmdbId),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MovieDetailScreen(movieId: history.tmdbId),
        ),
      );
    }
  }

  void _deleteHistoryItem(History history) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hoạt động'),
        content: const Text('Bạn có chắc muốn xóa hoạt động này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(historyProvider.notifier).deleteHistoryItem(history.id);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả lịch sử'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử hoạt động? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(historyProvider.notifier).clearHistory();
            },
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }
}
