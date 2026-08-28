// Provenance records for bundled content. UNKNOWN stays UNKNOWN.
// Never invent VERIFIED. Never rewrite Quran/Hadith JSON.

enum ContentTrust { bundled, retrieved, unknown }

class ContentProvenance {
  const ContentProvenance({
    required this.id,
    required this.source,
    required this.trust,
    this.license,
    this.notes,
  });

  final String id;
  final String source;
  final ContentTrust trust;
  final String? license;
  final String? notes;

  bool get isVerifiedClaim => false;

  static const List<ContentProvenance> bundled = [
    ContentProvenance(
      id: 'quran_arabic',
      source: 'assets/data/quran/quran_arabic.json',
      trust: ContentTrust.bundled,
      license: 'See docs/CONTENT_LICENSE_MANIFEST.md',
      notes: 'Arabic Uthmani text bundled with the app. Not re-verified at runtime.',
    ),
    ContentProvenance(
      id: 'quran_en',
      source: 'assets/data/quran/translation_en.json',
      trust: ContentTrust.bundled,
      notes: 'English translation bundled. Unbundled editions are honest misses.',
    ),
    ContentProvenance(
      id: 'quran_ur_jalandhry',
      source: 'assets/data/quran/translation_ur_jalandhry.json',
      trust: ContentTrust.bundled,
    ),
    ContentProvenance(
      id: 'hadith_local',
      source: 'assets/data/hadith/',
      trust: ContentTrust.bundled,
      notes: 'Local collections. Grade UNKNOWN unless the file itself supplies one.',
    ),
  ];

  static ContentProvenance unknown(String id) => ContentProvenance(
        id: id,
        source: 'UNKNOWN',
        trust: ContentTrust.unknown,
        notes: 'Not bundled. Do not invent text or grades.',
      );
}
