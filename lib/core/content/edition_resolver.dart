// Arabic + bundled translations only. Unbundled editions are honest misses.
// No fake Hindi. No remote edition pretending to be local.

class EditionMiss {
  const EditionMiss(this.id, this.reason);
  final String id;
  final String reason;
}

class ResolvedEdition {
  const ResolvedEdition({
    required this.id,
    required this.language,
    required this.assetPath,
    required this.label,
  });

  final String id;
  final String language;
  final String assetPath;
  final String label;
}

abstract final class EditionResolver {
  static const Map<String, ResolvedEdition> bundled = {
    'ar': ResolvedEdition(
      id: 'ar',
      language: 'ar',
      assetPath: 'assets/data/quran/quran_arabic.json',
      label: 'Arabic',
    ),
    'en': ResolvedEdition(
      id: 'en',
      language: 'en',
      assetPath: 'assets/data/quran/translation_en.json',
      label: 'English',
    ),
    'ur': ResolvedEdition(
      id: 'ur',
      language: 'ur',
      assetPath: 'assets/data/quran/translation_ur_jalandhry.json',
      label: 'Urdu (Jalandhry)',
    ),
    'ur_jalandhry': ResolvedEdition(
      id: 'ur_jalandhry',
      language: 'ur',
      assetPath: 'assets/data/quran/translation_ur_jalandhry.json',
      label: 'Urdu (Jalandhry)',
    ),
    'ur_junagarhi': ResolvedEdition(
      id: 'ur_junagarhi',
      language: 'ur',
      assetPath: 'assets/data/quran/translation_ur_junagarhi.json',
      label: 'Urdu (Junagarhi)',
    ),
    'ur_maududi': ResolvedEdition(
      id: 'ur_maududi',
      language: 'ur',
      assetPath: 'assets/data/quran/translation_ur_maududi.json',
      label: 'Urdu (Maududi)',
    ),
    'ur_maududi_roman': ResolvedEdition(
      id: 'ur_maududi_roman',
      language: 'ur',
      assetPath: 'assets/data/quran/translation_ur_maududi_roman.json',
      label: 'Roman Urdu (Maududi)',
    ),
    'ur_tahirulqadri': ResolvedEdition(
      id: 'ur_tahirulqadri',
      language: 'ur',
      assetPath: 'assets/data/quran/translation_ur_tahirulqadri.json',
      label: 'Urdu (Tahir-ul-Qadri)',
    ),
    'ur_usmani': ResolvedEdition(
      id: 'ur_usmani',
      language: 'ur',
      assetPath: 'assets/data/quran/translation_ur_usmani.json',
      label: 'Urdu (Usmani)',
    ),
  };

  static bool isBundled(String id) => bundled.containsKey(id.toLowerCase());

  static ResolvedEdition? resolve(String id) => bundled[id.toLowerCase()];

  static EditionMiss? miss(String id) {
    if (isBundled(id)) return null;
    if (id.toLowerCase() == 'hi' || id.toLowerCase() == 'hindi') {
      return const EditionMiss('hi', 'Hindi translation is not bundled.');
    }
    return EditionMiss(id, 'Edition "$id" is not bundled.');
  }

  static List<ResolvedEdition> allBundled() => bundled.values.toList();
}
