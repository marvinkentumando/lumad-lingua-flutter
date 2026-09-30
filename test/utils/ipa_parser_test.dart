import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/utils/ipa_parser.dart';

void main() {
  group('IpaParser Tests', () {
    test('TEST 1 — Standard slash-delimited IPA', () {
      final syllables = IpaParser.parseSyllables('/mɐŋ.sɐ.kɐ/');
      expect(syllables, equals(['mɐŋ', 'sɐ', 'kɐ']));
    });

    test('TEST 2 — Bracket-delimited IPA', () {
      final syllables = IpaParser.parseSyllables('[mɐŋ.sɐ.kɐ]');
      expect(syllables, equals(['mɐŋ', 'sɐ', 'kɐ']));
    });

    test('TEST 3 — Hyphen separators', () {
      final syllables = IpaParser.parseSyllables('mɐŋ-sɐ-kɐ');
      expect(syllables, equals(['mɐŋ', 'sɐ', 'kɐ']));
    });

    test('TEST 4 — Space separators', () {
      final syllables = IpaParser.parseSyllables('mɐŋ sɐ kɐ');
      expect(syllables, equals(['mɐŋ', 'sɐ', 'kɐ']));
    });

    test('TEST 5 — Mixed formatting', () {
      final syllables1 = IpaParser.parseSyllables('/[mɐŋ-sɐ.kɐ]/');
      expect(syllables1, equals(['mɐŋ', 'sɐ', 'kɐ']));

      final syllables2 = IpaParser.parseSyllables('/ mɐŋ - sɐ . kɐ /');
      expect(syllables2, equals(['mɐŋ', 'sɐ', 'kɐ']));
    });

    test('TEST 6 — IPA symbol descriptions', () {
      final descGlottal = IpaParser.getSymbolDescription('ʔ');
      expect(descGlottal, isNotNull);
      expect(descGlottal, contains('glottal stop'));

      final descSchwa = IpaParser.getSymbolDescription('ə');
      expect(descSchwa, isNotNull);
      expect(descSchwa, contains('schwa'));

      final descNasal = IpaParser.getSymbolDescription('ŋ');
      expect(descNasal, isNotNull);
      expect(descNasal, contains('ng sound'));

      final descTap = IpaParser.getSymbolDescription('ɾ');
      expect(descTap, isNotNull);
      expect(descTap, contains('tap or flap'));
    });

    test('TEST 7 — Common vowel symbols', () {
      final descA = IpaParser.getSymbolDescription('a');
      expect(descA, isNotNull);
      expect(descA, contains('father'));

      final descI = IpaParser.getSymbolDescription('i');
      expect(descI, isNotNull);
      expect(descI, contains('see'));

      final descU = IpaParser.getSymbolDescription('u');
      expect(descU, isNotNull);
      expect(descU, contains('boot'));
    });

    test('TEST 8 — Missing phonetic value', () {
      expect(IpaParser.clean(null), isEmpty);
      expect(IpaParser.clean(''), isEmpty);
      expect(IpaParser.clean(' / '), isEmpty);
      expect(IpaParser.clean('[ ]'), isEmpty);
      expect(IpaParser.clean('   '), isEmpty);

      expect(IpaParser.parseSyllables(null), isEmpty);
      expect(IpaParser.parseSyllables(''), isEmpty);
      expect(IpaParser.parseSyllables('/'), isEmpty);
      expect(IpaParser.parseSyllables('[ ]'), isEmpty);
      expect(IpaParser.parseSyllables('   '), isEmpty);
    });

    test('TEST 9 — No arbitrary 3-character fallback', () {
      const unformatted = 'mɐŋsɐkɐ';
      final syllables = IpaParser.parseSyllables(unformatted);
      expect(syllables, equals(['mɐŋsɐkɐ']));
      expect(syllables.length, equals(1));
    });

    test('TEST 10 — Unicode preservation', () {
      const unicodeIpa = '/ŋ.ʔ.ə.ɾ.ɐ.ʊ/';
      final cleaned = IpaParser.clean(unicodeIpa);
      expect(cleaned, equals('ŋ.ʔ.ə.ɾ.ɐ.ʊ'));

      final syllables = IpaParser.parseSyllables(unicodeIpa);
      expect(syllables, equals(['ŋ', 'ʔ', 'ə', 'ɾ', 'ɐ', 'ʊ']));
    });

    test('TEST 11 — Unsupported symbol', () {
      expect(() => IpaParser.getSymbolDescription('ð'), returnsNormally);
      expect(IpaParser.getSymbolDescription('ð'), isNull);

      expect(() => IpaParser.getSymbolDescription('x'), returnsNormally);
      expect(IpaParser.getSymbolDescription('x'), isNull);
    });

    test('TEST 12 — Symbol extraction and syllable symbol descriptions', () {
      final symbols = IpaParser.extractSymbols('/mɐŋ/');
      expect(symbols, equals(['m', 'ɐ', 'ŋ']));

      final map = IpaParser.getSymbolDescriptionsForSyllable('mɐŋ');
      expect(map.keys, containsAll(['m', 'ɐ', 'ŋ']));
      expect(map['ŋ'], contains('ng sound'));
    });
  });
}
