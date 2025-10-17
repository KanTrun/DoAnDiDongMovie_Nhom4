import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Cài đặt',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildSection(
              title: 'Hồ sơ',
              items: [
                _buildSettingItem(
                  icon: Icons.person_outline,
                  title: 'Thông tin cá nhân',
                  subtitle: currentUser?.email ?? 'Chưa đăng nhập',
                  onTap: () => _showEditProfileDialog(context, ref),
                ),
                _buildSettingItem(
                  icon: Icons.camera_alt_outlined,
                  title: 'Ảnh đại diện',
                  subtitle: 'Cập nhật ảnh đại diện',
                  onTap: () => _showChangeAvatarDialog(context),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Security Section
            _buildSection(
              title: 'Bảo mật',
              items: [
                _buildSettingItem(
                  icon: Icons.lock_outline,
                  title: 'Đổi mật khẩu',
                  subtitle: 'Cập nhật mật khẩu bảo mật',
                  onTap: () => _showChangePasswordDialog(context, ref),
                ),
                _buildSettingItem(
                  icon: Icons.security_outlined,
                  title: 'Bảo mật tài khoản',
                  subtitle: 'Xác thực 2 bước, khôi phục tài khoản',
                  onTap: () => _showSecurityDialog(context),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Preferences Section
            _buildSection(
              title: 'Tùy chọn',
              items: [
                _buildSettingItem(
                  icon: Icons.notifications_outlined,
                  title: 'Thông báo',
                  subtitle: 'Cài đặt thông báo và nhắc nhở',
                  onTap: () => _showNotificationSettings(context),
                ),
                _buildSettingItem(
                  icon: Icons.language_outlined,
                  title: 'Ngôn ngữ',
                  subtitle: 'Tiếng Việt',
                  onTap: () => _showLanguageSettings(context),
                ),
                _buildSettingItem(
                  icon: Icons.dark_mode_outlined,
                  title: 'Chủ đề',
                  subtitle: 'Chế độ tối',
                  onTap: () => _showThemeSettings(context),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Data Section
            _buildSection(
              title: 'Dữ liệu',
              items: [
                _buildSettingItem(
                  icon: Icons.download_outlined,
                  title: 'Tải xuống',
                  subtitle: 'Quản lý nội dung đã tải',
                  onTap: () => _showDownloadSettings(context),
                ),
                _buildSettingItem(
                  icon: Icons.storage_outlined,
                  title: 'Lưu trữ',
                  subtitle: 'Xóa cache, dữ liệu tạm',
                  onTap: () => _showStorageSettings(context),
                ),
                _buildSettingItem(
                  icon: Icons.cloud_sync_outlined,
                  title: 'Đồng bộ',
                  subtitle: 'Sao lưu và khôi phục dữ liệu',
                  onTap: () => _showSyncSettings(context),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Support Section
            _buildSection(
              title: 'Hỗ trợ',
              items: [
                _buildSettingItem(
                  icon: Icons.help_outline,
                  title: 'Trợ giúp',
                  subtitle: 'FAQ, hướng dẫn sử dụng',
                  onTap: () => _showHelpDialog(context),
                ),
                _buildSettingItem(
                  icon: Icons.feedback_outlined,
                  title: 'Phản hồi',
                  subtitle: 'Gửi ý kiến, báo lỗi',
                  onTap: () => _showFeedbackDialog(context),
                ),
                _buildSettingItem(
                  icon: Icons.info_outline,
                  title: 'Về ứng dụng',
                  subtitle: 'MoviePlus v1.0.0',
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Logout Button
            _buildLogoutButton(context, ref),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                  color: Colors.grey[800],
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

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showLogoutDialog(context, ref),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE50914),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout, size: 20),
            SizedBox(width: 8),
            Text(
              'Đăng xuất',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog methods
  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(currentUserProvider);
    final nameController = TextEditingController(text: currentUser?.fullName ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Họ và tên',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE50914)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Update user profile
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cập nhật hồ sơ thành công')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Đổi mật khẩu', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE50914)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE50914)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE50914)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text == confirmPasswordController.text) {
                // TODO: Change password
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đổi mật khẩu thành công')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
            child: const Text('Đổi mật khẩu'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  // Simple notification methods for other dialogs
  void _showChangeAvatarDialog(BuildContext context) {
    _showFeatureDialog(context, 'Thay đổi ảnh đại diện', 'Tính năng này sẽ được phát triển trong phiên bản tới.');
  }

  void _showSecurityDialog(BuildContext context) {
    _showFeatureDialog(context, 'Bảo mật tài khoản', 'Tính năng xác thực 2 bước sẽ được cập nhật sớm.');
  }

  void _showNotificationSettings(BuildContext context) {
    _showFeatureDialog(context, 'Cài đặt thông báo', 'Tính năng thông báo đang được phát triển.');
  }

  void _showLanguageSettings(BuildContext context) {
    _showFeatureDialog(context, 'Cài đặt ngôn ngữ', 'Hiện tại ứng dụng hỗ trợ tiếng Việt.');
  }

  void _showThemeSettings(BuildContext context) {
    _showFeatureDialog(context, 'Cài đặt chủ đề', 'Chế độ sáng sẽ được thêm trong phiên bản tới.');
  }

  void _showDownloadSettings(BuildContext context) {
    _showFeatureDialog(context, 'Quản lý tải xuống', 'Tính năng tải xuống đang được phát triển.');
  }

  void _showStorageSettings(BuildContext context) {
    _showFeatureDialog(context, 'Quản lý lưu trữ', 'Tính năng quản lý cache sẽ được cập nhật.');
  }

  void _showSyncSettings(BuildContext context) {
    _showFeatureDialog(context, 'Đồng bộ dữ liệu', 'Tính năng sao lưu cloud đang được phát triển.');
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Trợ giúp', style: TextStyle(color: Colors.white)),
        content: const Text(
          'MoviePlus - Ứng dụng xem thông tin phim\n\n'
          '• Khám phá phim mới từ TMDB\n'
          '• Thêm phim vào danh sách yêu thích\n'
          '• Tạo danh sách phim muốn xem\n'
          '• Đánh giá và viết ghi chú\n\n'
          'Liên hệ hỗ trợ: support@movieplus.com',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Gửi phản hồi', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: feedbackController,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Chia sẻ ý kiến của bạn về ứng dụng...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE50914)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cảm ơn phản hồi của bạn!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
            child: const Text('Gửi'),
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
            const Text('MoviePlus', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'MoviePlus v1.0.0\n\n'
          'Ứng dụng xem thông tin phim với giao diện hiện đại, '
          'tích hợp TMDB API để cung cấp thông tin phim chính xác và cập nhật.\n\n'
          'Tính năng:\n'
          '• Khám phá phim hot, mới nhất\n'
          '• Tìm kiếm phim theo tên, thể loại\n'
          '• Thông tin chi tiết phim, diễn viên\n'
          '• Quản lý danh sách yêu thích\n'
          '• Đánh giá và ghi chú cá nhân\n\n'
          'Phát triển bởi Nhóm 4 - Đồ án di động\n'
          'Trường Đại học ABC',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showFeatureDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}