import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/spell_correction_service.dart';

class SpeechToTextWidget extends StatefulWidget {
  final Function(String) onTextRecognized;
  final String? initialText;
  final bool isEnabled;

  const SpeechToTextWidget({
    super.key,
    required this.onTextRecognized,
    this.initialText,
    this.isEnabled = true,
  });

  @override
  State<SpeechToTextWidget> createState() => _SpeechToTextWidgetState();
}

class _SpeechToTextWidgetState extends State<SpeechToTextWidget>
    with TickerProviderStateMixin {
  late SpeechToText _speechToText;
  bool _isListening = false;
  bool _isAvailable = false;
  String _recognizedText = '';
  String _selectedLanguage = 'vi_VN'; // User selected language
  String _currentLanguage = 'vi_VN'; // Currently active language
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  final Map<String, String> _supportedLanguages = {
    'vi_VN': 'Tiếng Việt',
    'en_US': 'English',
  };

  @override
  void initState() {
    super.initState();
    _speechToText = SpeechToText();
    _initializeSpeech();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeSpeech() async {
    try {
      _isAvailable = await _speechToText.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          setState(() {
            _isListening = status == 'listening';
          });
        },
        onError: (error) {
          print('Speech error: ${error.errorMsg}');
          setState(() {
            _isListening = false;
          });
          _showErrorSnackBar('Lỗi nhận dạng giọng nói: ${error.errorMsg}');
        },
      );

      print('Speech available: $_isAvailable');
      if (_isAvailable) {
        // Check supported languages and set fallback
        final locales = await _speechToText.locales();
        print('Available locales: ${locales.map((e) => e.localeId).toList()}');
        print('Total locales count: ${locales.length}');
        
        final isVietnameseSupported = locales.any((locale) => locale.localeId == 'vi_VN');
        final isEnglishSupported = locales.any((locale) => locale.localeId == 'en_US');
        
        if (isVietnameseSupported) {
          _currentLanguage = 'vi_VN';
        } else if (isEnglishSupported) {
          _currentLanguage = 'en_US';
        } else {
          // Fallback to first available locale or default
          if (locales.isNotEmpty) {
            _currentLanguage = locales.first.localeId;
          } else {
            // Use system default
            _currentLanguage = 'en_US';
          }
        }
        
        setState(() {});
      } else {
        _showErrorSnackBar('Nhận dạng giọng nói không khả dụng trên thiết bị này');
      }
    } catch (e) {
      print('Speech init error: $e');
      _showErrorSnackBar('Không thể khởi tạo nhận dạng giọng nói: $e');
    }
  }

  Future<void> _startListening() async {
    if (!_isAvailable) {
      _showErrorSnackBar('Nhận dạng giọng nói không khả dụng');
      return;
    }

    // Check and request microphone permission
    print('Checking microphone permission...');
    final permission = await Permission.microphone.request();
    print('Microphone permission: $permission');
    
    if (permission != PermissionStatus.granted) {
      _showErrorSnackBar('Cần quyền truy cập microphone để sử dụng tính năng này');
      return;
    }

    // Use the current language
    String languageToUse = _currentLanguage;
    print('Using language: $languageToUse');

    try {
      _recognizedText = '';
      print('Starting speech recognition with language: $languageToUse');
      print('Current language: $_currentLanguage');
      print('Selected language: $_selectedLanguage');
      
      await _speechToText.listen(
        onResult: (result) {
          print('Speech result: ${result.recognizedWords}');
          print('Final result: ${result.finalResult}');
          setState(() {
            _recognizedText = result.recognizedWords;
          });
          
          // If final result, call callback immediately
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            print('Final result received, calling callback with: "${result.recognizedWords}"');
            _autoCorrectAndCallback(result.recognizedWords);
          }
        },
        localeId: languageToUse,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );

      _animationController.repeat(reverse: true);
    } catch (e) {
      print('Speech listening error: $e');
      _showErrorSnackBar('Lỗi khi bắt đầu nghe: $e');
    }
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    _animationController.stop();
    _animationController.reset();

    print('Stopping listening, recognized text: "$_recognizedText"');
    
    if (_recognizedText.isNotEmpty) {
      // Auto-correct spelling if needed
      final correctedText = await _autoCorrectText(_recognizedText);
      print('Corrected text: "$correctedText"');
      
      // Call the callback to update search field
      widget.onTextRecognized(correctedText);
      
      // Show success message
      _showSuccessSnackBar('Đã nhận dạng: "$correctedText"');
    } else {
      _showErrorSnackBar('Không nhận dạng được giọng nói');
    }
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chọn ngôn ngữ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Vietnamese option
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: _currentLanguage == 'vi_VN'
                      ? const LinearGradient(
                          colors: [Color(0xFFE50914), Color(0xFFB20710)],
                        )
                      : null,
                  color: _currentLanguage == 'vi_VN'
                      ? null
                      : Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.flag,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'Tiếng Việt',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              trailing: _currentLanguage == 'vi_VN'
                  ? const Icon(Icons.check, color: Color(0xFFE50914))
                  : null,
              onTap: () async {
                Navigator.pop(context);
                await _switchLanguage('vi_VN');
              },
            ),
            // English option
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: _currentLanguage == 'en_US'
                      ? const LinearGradient(
                          colors: [Color(0xFFE50914), Color(0xFFB20710)],
                        )
                      : null,
                  color: _currentLanguage == 'en_US'
                      ? null
                      : Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.language,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'English',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              trailing: _currentLanguage == 'en_US'
                  ? const Icon(Icons.check, color: Color(0xFFE50914))
                  : null,
              onTap: () async {
                Navigator.pop(context);
                await _switchLanguage('en_US');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _switchLanguage(String language) async {
    if (!_isAvailable) {
      _showErrorSnackBar('Nhận dạng giọng nói không khả dụng');
      return;
    }

    try {
      // Check if language is supported
      final locales = await _speechToText.locales();
      print('Available locales: ${locales.map((e) => e.localeId).toList()}');
      print('Trying to switch to: $language');
      
      final isLanguageSupported = locales.any((locale) => locale.localeId == language);
      print('Language $language supported: $isLanguageSupported');
      
      if (isLanguageSupported) {
        setState(() {
          _currentLanguage = language;
          _selectedLanguage = language;
        });
        _showSuccessSnackBar('Đã chuyển sang ${language == 'vi_VN' ? 'Tiếng Việt' : 'English'}');
      } else {
        // Try fallback to English if Vietnamese not supported
        if (language == 'vi_VN') {
          final isEnglishSupported = locales.any((locale) => locale.localeId == 'en_US');
          print('English supported: $isEnglishSupported');
          if (isEnglishSupported) {
            setState(() {
              _currentLanguage = 'en_US';
              _selectedLanguage = 'en_US';
            });
            _showErrorSnackBar('Tiếng Việt không được hỗ trợ, đã chuyển sang English');
          } else {
            _showErrorSnackBar('Không có ngôn ngữ nào được hỗ trợ trên thiết bị này');
          }
        } else {
          // For English, try to use any available language
          if (locales.isNotEmpty) {
            final fallbackLanguage = locales.first.localeId;
            setState(() {
              _currentLanguage = fallbackLanguage;
              _selectedLanguage = fallbackLanguage;
            });
            _showErrorSnackBar('English không được hỗ trợ, đã chuyển sang $fallbackLanguage');
          } else {
            _showErrorSnackBar('Không có ngôn ngữ nào được hỗ trợ trên thiết bị này');
          }
        }
      }
    } catch (e) {
      print('Error switching language: $e');
      _showErrorSnackBar('Lỗi khi chuyển đổi ngôn ngữ: $e');
    }
  }

  Future<void> _autoCorrectAndCallback(String text) async {
    try {
      print('Auto-correcting text: "$text"');
      // Use the spell correction service
      final correctedText = await SpellCorrectionService.correctText(
        text,
        language: _currentLanguage,
      );
      
      print('Corrected text: "$correctedText"');
      
      // Call the callback to update search field
      widget.onTextRecognized(correctedText);
      
      // Show success message
      _showSuccessSnackBar('Đã nhận dạng: "$correctedText"');
      
      // Stop listening
      await _speechToText.stop();
      _animationController.stop();
      _animationController.reset();
      setState(() {
        _isListening = false;
      });
    } catch (e) {
      print('Error in auto-correct callback: $e');
      // Still call callback with original text
      widget.onTextRecognized(text);
      _showSuccessSnackBar('Đã nhận dạng: "$text"');
    }
  }

  Future<String> _autoCorrectText(String text) async {
    try {
      // Use the spell correction service
      final correctedText = await SpellCorrectionService.correctText(
        text,
        language: _currentLanguage,
      );
      
      return correctedText;
    } catch (e) {
      return text; // Return original text if correction fails
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }


  @override
  void dispose() {
    _animationController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Language selector button
        GestureDetector(
          onTap: _showLanguageSelector,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _currentLanguage == 'vi_VN' ? Icons.flag : Icons.language,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _currentLanguage == 'vi_VN' ? 'VI' : 'EN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        // Microphone button
        GestureDetector(
          onTap: _isListening ? _stopListening : _startListening,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? _scaleAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: _isListening
                        ? const LinearGradient(
                            colors: [Color(0xFFE50914), Color(0xFFB20710)],
                          )
                        : null,
                    color: _isListening ? null : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isListening
                          ? const Color(0xFFE50914)
                          : Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: const Color(0xFFE50914).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 20,
                      ),
                      if (_isListening)
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: PulsePainter(
                                  progress: _pulseAnimation.value,
                                  color: const Color(0xFFE50914),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class PulsePainter extends CustomPainter {
  final double progress;
  final Color color;

  PulsePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3 * (1 - progress))
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * (1 + progress * 2);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


