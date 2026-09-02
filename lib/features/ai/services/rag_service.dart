import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/quran/data/repository/quran_repository.dart';

enum RetrievalMode { localRetrieval, remoteRetrieval, noContext }

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

  static RetrievalMode modeFor(
    Iterable<RetrievedPassage> passages, {
    bool remote = false,
  }) {
    if (passages.isEmpty) return RetrievalMode.noContext;
    return remote ? RetrievalMode.remoteRetrieval : RetrievalMode.localRetrieval;
  }

  // ---------------------------------------------------------------------
  // ROMAN URDU BRIDGE (owner 2026-09-02)
  // ---------------------------------------------------------------------
  // The local Quran/Hadith searches match Arabic-script text and English
  // translations; Roman Urdu queries ("namaz", "roza", "paani") never
  // appear verbatim in them. Before retrieval each Roman token expands to
  // its corpus vocabulary and the hits are unioned. Zero hits fall back to
  // Levenshtein-1 dictionary corrections for typo'd words.

  static const Map<String, List<String>> romanUrduBridge = {
    'namaz': ['prayer', 'salah', 'salat', 'صلاة'],
    'salah': ['prayer', 'namaz', 'صلاة'],
    'salat': ['prayer', 'namaz', 'صلاة'],
    'prayer': ['namaz', 'salah', 'صلاة'],
    'roza': ['fasting', 'sawm', 'صوم'],
    'fasting': ['roza', 'sawm', 'صيام'],
    'zakat': ['zakah', 'charity', 'alms', 'الزكاة'],
    'qibla': ['direction', 'القبلة'],
    'dua': ['supplication', 'invocation', 'دعاء'],
    'supplication': ['dua', 'دعاء'],
    'sabr': ['patience', 'steadfastness', 'صبر'],
    'patience': ['sabr', 'صبر'],
    'jannah': ['paradise', 'garden', 'جنة'],
    'paradise': ['jannah', 'جنة'],
    'jahannam': ['hell', 'fire', 'جهنم'],
    'hell': ['jahannam', 'نار'],
    'paani': ['water', 'ماء'],
    'water': ['paani', 'ماء'],
    'halal': ['lawful', 'permissible', 'حلال'],
    'haram': ['forbidden', 'prohibited', 'حرام'],
    'iman': ['faith', 'belief', 'ایمان'],
    'faith': ['iman', 'ایمان'],
    'taubah': ['repentance', 'turning', 'توبة'],
    'repentance': ['taubah', 'توبة'],
    'nabi': ['prophet', 'نبی'],
    'prophet': ['nabi', 'رسول'],
    'quran': ['furqan', 'القرآن'],
    'makkah': ['mecca', 'مكة'],
    'madina': ['medina', 'medinah'],
    'eid': ['festival', 'feast', 'عيد'],
    'hajj': ['pilgrimage', 'حج'],
    'umrah': ['pilgrimage', 'عمرة'],
    'farz': ['obligatory', 'obligation', 'duties', 'فرض'],
    'sunnah': ['tradition', 'سنة'],
    'hadith': ['tradition', 'narration', 'حديث'],
    'ghusl': ['washing', 'bath', 'غسل'],
    'wudu': ['ablution', 'purification', 'وضوء'],
    'ablution': ['wudu', 'ablution', 'وضوء'],
  };

  // Words that mark a Latin-script query as Roman Urdu (used only to pick
  // the language of canned honest messages — never for retrieval).
  static const Set<String> _romanUrduMarkers = {
    'namaz', 'roza', 'paani', 'sabr', 'jannah', 'jahannam', 'taubah',
    'nabi', 'farz', 'sunnat', 'wuzu', 'ghusl', 'hajat', 'kiya', 'kyun',
    'kyon', 'kya', 'kaise', 'kese', 'hai', 'hain', 'nahi', 'nahin',
    'karo', 'karta', 'karti', 'batao', 'bata', 'chahiye', 'chahye',
    'sakta', 'sakti', 'aap', 'tum', 'mera', 'meri', 'hamara', 'wala',
    'wali', 'liye', 'kyonke',
  };

  static List<String> _queryTokens(String text) => RegExp(
        r"[a-z']+",
      ).allMatches(text.toLowerCase()).map((m) => m.group(0)!).toList();

  /// Bridge-side expansion terms for a query (variants not already typed).
  static List<String> expandQuery(String query) {
    final seen = _queryTokens(query).toSet();
    final out = <String>[];
    for (final token in _queryTokens(query)) {
      final variants = romanUrduBridge[token];
      if (variants == null) continue;
      for (final v in variants) {
        final key = v.toLowerCase();
        if (!seen.contains(key) && !out.contains(v)) out.add(v);
      }
    }
    return out;
  }

  /// True when the query reads as Roman Urdu (bridge words or stopword
  /// markers present and it is Latin script).
  static bool looksRomanUrdu(String query) {
    final tokens = _queryTokens(query);
    if (tokens.isEmpty) return false;
    // A bridge word that is itself Roman-script (namaz, roza, paani ...)
    // or a pair of Urdu stopwords is enough signal; single shared loan
    // words ("the quran", "sabr in Islam") stay in their typed language.
    if (tokens.any((t) => romanUrduBridge.containsKey(t) && _romanUrduMarkers.contains(t))) {
      return true;
    }
    var markers = 0;
    for (final t in tokens) {
      if (_romanUrduMarkers.contains(t)) markers++;
      if (markers >= 2) return true;
    }
    return false;
  }

  static bool _isOneEditApart(String a, String b) {
    if (a == b || (a.length - b.length).abs() > 1) return false;
    var i = 0, j = 0, edits = 0;
    while (i < a.length && j < b.length) {
      if (a[i] == b[j]) {
        i++;
        j++;
        continue;
      }
      edits++;
      if (edits > 1) return false;
      if (a.length > b.length) {
        i++;
      } else if (b.length > a.length) {
        j++;
      } else {
        i++;
        j++;
      }
    }
    edits += (a.length - i) + (b.length - j);
    return edits <= 1;
  }

  /// Dictionary words exactly one Levenshtein edit away from [token].
  /// Guards against the owner's live-tested typos ("namz", "prayr", ...).
  static List<String> correctionsFor(String token) {
    final word = token.toLowerCase();
    if (word.length < 3) return const [];
    if (_bridgeDictionary.contains(word)) return const [];
    return _bridgeDictionary
        .where((c) => c.length >= 3 && _isOneEditApart(word, c))
        .toList()
      ..sort();
  }

  static late final Set<String> _bridgeDictionary = {
    for (final e in romanUrduBridge.entries)
      ...[e.key, ...e.value]
          .where((t) => RegExp(r"^[a-z']{3,}$").hasMatch(t))
          .toSet(),
    ...romanUrduBridge.keys,
    'allah', 'mosque', 'prophets', 'pray', 'prayers', 'fast', 'believers',
    'charity', 'forgive', 'merciful', 'guidance', 'righteous', 'patience',
  };

  /// Retrieves local Quran and Hadith passages for a query — via the Roman
  /// Urdu bridge and typo corrections when needed. Not independently verified.
  Future<List<RetrievedPassage>> retrieve(
    String query, {
    int topK = 3,
  }) async {
    if (query.trim().isEmpty) return [];

    final merged = <String, RetrievedPassage>{};
    void absorb(Iterable<RetrievedPassage> list) {
      for (final passage in list) {
        final key = '${passage.collection}|${passage.source}';
        final prev = merged[key];
        if (prev == null || passage.relevance > prev.relevance) {
          merged[key] = passage;
        }
      }
    }

    absorb(await _retrieveOnce(query, topK));

    for (final term in expandQuery(query).take(6)) {
      absorb(await _retrieveOnce(term, topK));
    }

    if (merged.isEmpty) {
      // Typo tolerance (owner): retry each word with Levenshtein-1
      // corrections, and bridge-expand the corrected word.
      for (final token in _queryTokens(query)) {
        for (final fix in correctionsFor(token).take(2)) {
          absorb(await _retrieveOnce(fix, topK));
          for (final term in expandQuery(fix).take(2)) {
            absorb(await _retrieveOnce(term, topK));
          }
          if (merged.isNotEmpty) break;
        }
        if (merged.isNotEmpty) break;
      }
    }

    final results = merged.values.toList()
      ..sort((a, b) => b.relevance.compareTo(a.relevance));
    return results.take(topK).toList();
  }

  Future<List<RetrievedPassage>> _retrieveOnce(
    String query,
    int topK,
  ) async {

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
