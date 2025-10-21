import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/two_factor_service.dart';
import '../../../core/providers/auth_provider.dart';
import 'verify_2fa_screen.dart';

class Enable2FAScreen extends ConsumerStatefulWidget {
  const Enable2FAScreen({super.key});

  @override
  ConsumerState<Enable2FAScreen> createState() => _Enable2FAScreenState();
}

class _Enable2FAScreenState extends ConsumerState<Enable2FAScreen> {
  bool _isLoading = false;
  String? _qrCodeData;
  String? _manualEntryKey;

  @override
  void initState() {
    super.initState();
    _enable2FA();
  }

  Future<void> _enable2FA() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 DEBUG: Đang gọi enable2FA...');
      
      // Kiểm tra authentication trước
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        throw Exception('Bạn cần đăng nhập để bật xác thực 2 lớp');
      }
      
      print('✅ DEBUG: User đã đăng nhập, token: ${authState.token?.substring(0, 20)}...');
      
      final response = await TwoFactorService.enable2FA();
      print('✅ DEBUG: Response received: ${response.toString()}');
      print('🔍 DEBUG: QR Code data: ${response.qrCodeBase64}');
      print('🔍 DEBUG: Manual key: ${response.manualEntryKey}');
      
      setState(() {
        _qrCodeData = response.qrCodeBase64;
        _manualEntryKey = response.manualEntryKey;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ DEBUG: Error in enable2FA: $e');
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
          'Bật xác thực 2 lớp',
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
              physics: const BouncingScrollPhysics(),
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
                          'Bảo mật tài khoản của bạn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Xác thực 2 lớp giúp bảo vệ tài khoản của bạn khỏi các mối đe dọa bảo mật',
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
                  
                  // Instructions
                  const Text(
                    'Cách thiết lập:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildStep(
                    '1',
                    'Tải ứng dụng Google Authenticator',
                    'Tải và cài đặt Google Authenticator từ App Store hoặc Google Play',
                    Icons.download,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildStep(
                    '2',
                    'Quét mã QR',
                    'Mở Google Authenticator và quét mã QR bên dưới',
                    Icons.qr_code_scanner,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // QR Code
                  if (_qrCodeData != null) ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _buildQRCode(_qrCodeData!),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Manual entry
                    Container(
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
                            'Hoặc nhập thủ công:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _manualEntryKey ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Verify2FAScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Tiếp tục',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildQRCode(String qrCodeData) {
    try {
      // Decode base64 to get the QR code text
      final bytes = base64Decode(qrCodeData);
      final qrData = String.fromCharCodes(bytes);
      
      print('🔍 DEBUG: QR Code data: $qrData');
      
      return QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: 200.0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        errorStateBuilder: (context, error) {
          return Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 32),
                const SizedBox(height: 8),
                Text(
                  'QR Error',
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
                Text(
                  error.toString(),
                  style: TextStyle(color: Colors.red[500], fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('❌ DEBUG: QR Code error: $e');
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.grey, size: 32),
            const SizedBox(height: 8),
            const Text(
              'QR Code\nError',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            Text(
              e.toString(),
              style: const TextStyle(color: Colors.grey, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStep(String number, String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
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
