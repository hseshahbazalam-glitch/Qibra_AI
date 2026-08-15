import 'package:flutter/foundation.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/quran/data/repository/quran_repository.dart';

class RetrievedPassage {
  final String source;
  final String text;
  final double relevance;
  final String collection;

  const RetrievedPassage({
    required this.source,
    required this.text,
    required this.relevance,
    required this.collection,
  });
}

class RagService {
  RagService._();

  static final RagService instance = RagService._();

  final QuranRepository _quranRepo = QuranRepository();
  HadithDatabaseService? _hadithDb;

  void attachHadithDb(HadithDatabaseService db) {
    _hadithDb = db;
  }

  /// Retrieves verified local Quran and Hadith passages for a query.
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
            ),
          );
        }
      }
    } catch (error) {
      debugPrint('[RAG] Quran search error: $error');
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
            ),
          );
        }
      }
    } catch (error) {
      debugPrint('[RAG] Hadith search error: $error');
    }

    results.sort((a, b) => b.relevance.compareTo(a.relevance));

    return results.take(topK).toList();
  }

  /// Builds verified source context for an AI request.
  Future<String> buildContextForQuery(String query) async {
    final passages = await retrieve(query, topK: 3);

    if (passages.isEmpty) return '';

    final buffer = StringBuffer();

    buffer.writeln(
      'Verified Qibra sources for this question (use these first and cite them):',
    );

    for (var index = 0; index < passages.length; index++) {
      final passage = passages[index];

      buffer.writeln(
        '[${index + 1}] ${passage.source}: ${passage.text}',
      );
    }

    buffer.writeln(
      'If no relevant passage above exists, say: '
      '"I could not find a verified source — please consult a qualified scholar."',
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
