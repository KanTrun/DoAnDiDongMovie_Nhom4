import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/two_factor_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _gradientController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation cho gradient background
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    // Animation cho fade in
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _fadeController.forward();
    _maybeShowBiometricHint();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _gradientController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted && ref.read(isAuthenticatedProvider)) {
        // Check if user has 2FA enabled by calling API
        try {
          final authState = ref.read(authProvider);
          print('🔍 DEBUG: Checking 2FA status for user: ${authState.user?.email}');
          
          // Call API to check actual 2FA status
          final twoFAStatus = await TwoFactorService.get2FAStatus();
          print('🔍 DEBUG: 2FA status: ${twoFAStatus.twoFactorEnabled}');
          
          if (twoFAStatus.twoFactorEnabled) {
            // User has 2FA enabled, navigate to 2FA screen
            context.push('/login-with-2fa', extra: {
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
            });
          } else {
            // Normal login, go to home
            context.go('/home');
          }
        } catch (e) {
          print('❌ DEBUG: Error checking 2FA status: $e');
          // If error checking 2FA, assume no 2FA and go to home
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thất bại: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFE50914),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _maybeShowBiometricHint() async {
    final localAuth = LocalAuthentication();
    try {
      final supported = await localAuth.isDeviceSupported();
      final canCheck = await localAuth.canCheckBiometrics;
      if (!mounted || !supported || !canCheck) return;
    } catch (_) {
      return;
    }
  }

  Future<void> _loginWithBiometrics() async {
    if (!mounted) return;
    final result = await ref.read(authProvider.notifier).loginWithBiometrics();
    
    if (result['success'] == true && mounted && ref.read(isAuthenticatedProvider)) {
      context.go('/home');
    } else if (result['needs2FA'] == true && mounted) {
      // Cần xác thực 2FA sau khi đăng nhập vân tay thành công
      context.push('/biometric-2fa');
    } else if (result['needsSelection'] == true && mounted) {
      // Hiển thị dialog chọn tài khoản
      await _showAccountSelectionDialog(result['accounts'], result['template']);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Xác thực sinh trắc học thất bại. Vui lòng đăng ký vân tay trước.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFE50914),
        ),
      );
    }
  }

  // Hiển thị dialog chọn tài khoản
  Future<void> _showAccountSelectionDialog(List accounts, String template) async {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Chọn tài khoản',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Có nhiều tài khoản sử dụng cùng vân tay. Vui lòng chọn tài khoản muốn đăng nhập:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...accounts.asMap().entries.map((entry) {
              final index = entry.key;
              final account = entry.value;
              final email = account['Email'] ?? account['email'] ?? 'Unknown';
              final displayName = account['DisplayName'] ?? account['displayName'] ?? 'User';
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  displayName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _loginWithSelectedAccount(account, template);
                },
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  // Đăng nhập với tài khoản đã chọn
  Future<void> _loginWithSelectedAccount(Map account, String template) async {
    if (!mounted) return;
    
    try {
      final accountId = account['Id'] ?? account['id'] ?? account['userId'];
      if (accountId != null) {
        final response = await ref.read(authProvider.notifier).loginWithSelectedAccount(template, accountId);
        
        if (response['success'] == true && mounted && ref.read(isAuthenticatedProvider)) {
          context.go('/home');
        } else if (response['needs2FA'] == true && mounted) {
          // Cần xác thực 2FA sau khi đăng nhập vân tay thành công
          context.push('/biometric-2fa');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['error'] ?? 'Lỗi đăng nhập'),
              backgroundColor: const Color(0xFFE50914),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng nhập: $e'),
            backgroundColor: const Color(0xFFE50914),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Stack(
        children: [
          // Animated Gradient Background
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: const [
                      Color(0xFF141414),
                      Color(0xFF2D0A0E),
                      Color(0xFF1A0308),
                      Color(0xFF0D0D0D),
                    ],
                    stops: [
                      0.0,
                      _gradientController.value * 0.5,
                      _gradientController.value,
                      1.0,
                    ],
                    transform: GradientRotation(_gradientController.value * 2 * math.pi),
                  ),
                ),
              );
            },
          ),
          
          // Floating animated circles
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedBuilder(
              animation: _gradientController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    math.sin(_gradientController.value * 2 * math.pi) * 20,
                    math.cos(_gradientController.value * 2 * math.pi) * 20,
                  ),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFE50914).withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Positioned(
            bottom: -150,
            left: -150,
            child: AnimatedBuilder(
              animation: _gradientController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    math.cos(_gradientController.value * 2 * math.pi) * 30,
                    math.sin(_gradientController.value * 2 * math.pi) * 30,
                  ),
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFB81D24).withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Main content with fade animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo với animation
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFE50914),
                                Color(0xFFB81D24),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE50914).withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.movie,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFE50914),
                            Color(0xFFFF6B6B),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'MoviePlus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 50),
                      
                      // Glassmorphism Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Email field
                                  _buildGlassTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Vui lòng nhập email';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Email không hợp lệ';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Password field
                                  _buildGlassTextField(
                                    controller: _passwordController,
                                    label: 'Mật khẩu',
                                    icon: Icons.lock_outline,
                                    obscureText: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Vui lòng nhập mật khẩu';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 35),
                                  
                                  // Login button với gradient animation
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFE50914),
                                          Color(0xFFB81D24),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFE50914).withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: isLoading ? null : _login,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Center(
                                          child: isLoading
                                              ? const SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2.5,
                                                  ),
                                                )
                                              : const Text(
                                                  'Đăng nhập',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Biometric button
                                  SizedBox(
                                    height: 56,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.white.withOpacity(0.25)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: isLoading ? null : _loginWithBiometrics,
                                      icon: const Icon(Icons.fingerprint, size: 24),
                                      label: const Text(
                                        'Đăng nhập bằng vân tay / Face ID',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Biometric help text
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, color: Colors.blue, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Cần đăng ký vân tay trước trong Profile',
                                            style: TextStyle(
                                              color: Colors.blue[300],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Chưa có tài khoản? ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 15,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFE50914),
                                  Color(0xFFFF6B6B),
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'Đăng ký ngay',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.04),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFFE50914).withOpacity(0.8),
            size: 22,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFE50914),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.red.shade300,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          errorStyle: const TextStyle(
            color: Colors.redAccent,
            fontSize: 12,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        validator: validator,
      ),
    );
  }
}
