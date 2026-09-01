// Provenance records for bundled content. UNKNOWN stays UNKNOWN.
// Never invent VERIFIED. Never rewrite Quran/Hadith JSON.
// VERIFIED requires an in-repo license file listed as licenseFile.

enum ContentTrust { bundled, retrieved, unknown }

enum ContentLegalStatus {
  verified,
  requiresPermission,
  unknown,
  doNotDistribute,
}

class ContentProvenance {
  const ContentProvenance({
    required this.id,
    required this.source,
    required this.trust,
    this.sourceName,
    this.collection,
    this.edition,
    this.translator,
    this.license,
    this.licenseUrl,
    this.licenseFile,
    this.copyrightStatus,
    this.attributionRequired,
    this.commercialUse,
    this.redistribution,
    this.status = ContentLegalStatus.unknown,
    this.verifiedAt,
    this.notes,
  });

  final String id;
  final String source;
  final ContentTrust trust;
  final String? sourceName;
  final String? collection;
  final String? edition;
  final String? translator;
  final String? license;
  final String? licenseUrl;
  final String? licenseFile;
  final String? copyrightStatus;
  final String? attributionRequired;
  final String? commercialUse;
  final String? redistribution;
  final ContentLegalStatus status;
  final String? verifiedAt;
  final String? notes;

  bool get isVerifiedClaim => false;

  bool get productionRagEligible =>
      status == ContentLegalStatus.verified &&
      licenseFile != null &&
      licenseFile!.isNotEmpty;

  static ContentLegalStatus parseStatus(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'VERIFIED':
        return ContentLegalStatus.verified;
      case 'REQUIRES_PERMISSION':
        return ContentLegalStatus.requiresPermission;
      case 'DO_NOT_DISTRIBUTE':
        return ContentLegalStatus.doNotDistribute;
      default:
        return ContentLegalStatus.unknown;
    }
  }

  static const List<ContentProvenance> bundled = [
    ContentProvenance(
      id: 'quran_arabic_uthmani',
      source: 'assets/data/quran/quran_arabic.json',
      sourceName: 'quran-uthmani',
      collection: 'quran',
      edition: 'quran-uthmani',
      trust: ContentTrust.bundled,
      status: ContentLegalStatus.unknown,
      license: 'UNKNOWN',
      notes: 'Arabic Uthmani text. Not a license grant.',
    ),
    ContentProvenance(
      id: 'quran_en_asad',
      source: 'assets/data/quran/translation_en.json',
      sourceName: 'en.asad',
      collection: 'quran',
      edition: 'en.asad',
      translator: 'Muhammad Asad',
      trust: ContentTrust.bundled,
      status: ContentLegalStatus.requiresPermission,
      license: 'UNKNOWN',
      notes: 'Named translator in JSON. No in-repo license file.',
    ),
    ContentProvenance(
      id: 'quran_ur_jalandhry',
      source: 'assets/data/quran/translation_ur_jalandhry.json',
      collection: 'quran',
      translator: 'Fateh Muhammad Jalandhry (filename)',
      trust: ContentTrust.bundled,
      status: ContentLegalStatus.unknown,
    ),
    ContentProvenance(
      id: 'hadith_local',
      source: 'assets/data/hadith/',
      collection: 'hadith',
      trust: ContentTrust.bundled,
      status: ContentLegalStatus.unknown,
      notes: 'Local collections. Grade UNKNOWN unless the file itself supplies one.',
    ),
    ContentProvenance(
      id: 'tafsir_ibn_kathir',
      source: 'not bundled',
      collection: 'tafsir',
      trust: ContentTrust.unknown,
      status: ContentLegalStatus.doNotDistribute,
      notes: 'Do not bundle until a licensed edition is in-repo.',
    ),
  ];

  static ContentProvenance unknown(String id) => ContentProvenance(
        id: id,
        source: 'UNKNOWN',
        trust: ContentTrust.unknown,
        status: ContentLegalStatus.unknown,
        notes: 'Not bundled. Do not invent text or grades.',
      );
}
