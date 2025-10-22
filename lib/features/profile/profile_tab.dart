import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/backend_provider.dart';
import '../favorites/favorites_tab.dart';
import '../watchlist/watchlist_tab.dart';
import '../admin/admin_dashboard_screen.dart';
import '../nearby_cinema/screens/nearby_cinema_screen.dart';
import 'settings_tab.dart';
import 'notes_tab.dart';
import 'ratings_tab.dart';
import 'history_tab.dart';
import '../../core/providers/notes_provider.dart' as notes_providers;
import '../../core/providers/ratings_provider.dart' as ratings_providers;
import '../../core/providers/history_provider.dart' as history_providers;
import '../../core/providers/community_provider.dart';

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
                count: ref.watch(notes_providers.notesProvider).notes.length,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotesTab()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Đánh giá',
                count: ref.watch(ratings_providers.ratingsProvider).ratings.length,
                color: Colors.yellow,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RatingsTab()),
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
                title: 'Lịch sử',
                count: ref.watch(history_providers.historyProvider).maybeWhen(
                  data: (histories) => histories.length,
                  orElse: () => 0,
                ),
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryTab()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(), // Empty space for alignment
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Đang theo dõi',
                count: ref.watch(followStatsProvider).when(
                  data: (stats) => stats['following'] ?? 0,
                  loading: () => 0,
                  error: (_, __) => 0,
                ),
                color: Colors.green,
                onTap: () {
                  // TODO: Navigate to following list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Danh sách đang theo dõi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Người theo dõi',
                count: ref.watch(followStatsProvider).when(
                  data: (stats) => stats['followers'] ?? 0,
                  loading: () => 0,
                  error: (_, __) => 0,
                ),
                color: Colors.teal,
                onTap: () {
                  // TODO: Navigate to followers list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Danh sách người theo dõi'),
                      backgroundColor: Colors.teal,
                    ),
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
          'title': 'Bảng điều khiển Admin',
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
        'icon': Icons.location_on_outlined,
        'title': 'Rạp gần tôi',
        'subtitle': 'Tìm rạp chiếu phim gần vị trí của bạn',
        'color': const Color(0xFFE50914),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NearbyCinemaScreen()),
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
          context.push('/security-settings');
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
        'icon': Icons.fingerprint,
        'title': 'Quản lý vân tay',
        'subtitle': 'Liên kết/xóa đăng nhập bằng vân tay',
        'color': Colors.blue,
        'onTap': () => _showBiometricManagementDialog(context, ref),
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

  void _showBiometricManagementDialog(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final hasBiometric = currentUser?.bioAuthEnabled ?? false;
    
    print('🔍 DEBUG: Current user bioAuthEnabled = $hasBiometric');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          hasBiometric ? 'Quản lý vân tay' : 'Liên kết vân tay',
          style: const TextStyle(color: Colors.white),
        ),
        content: hasBiometric 
          ? const Text(
              'Tài khoản này đã đăng ký vân tay. Bạn có muốn xóa không?',
              style: TextStyle(color: Colors.white),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Liên kết vân tay với tài khoản để đăng nhập nhanh.',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚠️ Lưu ý quan trọng:',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Phải đăng ký vân tay TRƯỚC trong Cài đặt hệ thống\n'
                        '• App chỉ LIÊN KẾT vân tay đã có với tài khoản\n'
                        '• Không thể đăng ký vân tay mới từ app',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📱 Cách thực hiện:',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Vào Cài đặt → Bảo mật → Vân tay\n'
                        '2. Đăng ký vân tay trong hệ thống\n'
                        '3. Quay lại app → Bấm "Liên kết"',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          if (hasBiometric) ...[
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await ref.read(authProvider.notifier).removeBiometrics();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                        ? 'Đã xóa vân tay thành công!' 
                        : 'Xóa vân tay thất bại. Vui lòng thử lại.'),
                      backgroundColor: success ? Colors.green : const Color(0xFFE50914),
                    ),
                  );
                  
                  // Refresh state để cập nhật UI
                  if (success) {
                    ref.invalidate(authProvider);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xóa vân tay'),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performBiometricRegistration(context, ref);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Liên kết'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _performBiometricRegistration(BuildContext context, WidgetRef ref) async {
    // Hiển thị hướng dẫn đăng ký vân tay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Đăng ký vân tay',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.fingerprint, color: Colors.blue, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Bạn sẽ cần đặt ngón tay lên cảm biến 2 lần:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Lần 1: Đăng ký vân tay\n• Lần 2: Xác nhận vân tay',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đảm bảo ngón tay sạch và khô ráo',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _startBiometricRegistration(context, ref);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Bắt đầu'),
          ),
        ],
      ),
    );
  }

  Future<void> _startBiometricRegistration(BuildContext context, WidgetRef ref) async {
    // Lưu reference để tránh deactivated widget
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Hiển thị loading dialog với thông báo chi tiết
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Đang đăng ký vân tay...',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng đặt ngón tay lên cảm biến',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sẽ có 2 lần xác thực',
              style: TextStyle(color: Colors.blue, fontSize: 11),
            ),
          ],
        ),
      ),
    );

    try {
      print('🚀 DEBUG: Bắt đầu đăng ký vân tay từ UI');
      final success = await ref.read(authProvider.notifier).registerBiometrics();
      print('📊 DEBUG: Kết quả đăng ký = $success');
      
      // Sử dụng delay nhỏ để đảm bảo widget tree ổn định
      await Future.delayed(const Duration(milliseconds: 100));
      print('🔄 DEBUG: Đóng loading dialog...');
      navigator.pop();
      
      if (success) {
        print('✅ DEBUG: Hiển thị thông báo thành công');
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('🎉 Liên kết vân tay thành công! Bây giờ bạn có thể đăng nhập bằng vân tay.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        print('❌ DEBUG: Hiển thị thông báo thất bại');
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('❌ Liên kết vân tay thất bại. Vui lòng thử lại.'),
            backgroundColor: Color(0xFFE50914),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('💥 DEBUG: Exception trong UI: $e');
      // Đóng loading dialog trong mọi trường hợp
      await Future.delayed(const Duration(milliseconds: 100));
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi chi tiết: $e'),
          backgroundColor: const Color(0xFFE50914),
          duration: const Duration(seconds: 5),
        ),
      );
    }
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