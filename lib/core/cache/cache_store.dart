// Local key-value cache. Does not log payload contents.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheEntry {
  const CacheEntry({
    required this.key,
    required this.value,
    required this.storedAt,
    this.ttl,
  });

  final String key;
  final String value;
  final DateTime storedAt;
  final Duration? ttl;

  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().isAfter(storedAt.add(ttl!));
  }
}

class CacheStore {
  CacheStore._();
  static final CacheStore instance = CacheStore._();

  static const _prefix = 'qibra_cache_';

  Future<void> write(String key, String value, {Duration? ttl}) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'v': value,
      't': DateTime.now().toIso8601String(),
      'ttl': ttl?.inMilliseconds,
    });
    await prefs.setString('$_prefix$key', payload);
  }

  Future<CacheEntry?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final entry = CacheEntry(
        key: key,
        value: map['v'] as String? ?? '',
        storedAt: DateTime.tryParse(map['t'] as String? ?? '') ?? DateTime.now(),
        ttl: map['ttl'] == null ? null : Duration(milliseconds: map['ttl'] as int),
      );
      if (entry.isExpired) {
        await prefs.remove('$_prefix$key');
        return null;
      }
      return entry;
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }
}
