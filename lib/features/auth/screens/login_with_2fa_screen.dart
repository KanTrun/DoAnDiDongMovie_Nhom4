import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/two_factor_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user.dart' as models;

class LoginWith2FAScreen extends ConsumerStatefulWidget {
  final String email;
  final String password;

  const LoginWith2FAScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  ConsumerState<LoginWith2FAScreen> createState() => _LoginWith2FAScreenState();
}

class _LoginWith2FAScreenState extends ConsumerState<LoginWith2FAScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loginWith2FA() async {
    if (_codeController.text.length != 6) {
      setState(() {
        _errorMessage = 'Mã xác thực phải có 6 chữ số';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await TwoFactorService.loginWith2FA(
        email: widget.email,
        password: widget.password,
        totpCode: _codeController.text,
      );
      
      // Update auth state
      final user = models.User.fromJson({
        'id': response.user.id,
        'email': response.user.email,
        'displayName': response.user.displayName,
        'role': response.user.role,
        'bioAuthEnabled': response.user.twoFactorEnabled,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      ref.read(authProvider.notifier).setAuthState(
        user,
        response.token,
      );
      
      // Navigate to home
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Xác thực 2 lớp',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
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
                    'Xác thực 2 lớp',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhập mã từ Google Authenticator cho ${widget.email}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Instructions
            const Text(
              'Hướng dẫn:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildInstruction(
              Icons.phone_android,
              'Mở Google Authenticator',
              'Trên điện thoại của bạn',
            ),
            
            const SizedBox(height: 12),
            
            _buildInstruction(
              Icons.lock,
              'Tìm mã 6 chữ số',
              'Mã thay đổi mỗi 30 giây',
            ),
            
            const SizedBox(height: 12),
            
            _buildInstruction(
              Icons.keyboard,
              'Nhập mã vào đây',
              'Để hoàn tất đăng nhập',
            ),
            
            const SizedBox(height: 32),
            
            // Code input
            const Text(
              'Mã xác thực:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 24,
                  letterSpacing: 8,
                ),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                counterText: '',
              ),
              onChanged: (value) {
                if (value.length == 6) {
                  _loginWith2FA();
                }
              },
            ),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Login button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loginWith2FA,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Help text
            Center(
              child: Text(
                'Không có Google Authenticator? Tải về từ App Store hoặc Google Play',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.red, size: 24),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
