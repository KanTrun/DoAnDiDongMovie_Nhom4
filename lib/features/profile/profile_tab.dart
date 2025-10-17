import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/backend_provider.dart';
import '../favorites/favorites_tab.dart';
import '../watchlist/watchlist_tab.dart';
import '../admin/admin_dashboard_screen.dart';
import 'settings_tab.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    if (!isAuthenticated || currentUser == null) {
      return _buildNotLoggedIn(context, ref);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Netflix-style App Bar with gradient
          SliverAppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            floating: true,
            snap: true,
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF141414),
                      Colors.black,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Profile avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE50914), Color(0xFFB20710)],
                          ),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.transparent,
                          backgroundImage: currentUser.profilePicture != null && currentUser.profilePicture!.isNotEmpty
                              ? NetworkImage(currentUser.profilePicture!)
                              : null,
                          child: currentUser.profilePicture == null || currentUser.profilePicture!.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // User name
                      Text(
                        currentUser.fullName ?? 'Người dùng',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // User email
                      Text(
                        currentUser.email,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_outlined, color: Colors.white),
                onPressed: () => _showLogoutDialog(context, ref),
              ),
            ],
          ),
          
          // Profile content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics cards
                  _buildStatisticsSection(context, ref),
                  
                  const SizedBox(height: 30),
                  
                  // Menu items
                  _buildMenuSection(context, ref),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFFB20710)],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Chưa đăng nhập',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Đăng nhập để trải nghiệm đầy đủ tính năng của MoviePlus',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Navigate to login screen
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Đăng nhập ngay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thống kê',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Yêu thích',
                count: ref.watch(favoritesProvider).maybeWhen(
                  data: (favorites) => favorites.length,
                  orElse: () => 0,
                ),
                color: const Color(0xFFE50914),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FavoritesTab()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Danh sách xem',
                count: ref.watch(watchlistProvider).maybeWhen(
                  data: (watchlist) => watchlist.length,
                  orElse: () => 0,
                ),
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WatchlistTab()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Ghi chú',
                count: ref.watch(notesProvider).maybeWhen(
                  data: (notes) => notes.length,
                  orElse: () => 0,
                ),
                color: Colors.orange,
                onTap: () {
                  // TODO: Navigate to notes tab
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng ghi chú đang phát triển')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Đánh giá',
                count: ref.watch(ratingsProvider).maybeWhen(
                  data: (ratings) => ratings.length,
                  orElse: () => 0,
                ),
                color: Colors.yellow,
                onTap: () {
                  // TODO: Navigate to ratings tab
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng đánh giá đang phát triển')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.role == 'Admin';
    
    final menuItems = [
      // Admin Dashboard - only show for admins
      if (isAdmin) ...[
        {
          'icon': Icons.admin_panel_settings,
          'title': 'Admin Dashboard',
          'subtitle': 'Quản lý hệ thống và người dùng',
          'color': Colors.red,
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
            );
          },
        },
      ],
      {
        'icon': Icons.person_outline,
        'title': 'Chỉnh sửa hồ sơ',
        'subtitle': 'Cập nhật thông tin cá nhân',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsTab()),
          );
        },
      },
      {
        'icon': Icons.notifications,
        'title': 'Thông báo',
        'subtitle': 'Cài đặt thông báo và nhắc nhở',
        'onTap': () {
          // Navigate to notifications settings
        },
      },
      {
        'icon': Icons.security_outlined,
        'title': 'Bảo mật',
        'subtitle': 'Đổi mật khẩu và cài đặt bảo mật',
        'onTap': () {
          // Navigate to security settings
        },
      },
      {
        'icon': Icons.language_outlined,
        'title': 'Ngôn ngữ',
        'subtitle': 'Chọn ngôn ngữ hiển thị',
        'onTap': () {
          // Navigate to language settings
        },
      },
      {
        'icon': Icons.info_outline,
        'title': 'Giới thiệu',
        'subtitle': 'Thông tin về ứng dụng',
        'onTap': () {
          _showAboutDialog(context);
        },
      },
      {
        'icon': Icons.help_outline,
        'title': 'Trợ giúp',
        'subtitle': 'Hướng dẫn sử dụng và hỗ trợ',
        'onTap': () {
          // Navigate to help
        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cài đặt',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...menuItems.map((item) => _buildMenuItem(
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          subtitle: item['subtitle'] as String,
          color: item['color'] as Color?,
          onTap: item['onTap'] as VoidCallback,
        )),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color ?? Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Đăng xuất',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
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
              ),
              child: const Icon(Icons.movie, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text(
              'MoviePlus',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'MoviePlus v1.0.0\n\nỨng dụng xem thông tin phim với giao diện hiện đại, tích hợp TMDB API.\n\nPhát triển bởi Nhóm 4 - Đồ án di động.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
            ),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}