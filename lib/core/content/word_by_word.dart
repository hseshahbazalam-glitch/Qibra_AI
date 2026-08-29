// Word-by-word glosses. UNKNOWN stays UNKNOWN.
// Do not invent meanings. There is no licensed word corpus in this repo.

class WordGloss {
  const WordGloss({required this.token, required this.gloss});

  final String token;
  final String gloss;

  bool get isUnknown => gloss == 'UNKNOWN';

  static const unknownLabel = 'UNKNOWN';
}

abstract final class WordByWordResolver {
  /// Split Arabic ayah text into display tokens. No meaning is invented.
  static List<WordGloss> tokenize(String ayahText) {
    return ayahText
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .map((token) => WordGloss(token: token, gloss: WordGloss.unknownLabel))
        .toList();
  }

  static String glossFor(String token) => WordGloss.unknownLabel;
}
