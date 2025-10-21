import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/two_factor_service.dart';
import 'enable_2fa_screen.dart';
import 'disable_2fa_screen.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  bool _isLoading = true;
  bool _twoFactorEnabled = false;
  DateTime? _twoFactorEnabledAt;

  @override
  void initState() {
    super.initState();
    _load2FAStatus();
  }

  Future<void> _load2FAStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await TwoFactorService.get2FAStatus();
      setState(() {
        _twoFactorEnabled = status.twoFactorEnabled;
        _twoFactorEnabledAt = status.twoFactorEnabledAt;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Bảo mật',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.red),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.red, Colors.redAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.security,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Bảo mật tài khoản',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Quản lý các tùy chọn bảo mật cho tài khoản của bạn',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 2FA Section
                  const Text(
                    'Xác thực 2 lớp',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _twoFactorEnabled ? Icons.verified_user : Icons.security,
                              color: _twoFactorEnabled ? Colors.green : Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _twoFactorEnabled ? 'Đã bật' : 'Chưa bật',
                                    style: TextStyle(
                                      color: _twoFactorEnabled ? Colors.green : Colors.orange,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _twoFactorEnabled 
                                        ? 'Xác thực 2 lớp đang hoạt động'
                                        : 'Bảo vệ tài khoản bằng mã xác thực',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        if (_twoFactorEnabled && _twoFactorEnabledAt != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule, color: Colors.grey, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Được bật lúc: ${_formatDate(_twoFactorEnabledAt!)}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_twoFactorEnabled) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Disable2FAScreen(),
                                  ),
                                ).then((_) => _load2FAStatus());
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Enable2FAScreen(),
                                  ),
                                ).then((_) => _load2FAStatus());
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _twoFactorEnabled ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _twoFactorEnabled ? 'Tắt xác thực 2 lớp' : 'Bật xác thực 2 lớp',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Info section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Thông tin về xác thực 2 lớp',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Xác thực 2 lớp giúp bảo vệ tài khoản khỏi các mối đe dọa bảo mật',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '• Bạn cần Google Authenticator để sử dụng tính năng này',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '• Mã xác thực thay đổi mỗi 30 giây',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
