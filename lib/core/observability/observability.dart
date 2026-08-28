// Local observability. Consent default OFF. No Firebase / Sentry / Mixpanel.
// Do not log email, GPS, tokens, receipts, Quran/Hadith text, or AI prompts.

class ObservabilityConsent {
  const ObservabilityConsent({this.enabled = false});
  final bool enabled;

  static const ObservabilityConsent off = ObservabilityConsent();
}

class LocalEvent {
  const LocalEvent(this.name, {this.meta = const {}});
  final String name;
  final Map<String, String> meta;
}

class Observability {
  Observability._();
  static final Observability instance = Observability._();

  ObservabilityConsent consent = ObservabilityConsent.off;
  final List<LocalEvent> _buffer = [];

  bool get isEnabled => consent.enabled;

  void record(String name, {Map<String, String> meta = const {}}) {
    if (!isEnabled) return;
    if (_isForbidden(name, meta)) return;
    _buffer.add(LocalEvent(name, meta: meta));
    if (_buffer.length > 50) _buffer.removeAt(0);
  }

  List<LocalEvent> snapshot() => List.unmodifiable(_buffer);

  bool _isForbidden(String name, Map<String, String> meta) {
    final blob = '$name ${meta.values.join(' ')}'.toLowerCase();
    const banned = [
      'email',
      'token',
      'gps',
      'latitude',
      'longitude',
      'receipt',
      'ayah',
      'hadith',
      'prompt',
    ];
    return banned.any(blob.contains);
  }
}
