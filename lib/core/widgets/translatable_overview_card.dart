import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class TranslatableOverviewCard extends StatefulWidget {
  final String overview;
  final String? overviewVi;
  final TranslationService translationService;

  const TranslatableOverviewCard({
    super.key,
    required this.overview,
    this.overviewVi,
    required this.translationService,
  });

  @override
  State<TranslatableOverviewCard> createState() => _TranslatableOverviewCardState();
}

class _TranslatableOverviewCardState extends State<TranslatableOverviewCard> {
  String? _translatedOverview;
  bool _isTranslating = false;
  bool _hasTriedTranslation = false;

  @override
  void initState() {
    super.initState();
    _autoTranslateIfNeeded();
  }

  Future<void> _autoTranslateIfNeeded() async {
    // Only auto-translate if we don't have Vietnamese overview and have English overview
    if (widget.overviewVi?.isNotEmpty == true) {
      return; // Already have Vietnamese
    }
    
    if (widget.overview.isEmpty) {
      return; // No overview to translate
    }
    
    // Prevent multiple translation attempts
    if (_hasTriedTranslation) {
      return;
    }
    
    setState(() {
      _hasTriedTranslation = true;
      _isTranslating = true;
    });

    try {
      print('🔄 Auto-translating overview: "${widget.overview.substring(0, widget.overview.length > 50 ? 50 : widget.overview.length)}..."');
      
      final translated = await widget.translationService.translateToVietnamese(widget.overview);
      
      if (mounted) {
        setState(() {
          _translatedOverview = translated;
          _isTranslating = false;
        });
        
        print('✅ Auto-translation completed: "${translated.substring(0, translated.length > 50 ? 50 : translated.length)}..."');
      }
    } catch (e) {
      print('❌ Auto-translation failed: $e');
      if (mounted) {
        setState(() {
          _isTranslating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Priority: overviewVi > _translatedOverview > overview > "Không có mô tả"
    String displayText = 'Không có mô tả';
    
    if (widget.overviewVi?.isNotEmpty == true) {
      displayText = widget.overviewVi!;
    } else if (_translatedOverview?.isNotEmpty == true) {
      displayText = _translatedOverview!;
    } else if (widget.overview.isNotEmpty) {
      displayText = widget.overview;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            displayText,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 12,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_isTranslating)
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
              ),
            ),
          ),
      ],
    );
  }
}
