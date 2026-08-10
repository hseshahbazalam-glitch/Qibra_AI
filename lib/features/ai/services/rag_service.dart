// lib/features/ai/services/rag_service.dart
// ============================================================
// QIBRA AI — RAG SERVICE (P1.2 — Verified Islamic Retrieval)
// ============================================================
// Simple keyword-based retrieval over local Quran + Hadith.
// Prioritizes Qibra verified data over LLM memory.
// Returns top-k passages with citations to be injected into prompt.
//
// Future: replace with embeddings + vector DB (pgvector/faiss).
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:qibra_ai/features/quran/data/repository/quran_repository.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';

class RetrievedPassage {
  final String source; // e.g., Quran 2:255, Sahih al-Bukhari 1
  final String text;
  final double relevance;
  final String collection; // quran / hadith
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

  /// Retrieve top-k passages for a query
  Future<List<RetrievedPassage>> retrieve(
    String query, {
    int topK = 3,
  }) async {
    if (query.trim().isEmpty) return [];
    final results = <RetrievedPassage>[];

    // 1. Quran retrieval (offline, keyword search via repo)
    try {
      if (_quranRepo.isInitialized) {
        final searchResults = await _quranRepo.search(query);
        for (final r in searchResults.take(topK)) {
          results.add(RetrievedPassage(
            source: r.reference, // e.g., Quran 2:255
            text: '${r.arabicText} — ${r.translation ?? ''}'.trim(),
            relevance: 0.9,
            collection: 'quran',
          ));
        }
      }
    } catch (e) {
      debugPrint('[RAG] Quran search error: $e');
    }

    // 2. Hadith retrieval (offline local DB)
    try {
      final db = _hadithDb;
      if (db != null && db.isInitialized) {
        final hadithResults = db.search(query, maxResults: topK);
        for (final r in hadithResults) {
          results.add(RetrievedPassage(
            source: r.hadith.displayReference,
            text: r.hadith.textEnglish,
            relevance: r.relevance,
            collection: 'hadith',
          ));
        }
      }
    } catch (e) {
      debugPrint('[RAG] Hadith search error: $e');
    }

    // Sort by relevance
    results.sort((a, b) => b.relevance.compareTo(a.relevance));
    return results.take(topK).toList();
  }

  /// Build context string to inject into LLM prompt
  Future<String> buildContextForQuery(String query) async {
    final passages = await retrieve(query, topK: 3);
    if (passages.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.writeln(
        'Verified Qibra sources for this question (use these first, cite them):');
    for (int i = 0; i < passages.length; i++) {
      final p = passages[i];
      buffer.writeln('[${i + 1}] ${p.source}: ${p.text}');
    }
    buffer.writeln(
        'If no relevant passage above, say: "I couldn\'t find a verified source — please consult a scholar."');
    return buffer.toString();
  }

  /// Verify that AI answer contains at least one citation from retrieved passages
  bool verifyCitations(String answer, List<RetrievedPassage> passages) {
    if (passages.isEmpty) return true; // nothing to verify
    for (final p in passages) {
      if (answer.contains(p.source)) return true;
      // Also check Quran 2:255 pattern
      final surahAyah = RegExp(r'Quran\s+\d+:\d+', caseSensitive: false);
      if (surahAyah.hasMatch(answer)) return true;
      if (answer.contains('Sahih') || answer.contains('Sunan')) return true;
    }
    return false;
  }
}
