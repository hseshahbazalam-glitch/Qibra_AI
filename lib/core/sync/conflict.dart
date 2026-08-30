// Deterministic merge. Does not invent Quran/Hadith identifiers.

class BookmarkMerge {
  static List<String> setUnion({
    required List<String> localIds,
    required List<String> remoteIds,
    List<String> deletedIds = const [],
  }) {
    final deleted = deletedIds.toSet();
    final merged = <String>{};
    for (final id in [...localIds, ...remoteIds]) {
      if (id.isEmpty || deleted.contains(id)) continue;
      merged.add(id);
    }
    final out = merged.toList()..sort();
    return out;
  }
}

class ProgressMerge {
  static Map<String, dynamic> latestWins({
    required Map<String, dynamic> local,
    required DateTime localUpdated,
    required Map<String, dynamic> remote,
    required DateTime remoteUpdated,
  }) {
    if (remoteUpdated.isAfter(localUpdated)) return remote;
    return local;
  }
}
