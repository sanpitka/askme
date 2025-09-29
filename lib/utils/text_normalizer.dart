/// Utility functions for text normalization and diacritic handling
/// 
/// This file contains comprehensive diacritic mappings for European languages
/// using the Latin alphabet, making text comparison more lenient and user-friendly.

library;

class TextNormalizer {
  /// Comprehensive diacritic map covering most European languages
  static const Map<String, String> _diacriticMap = {
    // Basic Latin with diacritics - Vowels
    'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ā': 'a', 'ă': 'a', 'ą': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ė': 'e', 'ę': 'e', 'ě': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', 'į': 'i', 'ı': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ő': 'o', 'ō': 'o', 'ø': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ű': 'u', 'ū': 'u', 'ų': 'u', 'ů': 'u',
    'ý': 'y', 'ÿ': 'y',
    
    // Consonants with diacritics
    'ç': 'c', 'ć': 'c', 'č': 'c', 'ĉ': 'c',
    'ď': 'd', 'đ': 'd', 'ð': 'd',
    'ğ': 'g', 'ģ': 'g',
    'ķ': 'k',
    'ł': 'l', 'ļ': 'l', 'ľ': 'l',
    'ń': 'n', 'ň': 'n', 'ñ': 'n', 'ņ': 'n',
    'ř': 'r',
    'ś': 's', 'š': 's', 'ş': 's', 'ș': 's',
    'ť': 't', 'ț': 't', 'þ': 't',
    'ź': 'z', 'ž': 'z', 'ż': 'z',
    
    // Special characters
    'æ': 'ae',
    'ß': 'ss',
    
    // Uppercase versions - Vowels
    'Á': 'A', 'À': 'A', 'Â': 'A', 'Ä': 'A', 'Ã': 'A', 'Å': 'A', 'Ā': 'A', 'Ă': 'A', 'Ą': 'A',
    'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E', 'Ē': 'E', 'Ė': 'E', 'Ę': 'E', 'Ě': 'E',
    'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I', 'Ī': 'I', 'Į': 'I', 'İ': 'I',
    'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Ö': 'O', 'Õ': 'O', 'Ő': 'O', 'Ō': 'O', 'Ø': 'O',
    'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U', 'Ű': 'U', 'Ū': 'U', 'Ų': 'U', 'Ů': 'U',
    'Ý': 'Y', 'Ÿ': 'Y',
    
    // Uppercase consonants
    'Ç': 'C', 'Ć': 'C', 'Č': 'C', 'Ĉ': 'C',
    'Ď': 'D', 'Đ': 'D', 'Ð': 'D',
    'Ğ': 'G', 'Ģ': 'G',
    'Ķ': 'K',
    'Ł': 'L', 'Ļ': 'L', 'Ľ': 'L',
    'Ń': 'N', 'Ň': 'N', 'Ñ': 'N', 'Ņ': 'N',
    'Ř': 'R',
    'Ś': 'S', 'Š': 'S', 'Ş': 'S', 'Ș': 'S',
    'Ť': 'T', 'Ț': 'T', 'Þ': 'T',
    'Ź': 'Z', 'Ž': 'Z', 'Ż': 'Z',
    
    'Æ': 'AE',
  };

  /// Normalizes text by removing diacritics/accents for more lenient comparison
  /// 
  /// This function is particularly useful for language learning applications
  /// where users might not have access to special keyboard layouts or might
  /// make minor diacritic mistakes.
  /// 
  /// Supports most European languages including:
  /// - Germanic: German, English, Dutch, Swedish, Danish, Norwegian, Icelandic
  /// - Romance: Spanish, French, Italian, Portuguese, Romanian
  /// - Slavic: Polish, Czech, Slovak, Croatian, Serbian, Slovenian
  /// - Baltic: Lithuanian, Latvian
  /// - Finno-Ugric: Finnish, Hungarian
  /// - Turkic: Turkish
  /// 
  /// Example:
  /// ```dart
  /// TextNormalizer.normalize('café') // returns 'cafe'
  /// TextNormalizer.normalize('naïve') // returns 'naive'
  /// TextNormalizer.normalize('résumé') // returns 'resume'
  /// ```
  static String normalize(String text) {
    String normalized = text;
    _diacriticMap.forEach((accented, normal) {
      normalized = normalized.replaceAll(accented, normal);
    });
    return normalized;
  }

  /// Checks if two strings are equivalent when diacritics are ignored
  /// 
  /// Example:
  /// ```dart
  /// TextNormalizer.areEquivalent('café', 'cafe') // returns true
  /// TextNormalizer.areEquivalent('résumé', 'resume') // returns true
  /// ```
  static bool areEquivalent(String text1, String text2) {
    return normalize(text1.toLowerCase()) == normalize(text2.toLowerCase());
  }

  /// Returns a list of all supported diacritic characters
  /// Useful for documentation or testing purposes
  static List<String> getSupportedDiacritics() {
    return _diacriticMap.keys.toList()..sort();
  }

  /// Returns the number of supported diacritic mappings
  static int getMappingCount() {
    return _diacriticMap.length;
  }
}
