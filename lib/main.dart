import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/translation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  
  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Set preferred orientations - Allow all orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize translation service
  try {
    await TranslationService().initialize();
    // Translation service initialized
  } catch (e) {
    print('⚠️  Translation service initialization failed: $e');
    // Continue without translation service
  }

  runApp(
    const ProviderScope(
      child: MoviePlusApp(),
    ),
  );
}