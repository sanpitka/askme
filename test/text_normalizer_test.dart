import 'package:flutter_test/flutter_test.dart';
import 'package:askme/utils/text_normalizer.dart';

void main() {
  group('TextNormalizer', () {
    test('should normalize basic diacritics correctly', () {
      expect(TextNormalizer.normalize('café'), equals('cafe'));
      expect(TextNormalizer.normalize('naïve'), equals('naive'));
      expect(TextNormalizer.normalize('résumé'), equals('resume'));
    });

    test('should handle European language diacritics', () {
      expect(TextNormalizer.normalize('škola'), equals('skola')); // Czech
      expect(TextNormalizer.normalize('łódź'), equals('lodz')); // Polish
      expect(TextNormalizer.normalize('Zürich'), equals('Zurich')); // German
      expect(TextNormalizer.normalize('København'), equals('Kobenhavn')); // Danish
      expect(TextNormalizer.normalize('Rīga'), equals('Riga')); // Latvian
    });

    test('should handle special characters correctly', () {
      expect(TextNormalizer.normalize('æ'), equals('ae'));
      expect(TextNormalizer.normalize('ß'), equals('ss'));
      expect(TextNormalizer.normalize('Æ'), equals('AE'));
    });

    test('should check equivalence correctly', () {
      expect(TextNormalizer.areEquivalent('café', 'cafe'), isTrue);
      expect(TextNormalizer.areEquivalent('résumé', 'resume'), isTrue);
      expect(TextNormalizer.areEquivalent('hello', 'world'), isFalse);
      expect(TextNormalizer.areEquivalent('CAFÉ', 'cafe'), isTrue); // Case insensitive
    });

    test('should return correct mapping statistics', () {
      expect(TextNormalizer.getMappingCount(), greaterThan(100));
      expect(TextNormalizer.getSupportedDiacritics(), isNotEmpty);
    });

    test('should handle empty and null cases gracefully', () {
      expect(TextNormalizer.normalize(''), equals(''));
      expect(TextNormalizer.areEquivalent('', ''), isTrue);
      expect(TextNormalizer.areEquivalent('', 'test'), isFalse);
    });
  });
}
