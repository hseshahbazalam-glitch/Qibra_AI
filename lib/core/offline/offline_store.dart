import '../cache/cache_store.dart';

class OfflineStore {
  OfflineStore._();
  static final OfflineStore instance = OfflineStore._();

  Future<void> putJson(String key, String json) {
    return CacheStore.instance.write('offline_$key', json);
  }

  Future<String?> getJson(String key) async {
    final entry = await CacheStore.instance.read('offline_$key');
    return entry?.value;
  }
}
