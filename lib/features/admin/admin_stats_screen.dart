import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/models/backend_models.dart';

class AdminStatsScreen extends ConsumerStatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  ConsumerState<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends ConsumerState<AdminStatsScreen> with SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê nền tảng'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(adminStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => _buildStatsContent(context, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
            Text('Lỗi tải thống kê: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(adminStatsProvider),
              child: const Text('Thử lại'),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsContent(BuildContext context, AdminStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview section
          _buildSection(
            'Tổng quan nền tảng',
            [
              _buildStatCard(
                'Tổng người dùng',
                stats.totalUsers.toString(),
                Icons.people,
                Colors.blue,
                'Tất cả người dùng đã đăng ký',
              ),
              _buildStatCard(
                'Quản trị viên',
                stats.totalAdmins.toString(),
                Icons.admin_panel_settings,
                Colors.red,
                'Tài khoản quản trị',
              ),
              _buildStatCard(
                'Người dùng thường',
                stats.totalRegularUsers.toString(),
                Icons.person,
                Colors.green,
                'Tài khoản người dùng thường',
              ),
              _buildStatCard(
                'Người dùng mới',
                stats.recentUsers.toString(),
                Icons.person_add,
                Colors.purple,
                'Tham gia trong 7 ngày qua',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // User engagement section
          _buildSection(
            'Tương tác người dùng',
            [
              _buildStatCard(
                'Tổng yêu thích',
                stats.totalFavorites.toString(),
                Icons.favorite,
                Colors.pink,
                'Phim/TV được yêu thích',
              ),
              _buildStatCard(
                'Tổng danh sách xem',
                stats.totalWatchlists.toString(),
                Icons.playlist_add,
                Colors.orange,
                'Mục trong danh sách xem',
              ),
              _buildStatCard(
                'Tổng ghi chú',
                stats.totalNotes.toString(),
                Icons.note,
                Colors.amber,
                'Ghi chú người dùng tạo',
              ),
              _buildStatCard(
                'Tổng lịch sử',
                stats.totalHistories.toString(),
                Icons.history,
                Colors.teal,
                'Bản ghi hoạt động người dùng',
              ),
              _buildStatCard(
                'Tổng đánh giá',
                stats.totalRatings.toString(),
                Icons.star,
                Colors.yellow,
                'Đánh giá người dùng đã cho',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Insights section
          _buildInsightsSection(stats),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: children,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              fontSize: 7,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(AdminStats stats) {
    final avgFavoritesPerUser = stats.totalUsers > 0 ? (stats.totalFavorites / stats.totalUsers).toStringAsFixed(1) : '0';
    final avgWatchlistsPerUser = stats.totalUsers > 0 ? (stats.totalWatchlists / stats.totalUsers).toStringAsFixed(1) : '0';
    final avgNotesPerUser = stats.totalUsers > 0 ? (stats.totalNotes / stats.totalUsers).toStringAsFixed(1) : '0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin chính',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            'Trung bình yêu thích/người dùng',
            '$avgFavoritesPerUser',
            Icons.favorite,
            Colors.pink,
          ),
          _buildInsightRow(
            'Trung bình danh sách xem/người dùng',
            '$avgWatchlistsPerUser',
            Icons.playlist_add,
            Colors.orange,
          ),
          _buildInsightRow(
            'Trung bình ghi chú/người dùng',
            '$avgNotesPerUser',
            Icons.note,
            Colors.amber,
          ),
          _buildInsightRow(
            'Tỷ lệ Admin:Người dùng',
            '${stats.totalAdmins}:${stats.totalRegularUsers}',
            Icons.admin_panel_settings,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
