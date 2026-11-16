// Local key-value cache. Expired entries are kept until invalidated.
// Does not log payload contents. Do not store tokens, passwords, or GPS.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum CacheFreshness { missing, fresh, stale, expired }

abstract class CacheBackend {
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
  Future<void> remove(String key);
}

class MemoryCacheBackend implements CacheBackend {
  final Map<String, String> data = {};

  @override
  Future<void> setString(String key, String value) async => data[key] = value;

  @override
  Future<String?> getString(String key) async => data[key];

  @override
  Future<void> remove(String key) async => data.remove(key);
}

class PrefsCacheBackend implements CacheBackend {
  PrefsCacheBackend(this.prefs);
  final SharedPreferences prefs;

  @override
  Future<void> setString(String key, String value) => prefs.setString(key, value);

  @override
  Future<String?> getString(String key) async => prefs.getString(key);

  @override
  Future<void> remove(String key) => prefs.remove(key);
}

class CacheEntry {
  const CacheEntry({
    required this.key,
    required this.value,
    required this.storedAt,
    this.updatedAt,
    this.ttl,
    this.staleAfter,
    this.version,
    this.source,
    this.checksum,
  });

  final String key;
  final String value;
  final DateTime storedAt;
  final DateTime? updatedAt;
  final Duration? ttl;
  final Duration? staleAfter;
  final String? version;
  final String? source;
  final String? checksum;

  DateTime? get expiresAt => ttl == null ? null : storedAt.add(ttl!);
  DateTime? get staleAt => staleAfter == null ? expiresAt : storedAt.add(staleAfter!);

  bool isExpiredAt(DateTime now) {
    final exp = expiresAt;
    if (exp == null) return false;
    return !now.isBefore(exp);
  }

  CacheFreshness freshnessAt(DateTime now) {
    return CachePolicy.classify(this, now);
  }
}

class CacheLookup {
  const CacheLookup(this.freshness, [this.entry]);

  final CacheFreshness freshness;
  final CacheEntry? entry;

  bool get hasData => entry != null;
  bool get isMissing => freshness == CacheFreshness.missing;
}

abstract final class CachePolicy {
  static CacheFreshness classify(CacheEntry? entry, DateTime now) {
    if (entry == null) return CacheFreshness.missing;
    final staleAt = entry.staleAt;
    final expiresAt = entry.expiresAt;
    if (expiresAt != null && !now.isBefore(expiresAt)) {
      return CacheFreshness.expired;
    }
    if (staleAt != null && !now.isBefore(staleAt)) {
      return CacheFreshness.stale;
    }
    return CacheFreshness.fresh;
  }
}

class CacheStore {
  CacheStore({CacheBackend? backend, DateTime Function()? clock})
      : _injected = backend,
        _clock = clock ?? DateTime.now;

  static final CacheStore instance = CacheStore();

  final CacheBackend? _injected;
  final DateTime Function() _clock;
  CacheBackend? _prefsBackend;

  static const _prefix = 'qibra_cache_';

  Future<CacheBackend> _backend() async {
    if (_injected != null) return _injected;
    return _prefsBackend ??=
        PrefsCacheBackend(await SharedPreferences.getInstance());
  }

  String _k(String key) => '$_prefix$key';

  Future<void> write(
    String key,
    String value, {
    Duration? ttl,
    Duration? staleAfter,
    String? version,
    String? source,
    String? checksum,
  }) async {
    final backend = await _backend();
    final now = _clock();
    final payload = jsonEncode({
      'v': value,
      't': now.toIso8601String(),
      'u': now.toIso8601String(),
      'ttl': ttl?.inMilliseconds,
      'stale': staleAfter?.inMilliseconds,
      'ver': version,
      'src': source,
      'sum': checksum,
    });
    await backend.setString(_k(key), payload);
  }

  Future<CacheLookup> lookup(String key) async {
    final backend = await _backend();
    final raw = await backend.getString(_k(key));
    if (raw == null) return const CacheLookup(CacheFreshness.missing);
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final entry = CacheEntry(
        key: key,
        value: map['v'] as String? ?? '',
        storedAt: DateTime.tryParse(map['t'] as String? ?? '') ?? _clock(),
        updatedAt: DateTime.tryParse(map['u'] as String? ?? ''),
        ttl: map['ttl'] == null
            ? null
            : Duration(milliseconds: map['ttl'] as int),
        staleAfter: map['stale'] == null
            ? null
            : Duration(milliseconds: map['stale'] as int),
        version: map['ver'] as String?,
        source: map['src'] as String?,
        checksum: map['sum'] as String?,
      );
      return CacheLookup(CachePolicy.classify(entry, _clock()), entry);
    } catch (_) {
      return const CacheLookup(CacheFreshness.missing);
    }
  }

  /// Returns stored data even when stale/expired. Missing or corrupt → null.
  Future<CacheEntry?> read(String key) async {
    final hit = await lookup(key);
    return hit.entry;
  }

  Future<void> remove(String key) async {
    final backend = await _backend();
    await backend.remove(_k(key));
  }

  Future<void> invalidate(String key) => remove(key);
}
