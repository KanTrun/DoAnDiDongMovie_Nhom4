class SpellCorrectionService {

  // Common movie-related terms and their corrections
  static final Map<String, String> _movieCorrections = {
    // Superhero movies
    'avenger': 'avengers',
    'avengers': 'avengers',
    'spiderman': 'spider-man',
    'spider man': 'spider-man',
    'batman': 'batman',
    'superman': 'superman',
    'ironman': 'iron man',
    'iron man': 'iron man',
    'thor': 'thor',
    'captain america': 'captain america',
    'black widow': 'black widow',
    'wonder woman': 'wonder woman',
    'hulk': 'hulk',
    'deadpool': 'deadpool',
    'wolverine': 'wolverine',
    'x-men': 'x-men',
    'xmen': 'x-men',
    
    // Action movies
    'fast and furious': 'fast & furious',
    'fast furious': 'fast & furious',
    'transformers': 'transformers',
    'terminator': 'terminator',
    'rambo': 'rambo',
    'die hard': 'die hard',
    'mission impossible': 'mission: impossible',
    'james bond': 'james bond',
    '007': 'james bond',
    
    // Sci-fi movies
    'matrix': 'matrix',
    'inception': 'inception',
    'interstellar': 'interstellar',
    'avatar': 'avatar',
    'star wars': 'star wars',
    'star trek': 'star trek',
    'blade runner': 'blade runner',
    'alien': 'alien',
    'predator': 'predator',
    
    // Romance/Drama
    'titanic': 'titanic',
    'notebook': 'the notebook',
    'casablanca': 'casablanca',
    'gone with the wind': 'gone with the wind',
    'citizen kane': 'citizen kane',
    
    // Horror
    'exorcist': 'the exorcist',
    'shining': 'the shining',
    'halloween': 'halloween',
    'friday the 13th': 'friday the 13th',
    'nightmare on elm street': 'a nightmare on elm street',
    
    // Comedy
    'hangover': 'the hangover',
    'dumb and dumber': 'dumb and dumber',
    'ace ventura': 'ace ventura',
    'wayne world': 'wayne\'s world',
    
    // Animation
    'toy story': 'toy story',
    'finding nemo': 'finding nemo',
    'shrek': 'shrek',
    'frozen': 'frozen',
    'lion king': 'the lion king',
    'beauty and the beast': 'beauty and the beast',
    
    // Common misspellings
    'recieved': 'received',
    'seperate': 'separate',
    'occured': 'occurred',
    'definately': 'definitely',
    'accomodate': 'accommodate',
    'embarass': 'embarrass',
    'priviledge': 'privilege',
    'maintainance': 'maintenance',
    'neccessary': 'necessary',
    'occassion': 'occasion',
  };

  // Vietnamese movie terms
  static final Map<String, String> _vietnameseCorrections = {
    'phim hanh dong': 'phim hành động',
    'phim tinh cam': 'phim tình cảm',
    'phim hai': 'phim hài',
    'phim kinh di': 'phim kinh dị',
    'phim khoa hoc vien tuong': 'phim khoa học viễn tưởng',
    'phim hoat hinh': 'phim hoạt hình',
    'phim chien tranh': 'phim chiến tranh',
    'phim co trang': 'phim cổ trang',
    'phim than thoai': 'phim thần thoại',
    'phim vo thuat': 'phim võ thuật',
    'phim ca nhac': 'phim ca nhạc',
    'phim tai lieu': 'phim tài liệu',
    'phim gay can': 'phim gay cấn',
    'phim bi an': 'phim bí ẩn',
    'phim lang man': 'phim lãng mạn',
    'phim gia dinh': 'phim gia đình',
    'phim tre em': 'phim trẻ em',
    'phim thanh thieu nien': 'phim thanh thiếu niên',
  };

  /// Auto-correct text with movie-specific corrections
  static Future<String> correctText(String text, {String language = 'vi-VN'}) async {
    if (text.trim().isEmpty) return text;

    String correctedText = text.toLowerCase().trim();
    
    // Apply movie-specific corrections
    if (language == 'vi-VN') {
      correctedText = _applyVietnameseCorrections(correctedText);
    } else {
      correctedText = _applyEnglishCorrections(correctedText);
    }

    // Apply common spelling corrections
    correctedText = _applyCommonCorrections(correctedText);

    // If text is in Vietnamese, try to improve Vietnamese spelling
    if (language == 'vi-VN') {
      correctedText = await _improveVietnameseText(correctedText);
    }

    return correctedText.trim();
  }

  static String _applyEnglishCorrections(String text) {
    String corrected = text;
    
    for (final entry in _movieCorrections.entries) {
      // Check for exact matches and partial matches
      if (corrected.contains(entry.key)) {
        corrected = corrected.replaceAll(entry.key, entry.value);
      }
    }
    
    return corrected;
  }

  static String _applyVietnameseCorrections(String text) {
    String corrected = text;
    
    for (final entry in _vietnameseCorrections.entries) {
      if (corrected.contains(entry.key)) {
        corrected = corrected.replaceAll(entry.key, entry.value);
      }
    }
    
    return corrected;
  }

  static String _applyCommonCorrections(String text) {
    String corrected = text;
    
    // Common English spelling mistakes
    final commonMistakes = {
      'recieved': 'received',
      'seperate': 'separate',
      'occured': 'occurred',
      'definately': 'definitely',
      'accomodate': 'accommodate',
      'embarass': 'embarrass',
      'priviledge': 'privilege',
      'maintainance': 'maintenance',
      'neccessary': 'necessary',
      'occassion': 'occasion',
      'begining': 'beginning',
      'existance': 'existence',
      'independant': 'independent',
      'reccomend': 'recommend',
      'seperate': 'separate',
      'succesful': 'successful',
      'untill': 'until',
      'writting': 'writing',
    };

    for (final entry in commonMistakes.entries) {
      if (corrected.contains(entry.key)) {
        corrected = corrected.replaceAll(entry.key, entry.value);
      }
    }
    
    return corrected;
  }

  static Future<String> _improveVietnameseText(String text) async {
    try {
      // Simple Vietnamese text improvements
      String improved = text;
      
      // Fix common Vietnamese typos
      final vietnameseFixes = {
        'phim hanh dong': 'phim hành động',
        'phim tinh cam': 'phim tình cảm',
        'phim hai': 'phim hài',
        'phim kinh di': 'phim kinh dị',
        'phim khoa hoc': 'phim khoa học',
        'phim vien tuong': 'phim viễn tưởng',
        'phim hoat hinh': 'phim hoạt hình',
        'phim chien tranh': 'phim chiến tranh',
        'phim co trang': 'phim cổ trang',
        'phim than thoai': 'phim thần thoại',
        'phim vo thuat': 'phim võ thuật',
        'phim ca nhac': 'phim ca nhạc',
        'phim tai lieu': 'phim tài liệu',
        'phim gay can': 'phim gay cấn',
        'phim bi an': 'phim bí ẩn',
        'phim lang man': 'phim lãng mạn',
        'phim gia dinh': 'phim gia đình',
        'phim tre em': 'phim trẻ em',
        'phim thanh thieu nien': 'phim thanh thiếu niên',
      };

      for (final entry in vietnameseFixes.entries) {
        if (improved.contains(entry.key)) {
          improved = improved.replaceAll(entry.key, entry.value);
        }
      }

      return improved;
    } catch (e) {
      return text; // Return original if improvement fails
    }
  }

  /// Get suggestions for a given text
  static List<String> getSuggestions(String text) {
    if (text.trim().isEmpty) return [];

    final suggestions = <String>[];
    final lowerText = text.toLowerCase();

    // Add movie title suggestions based on partial matches
    for (final entry in _movieCorrections.entries) {
      if (entry.key.contains(lowerText) || lowerText.contains(entry.key)) {
        suggestions.add(entry.value);
      }
    }

    // Add Vietnamese suggestions
    for (final entry in _vietnameseCorrections.entries) {
      if (entry.key.contains(lowerText) || lowerText.contains(entry.key)) {
        suggestions.add(entry.value);
      }
    }

    return suggestions.take(5).toList();
  }
}
