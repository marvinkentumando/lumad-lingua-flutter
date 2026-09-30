import 'package:flutter/widgets.dart';

/// Utility class for cleaning, parsing, and retrieving educational guides
/// for International Phonetic Alphabet (IPA) transcriptions.
class IpaParser {
  const IpaParser._();

  static const Map<String, String> _symbolDescriptions = {
    // Core required symbols
    'ʔ': "glottal stop, like the brief catch in the throat",
    'ə': "schwa sound, like the 'a' in 'about'",
    'ŋ': "ng sound as in 'sing'",
    'ɾ': "tap or flap r, like the 'tt' in 'butter'",
    'a': "open front unrounded vowel, as in 'father'",
    'i': "close front unrounded vowel, as in 'see'",
    'u': "close back rounded vowel, as in 'boot'",

    // Additional common IPA symbols
    'ɐ': "near-open central vowel, as in 'cup'",
    'ʊ': "near-close near-back rounded vowel, as in 'put'",
    'ɪ': "near-close near-front unrounded vowel, as in 'sit'",
    'e': "close-mid front unrounded vowel, as in 'pet'",
    'o': "close-mid back rounded vowel, as in 'go'",
    'ɛ': "open-mid front unrounded vowel, as in 'bed'",
    'ɔ': "open-mid back rounded vowel, as in 'thought'",

    // Consonants
    'b': "voiced bilabial stop, as in 'bat'",
    'd': "voiced alveolar stop, as in 'dog'",
    'g': "voiced velar stop, as in 'go'",
    'ɡ': "voiced velar stop, as in 'go'",
    'h': "voiceless glottal fricative, as in 'hat'",
    'k': "voiceless velar stop, as in 'cat'",
    'l': "alveolar lateral approximant, as in 'light'",
    'm': "bilabial nasal, as in 'man'",
    'n': "alveolar nasal, as in 'net'",
    'p': "voiceless bilabial stop, as in 'pat'",
    's': "voiceless alveolar fricative, as in 'sun'",
    't': "voiceless alveolar stop, as in 'top'",
    'w': "voiced labial-velar approximant, as in 'win'",
    'j': "voiced palatal approximant, like the 'y' in 'yes'",
    'r': "alveolar trill or approximant, as in 'run'",
  };

  /// Cleans raw IPA input by stripping surrounding slashes, brackets, and trimming whitespace.
  ///
  /// Examples:
  /// - `"/mɐŋ.sɐ.kɐ/"` -> `"mɐŋ.sɐ.kɐ"`
  /// - `"[mɐŋ.sɐ.kɐ]"` -> `"mɐŋ.sɐ.kɐ"`
  /// - `null` / `"/"` / `"[ ]"` -> `""`
  static String clean(String? rawIpa) {
    if (rawIpa == null) return '';
    var cleaned = rawIpa.trim();
    if (cleaned.isEmpty) return '';

    // Strip matched surrounding slashes or brackets
    while (cleaned.length >= 2 &&
        ((cleaned.startsWith('/') && cleaned.endsWith('/')) ||
            (cleaned.startsWith('[') && cleaned.endsWith(']')))) {
      cleaned = cleaned.substring(1, cleaned.length - 1).trim();
    }

    // Strip remaining isolated leading or trailing delimiters
    if (cleaned.startsWith('/') || cleaned.startsWith('[')) {
      cleaned = cleaned.substring(1).trim();
    }
    if (cleaned.endsWith('/') || cleaned.endsWith(']')) {
      cleaned = cleaned.substring(0, cleaned.length - 1).trim();
    }

    return cleaned;
  }

  /// Parses an IPA string into individual syllable units.
  ///
  /// Recognizes syllable boundary delimiters (`.`, `-`, and whitespace).
  /// If no explicit syllable boundary is encoded, preserves the cleaned string as a single unit
  /// rather than fabricating arbitrary syllable boundaries.
  ///
  /// Examples:
  /// - `"/mɐŋ.sɐ.kɐ/"` -> `["mɐŋ", "sɐ", "kɐ"]`
  /// - `"mɐŋ-sɐ-kɐ"`    -> `["mɐŋ", "sɐ", "kɐ"]`
  /// - `"mɐŋ sɐ kɐ"`    -> `["mɐŋ", "sɐ", "kɐ"]`
  /// - `"mɐŋsɐkɐ"`      -> `["mɐŋsɐkɐ"]`
  /// - `null` / `""`    -> `[]`
  static List<String> parseSyllables(String? rawIpa) {
    final cleaned = clean(rawIpa);
    if (cleaned.isEmpty) return const [];

    final delimiterRegex = RegExp(r'[.\-\s]+');
    if (delimiterRegex.hasMatch(cleaned)) {
      return cleaned
          .split(delimiterRegex)
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return [cleaned];
  }

  /// Returns a beginner-friendly description for a given IPA symbol.
  ///
  /// Returns `null` if the symbol is null, empty, or unsupported.
  static String? getSymbolDescription(String? symbol) {
    if (symbol == null || symbol.trim().isEmpty) return null;
    return _symbolDescriptions[symbol.trim()];
  }

  /// Extracts distinct IPA symbols present in the provided [text],
  /// preserving order of appearance and handling Unicode characters safely.
  static List<String> extractSymbols(String? text) {
    final cleaned = clean(text);
    if (cleaned.isEmpty) return const [];

    final List<String> symbols = [];
    for (final char in cleaned.characters) {
      if (char == '.' || char == '-' || char == ' ' || char == '/' || char == '[' || char == ']') {
        continue;
      }
      if (!symbols.contains(char)) {
        symbols.add(char);
      }
    }
    return symbols;
  }

  /// Returns a map of recognized symbols to their educational descriptions for a given [syllable].
  static Map<String, String> getSymbolDescriptionsForSyllable(String? syllable) {
    final symbols = extractSymbols(syllable);
    final Map<String, String> result = {};
    for (final sym in symbols) {
      final desc = getSymbolDescription(sym);
      if (desc != null) {
        result[sym] = desc;
      }
    }
    return result;
  }

  /// Unmodifiable view of all supported IPA symbol descriptions.
  static Map<String, String> get supportedSymbols => Map.unmodifiable(_symbolDescriptions);
}
