import 'dart:async';
import 'package:flutter/foundation.dart';
// import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';
// import 'package:permission_handler/permission_handler.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  // final SpeechToText _speechToText = SpeechToText();
  final GoogleTranslator _translator = GoogleTranslator();
  
  bool _isListening = false;
  bool _isInitialized = false;
  String _currentText = '';
  String _translatedText = '';
  
  // Stream controllers for real-time updates
  final StreamController<String> _originalTextController = StreamController<String>.broadcast();
  final StreamController<String> _translatedTextController = StreamController<String>.broadcast();
  
  // Getters
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get currentText => _currentText;
  String get translatedText => _translatedText;
  
  // Streams
  Stream<String> get originalTextStream => _originalTextController.stream;
  Stream<String> get translatedTextStream => _translatedTextController.stream;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    try {
      // Temporarily disabled speech recognition
      _isInitialized = true;
      // Translation service initialized (speech disabled)
      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing translation service: $e');
      return false;
    }
  }

  /// Start listening for speech
  Future<void> startListening() async {
    if (!_isInitialized) {
      debugPrint('Translation service not initialized');
      return;
    }

    if (_isListening) {
      debugPrint('Already listening');
      return;
    }

    try {
      // Temporarily disabled - just simulate listening
      _isListening = true;
      debugPrint('🎤 Started listening for speech (simulated)');
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      // Temporarily disabled
      _isListening = false;
      debugPrint('🛑 Stopped listening for speech (simulated)');
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
    }
  }


  /// Manual translation (for testing)
  Future<String> translateText(String text) async {
    if (text.isEmpty) return '';

    try {
      debugPrint('🔄 Translating text: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');
      final translation = await _translator.translate(
        text,
        from: 'auto',
        to: 'vi',
      );
      // Translation completed
      return translation.text;
    } catch (e) {
      // Translation error
      return text; // Return original text if translation fails
    }
  }

  /// Translate to Vietnamese (alias for translateText)
  Future<String> translateToVietnamese(String text) async {
    return await translateText(text);
  }

  /// Clear all text
  void clearText() {
    _currentText = '';
    _translatedText = '';
    _originalTextController.add('');
    _translatedTextController.add('');
  }

  /// Dispose resources
  void dispose() {
    // _speechToText.stop();
    _originalTextController.close();
    _translatedTextController.close();
  }
}