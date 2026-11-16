// lib/features/quran/data/repository/urdu_edition_catalog.dart
//
// ============================================================
// QIBRA AI — PASS E: THE URDU EDITION CATALOG
// ============================================================
// The honesty layer for Urdu translations. Before Pass E the settings
// picker offered every bundled Urdu edition but only Jalandhry's data
// ever reached the reader — choosing Tahir-ul-Qadri printed Jalandhry
// silently. This catalog makes the promise real: whatever the picker
// offers, the reader loads and shows; whatever is too heavy to keep,
// the LRU drops (max 2 resident editions — six ~2MB maps at once is
// MANA by the memory discipline of this pass).
//
// Contract:
//   * 'en' and the two faces already ATTACHED to the models by
//     QuranRepository (Jalandhry script, Maududi roman) resolve to
//     null — meaning "serve the model field". No duplicate copies, and
//     the pre-E default render is byte-identical (no surprise switch).
//   * Any other bundled 'ur_*' id lazy-loads its registered asset file
//     through the repository's proven 'quran'-shape parser. Blank ayah
//     texts (the upstream Tahir-ul-Qadri 7+100 gap) are stored as
//     ABSENT, so consumers show the honest unavailable line — never an
//     empty string, never another edition's bleed.
//   * While a load is in flight consumers keep the previous (default)
//     face — keep-old-until-ready, the same frame policy the Q2 reader
//     uses for its fonts.
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:qibra_ai/core/content/edition_resolver.dart';
import 'package:qibra_ai/features/quran/data/models/quran_models.dart';
import 'package:qibra_ai/features/quran/providers/reading_preferences_provider.dart';

dynamic _parseJsonIsolate(String jsonString) => jsonDecode(jsonString);

class UrduEditionCatalog {
  UrduEditionCatalog._internal();
  static final UrduEditionCatalog instance = UrduEditionCatalog._internal();

  /// Memory discipline: the selected edition plus the previously loaded
  /// one — never all six (~12MB of maps) at once.
  static const int maxCachedEditions = 2;

  // editionId -> ('chapter:verse' -> text). Map order IS the LRU order:
  // use touches move an entry to the tail; eviction takes the head.
  final Map<String, Map<String, String>> _loaded = {};
  final Map<String, Future<Map<String, String>?>> _inFlight = {};

  /// Ids whose content already rides AyahModel (attached by the Quran
  /// repository at init): a catalog copy of them would be a lie of
  /// duplication AND wasted memory. They resolve to null.
  static bool _servedByModelField(String canonicalId) =>
      canonicalId == 'ur_jalandhry' || canonicalId == 'ur_maududi_roman';

  /// Test/pure view of the resident set, oldest first.
  List<String> get loadedIds => List.unmodifiable(_loaded.keys);

  void debugReset() {
    _loaded.clear();
    _inFlight.clear();
  }

  /// Seed the cache without touching rootBundle (mirrors the Q2
  /// provider-override harness style — pure LRU tests use this).
  void debugInject(String editionId, Map<String, String> map) {
    final id = EditionResolver.canonical(editionId);
    _loaded
      ..remove(id)
      ..[id] = Map<String, String>.of(map);
    _evictOverflow();
  }

  /// Synchronous peek — the share/copy flows call this so a button
  /// never waits on disk; null means "serve the default face".
  Map<String, String>? peek(String editionId) {
    final id = EditionResolver.canonical(editionId);
    final hit = _loaded.remove(id);
    if (hit != null) _loaded[id] = hit; // touch -> MRU tail
    return hit;
  }

  /// Ensure the edition's map is resident; resolves null for the ids
  /// that serve from the model fields and for anything unbundled.
  Future<Map<String, String>?> ensure(String editionId) async {
    final id = EditionResolver.canonical(editionId);
    if (!id.startsWith('ur') || _servedByModelField(id)) return null;
    final hit = peek(id);
    if (hit != null) return hit;
    final fly = _inFlight[id];
    if (fly != null) return fly;
    final future = _load(id).whenComplete(() => _inFlight.remove(id));
    _inFlight[id] = future;
    return future;
  }

  Future<Map<String, String>?> _load(String id) async {
    final edition = EditionResolver.resolve(id);
    if (edition == null) return null;
    try {
      // Disk-first, decided by physics, not by sniffing the room: a
      // registered asset's relative path resolves ONLY where the asset
      // tree sits next to the process — the test harness and desktop
      // dev runs from the repo. A shipped mobile build has no such
      // path (CWD is not the bundle), so devices fall through to
      // rootBundle. The read is attempted, not stat-ed: open() is the
      // primitive the E5 file pins already exercise green on CI, while
      // a stat-based probe was proven to mislead once this very branch
      // was chosen. The disk bytes go through the same parser inline —
      // the same registered file, no unwaitable port machinery (the
      // bundle+isolate pair completes over channels a test zone never
      // dispatches: CI-proven three ways before this landed).
      dynamic decoded;
      final read = _tryReadAssetFile(edition.assetPath);
      if (read != null) {
        decoded = jsonDecode(read);
      } else {
        final jsonString = await rootBundle.loadString(edition.assetPath);
        decoded = await Isolate.run(() => _parseJsonIsolate(jsonString));
      }
      final map = parseUrduShape(decoded);
      _loaded[id] = map;
      _evictOverflow();
      return map;
    } catch (e) {
      if (kDebugMode) debugPrint('[EDITION] load failed ($id): $e');
      return null;
    }
  }

  /// One-shot attempt: read the file if the process can; null on any
  /// failure (missing path, permissions, a device bundle layout). Never
  /// throws — the caller treats null as "use the bundle".
  static String? _tryReadAssetFile(String path) {
    try {
      return File(path).readAsStringSync();
    } catch (_) {
      return null;
    }
  }

  void _evictOverflow() {
    while (_loaded.length > maxCachedEditions) {
      final oldest = _loaded.keys.first;
      _loaded.remove(oldest);
      if (kDebugMode) debugPrint('[EDITION] LRU evicted $oldest');
    }
  }

  /// The 'quran:[{chapter,verse,text}]' shape — the same parse the
  /// repository performs for its two resident faces, kept honest about
  /// blanks: an empty upstream text is stored as ABSENT, so consumers
  /// fall through to their "unavailable" line (the TQ 7+100 gap).
  static Map<String, String> parseUrduShape(dynamic decoded) {
    final out = <String, String>{};
    final rows =
        decoded is Map<String, dynamic> ? decoded['quran'] : null;
    if (rows is! List) return out;
    for (final row in rows) {
      if (row is! Map) continue;
      final chapter = (row['chapter'] as num?)?.toInt();
      final verse = (row['verse'] as num?)?.toInt();
      final text = (row['text'] as String?)?.trim() ?? '';
      if (chapter == null || verse == null || text.isEmpty) continue;
      out['$chapter:$verse'] = text;
    }
    return out;
  }

  /// E1 census seam — the ONE resolution every edition-aware consumer
  /// calls (reader card, compare column, share/copy, home preview):
  /// selected edition's loaded text first; the model's default face
  /// while a load is in flight; English as the non-Urdu fallback.
  /// Null = show the honest unavailable line. Never a mislabel.
  static String? selectedText({
    required AyahModel ayah,
    required ReadingPreferences prefs,
    required int surahNumber,
    Map<String, String>? editionTexts,
  }) {
    final id = EditionResolver.canonical(prefs.translationId);
    if (id == 'en') {
      final english = ayah.translation?.trim();
      return (english == null || english.isEmpty) ? null : english;
    }
    if (editionTexts != null) {
      final hit = editionTexts['$surahNumber:${ayah.number}'];
      return (hit == null || hit.isEmpty) ? null : hit;
    }
    final face = id == 'ur_maududi_roman'
        ? ayah.translationRoman
        : ayah.translationUrdu;
    final trimmed = face?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// True when the selected id wants an Urdu face (compare card picks
  /// its column label off this).
  static bool urduSelected(ReadingPreferences prefs) =>
      EditionResolver.canonical(prefs.translationId).startsWith('ur');
}
