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

abstract final class EventAllowlist {
  static const names = {
    'opened_home',
    'opened_prayer',
    'opened_quran',
    'opened_more',
    'sync_ok',
    'sync_conflict',
    'sync_fail',
    'cache_hit',
    'cache_miss',
    'cache_stale',
    'notif_plan',
    'rag_local',
    'rag_no_context',
    'billing_unconfigured',
    'api_ok',
    'api_error',
    'crash_hook',
  };

  static const banned = [
    'email',
    'token',
    'gps',
    'latitude',
    'longitude',
    'receipt',
    'ayah',
    'hadith',
    'prompt',
    'password',
    'secret',
  ];

  static bool isForbidden(String name, [Map<String, String> meta = const {}]) {
    final blob = '$name ${meta.values.join(' ')}'.toLowerCase();
    return banned.any(blob.contains);
  }

  static bool isAllowed(String name, [Map<String, String> meta = const {}]) {
    if (isForbidden(name, meta)) return false;
    return names.contains(name);
  }
}

abstract final class LogRedactor {
  static final _email = RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false);
  static final _bearer = RegExp(r'bearer\s+\S+', caseSensitive: false);
  static final _jwt = RegExp(r'eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}');
  static final _geo = RegExp(
    r'\b(?:lat|lng|lon|latitude|longitude)\s*[:=]\s*-?\d+(?:\.\d+)?',
    caseSensitive: false,
  );

  static String redact(String text) {
    var out = text.replaceAll(_email, '[redacted-email]');
    out = out.replaceAll(_bearer, 'bearer [redacted]');
    out = out.replaceAll(_jwt, '[redacted-jwt]');
    out = out.replaceAll(_geo, '[redacted-geo]');
    return out;
  }
}

class LocalMetrics {
  LocalMetrics();

  final Map<String, int> _counters = {};

  void inc(String name, [int n = 1]) {
    if (name.isEmpty || EventAllowlist.isForbidden(name)) return;
    _counters[name] = (_counters[name] ?? 0) + n;
  }

  void noteCrash() => inc('crash_hook');

  Map<String, int> snapshot() => Map.unmodifiable(_counters);

  void reset() => _counters.clear();
}

class Observability {
  Observability._();
  static final Observability instance = Observability._();

  ObservabilityConsent consent = ObservabilityConsent.off;
  final List<LocalEvent> _buffer = [];
  final LocalMetrics metrics = LocalMetrics();

  bool get isEnabled => consent.enabled;

  void record(String name, {Map<String, String> meta = const {}}) {
    if (!isEnabled) return;
    if (!EventAllowlist.isAllowed(name, meta)) return;
    _buffer.add(LocalEvent(name, meta: meta));
    if (_buffer.length > 50) _buffer.removeAt(0);
  }

  List<LocalEvent> snapshot() => List.unmodifiable(_buffer);

  void hookCrash() {
    metrics.noteCrash();
  }
}
