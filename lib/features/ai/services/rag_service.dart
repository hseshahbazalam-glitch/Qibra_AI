import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/quran/data/repository/quran_repository.dart';

class RetrievedPassage {
  final String source;
  final String text;
  final double relevance;
  final String collection;
  final String? edition;
  final String? translator;
  final String verificationStatus;
  final String? reference;

  const RetrievedPassage({
    required this.source,
    required this.text,
    required this.relevance,
    required this.collection,
    this.edition,
    this.translator,
    this.verificationStatus = 'UNKNOWN',
    this.reference,
  });

  bool get productionRagEligible => verificationStatus == 'VERIFIED';
}

class RagService {
  RagService._();

  static final RagService instance = RagService._();

  final QuranRepository _quranRepo = QuranRepository();
  HadithDatabaseService? _hadithDb;

  void attachHadithDb(HadithDatabaseService db) {
    _hadithDb = db;
  }

  /// Retrieves local Quran and Hadith passages for a query. Not independently verified.
  Future<List<RetrievedPassage>> retrieve(
    String query, {
    int topK = 3,
  }) async {
    if (query.trim().isEmpty) return [];

    final results = <RetrievedPassage>[];

    try {
      if (_quranRepo.isInitialized) {
        final searchResults = await _quranRepo.search(query);

        for (final result in searchResults.take(topK)) {
          results.add(
            RetrievedPassage(
              source: 'Quran ${result.surahNumber}:${result.ayahNumber}',
              text: '${result.ayahText} — ${result.translation ?? ''}'.trim(),
              relevance: 0.9,
              collection: 'quran',
              verificationStatus: 'UNKNOWN',
              reference: '${result.surahNumber}:${result.ayahNumber}',
            ),
          );
        }
      }
    } catch (_) {
      // Do not log query, Quran text, or exception payloads.
    }

    try {
      final db = _hadithDb;

      if (db != null && db.isInitialized) {
        final hadithResults = db.search(query, maxResults: topK);

        for (final result in hadithResults) {
          results.add(
            RetrievedPassage(
              source: result.hadith.displayReference,
              text: result.hadith.textEnglish,
              relevance: result.relevance,
              collection: 'hadith',
              verificationStatus: 'UNKNOWN',
              reference: result.hadith.displayReference,
            ),
          );
        }
      }
    } catch (_) {
      // Do not log query, Hadith text, or exception payloads.
    }

    results.sort((a, b) => b.relevance.compareTo(a.relevance));

    return results.take(topK).toList();
  }

  /// Builds retrieved-passage context for an AI request. Never invent citations.
  Future<String> buildContextForQuery(String query) async {
    final passages = await retrieve(query, topK: 3);

    if (passages.isEmpty) {
      return 'REFUSE: no retrieved passage. Do not invent Quran or Hadith.';
    }

    final buffer = StringBuffer();

    buffer.writeln(
      'Retrieved local passages (not independently verified). Cite only these:',
    );

    for (var index = 0; index < passages.length; index++) {
      final passage = passages[index];

      buffer.writeln(
        '[${index + 1}] ${passage.source}: ${passage.text}',
      );
    }

    buffer.writeln(
      'If no relevant passage above exists, say you could not find a retrieved '
      'passage and will not invent Quran or Hadith.',
    );

    return buffer.toString();
  }

  /// Returns true only when the response cites at least one source that was
  /// actually retrieved and supplied to the AI.
  bool verifyCitations(
    String answer,
    List<RetrievedPassage> passages,
  ) {
    if (passages.isEmpty) {
      return true;
    }

    final normalizedAnswer = _normalizeCitation(answer);

    return passages.any(
      (passage) =>
          normalizedAnswer.contains(_normalizeCitation(passage.source)),
    );
  }

  static String _normalizeCitation(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
