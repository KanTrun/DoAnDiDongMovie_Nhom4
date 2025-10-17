import 'dart:async';
import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class SubtitleOverlay extends StatefulWidget {
  final bool isEnabled;
  final VoidCallback? onToggle;
  final VoidCallback? onClear;

  const SubtitleOverlay({
    Key? key,
    required this.isEnabled,
    this.onToggle,
    this.onClear,
  }) : super(key: key);

  @override
  State<SubtitleOverlay> createState() => _SubtitleOverlayState();
}

class _SubtitleOverlayState extends State<SubtitleOverlay>
    with TickerProviderStateMixin {
  final TranslationService _translationService = TranslationService();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  StreamSubscription<String>? _originalTextSubscription;
  StreamSubscription<String>? _translatedTextSubscription;

  String _originalText = '';
  String _translatedText = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTranslationService();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _initializeTranslationService() async {
    final success = await _translationService.initialize();
    if (success) {
      setState(() {
        _isInitialized = true;
      });
      _setupStreams();
    }
  }

  void _setupStreams() {
    _originalTextSubscription = _translationService.originalTextStream.listen(
      (text) {
        setState(() {
          _originalText = text;
        });
        _animateText();
      },
    );

    _translatedTextSubscription = _translationService.translatedTextStream.listen(
      (text) {
        setState(() {
          _translatedText = text;
        });
        _animateText();
      },
    );
  }

  void _animateText() {
    if (_originalText.isNotEmpty || _translatedText.isNotEmpty) {
      _fadeController.forward();
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    _originalTextSubscription?.cancel();
    _translatedTextSubscription?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled || !_isInitialized) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: Listenable.merge([_fadeAnimation, _slideAnimation]),
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildSubtitleCard(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubtitleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with controls
          Row(
            children: [
              Icon(
                Icons.translate,
                color: Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Dịch thời gian thực',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_originalText.isNotEmpty || _translatedText.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white, size: 18),
                  onPressed: () {
                    _translationService.clearText();
                    setState(() {
                      _originalText = '';
                      _translatedText = '';
                    });
                    _fadeController.reverse();
                    _slideController.reverse();
                    widget.onClear?.call();
                  },
                  tooltip: 'Xóa phụ đề',
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Original text (if available)
          if (_originalText.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900]?.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!, width: 1),
              ),
              child: Text(
                _originalText,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Translated text
          if (_translatedText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
              ),
              child: Text(
                _translatedText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          
          // Status indicator
          if (_originalText.isEmpty && _translatedText.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đang nghe...',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
