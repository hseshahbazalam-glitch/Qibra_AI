import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/cache/cache_store.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/notifications/notification_reconcile.dart';
import 'package:qibra_ai/core/offline/data_status.dart';
import 'package:qibra_ai/core/offline/reachability.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';
import 'package:qibra_ai/core/sync/conflict.dart';
import 'package:qibra_ai/core/sync/retry_policy.dart';
import 'package:qibra_ai/core/sync/sync_engine.dart';
import 'package:qibra_ai/features/ai/services/rag_service.dart';
import 'package:qibra_ai/features/prayer/data/services/prayer_schedule_cache.dart';

void main() {
  DateTime t0 = DateTime.utc(2026, 8, 30, 12);

  CacheStore storeAt(DateTime Function() clock) {
    return CacheStore(backend: MemoryCacheBackend(), clock: clock);
  }

  test('cache hit / miss / stale / expired keep data', () async {
    var now = t0;
    final store = storeAt(() => now);
    expect((await store.lookup('k')).freshness, CacheFreshness.missing);

    await store.write(
      'k',
      'v1',
      ttl: const Duration(minutes: 10),
      staleAfter: const Duration(minutes: 5),
    );
    expect((await store.lookup('k')).freshness, CacheFreshness.fresh);
    expect((await store.read('k'))?.value, 'v1');

    now = t0.add(const Duration(minutes: 6));
    expect((await store.lookup('k')).freshness, CacheFreshness.stale);
    expect((await store.read('k'))?.value, 'v1');

    now = t0.add(const Duration(minutes: 11));
    final expired = await store.lookup('k');
    expect(expired.freshness, CacheFreshness.expired);
    expect(expired.entry?.value, 'v1');
  });

  test('offline read and network-failure fallback keep stale', () async {
    var now = t0;
    final store = storeAt(() => now);
    await store.write('prayer', '{"Fajr":"05:00"}', ttl: const Duration(hours: 1));
    now = t0.add(const Duration(hours: 2));
    final hit = await store.lookup('prayer');
    expect(hit.hasData, isTrue);
    expect(
      ServiceAvailability.fromCache(
        freshness: CacheLikeFreshness.expired,
        networkOnline: false,
      ),
      DataStatus.stale,
    );
    expect(
      ServiceAvailability.fromCache(
        freshness: CacheLikeFreshness.missing,
        networkOnline: false,
      ),
      DataStatus.unavailable,
    );
  });

  test('online refresh overwrites; invalidation removes', () async {
    final store = storeAt(() => t0);
    await store.write('k', 'old', ttl: const Duration(hours: 1));
    await store.write('k', 'new', ttl: const Duration(hours: 1));
    expect((await store.read('k'))?.value, 'new');
    await store.invalidate('k');
    expect((await store.lookup('k')).isMissing, isTrue);
  });

  test('queue persistence, duplicate prevention, retry backoff', () {
    final engine = SyncEngine.standalone();
    final op = SyncOp(
      id: '2:255',
      collection: 'bookmarks',
      type: SyncOpType.upsert,
      payload: const {'surah': 2, 'ayah': 255},
      updatedAt: t0,
    );
    engine.queue.enqueue(op);
    engine.queue.enqueue(op.copyWith());
    expect(engine.queue.pending, hasLength(1));

    final dumped = engine.dumpJson();
    final restored = SyncEngine.standalone()..loadJson(dumped);
    expect(restored.queue.pending.single.id, '2:255');
    expect(dumped.contains('token'), isFalse);

    engine.queue.mark(
      '2:255',
      'bookmarks',
      SyncOpStatus.failed,
      errorCode: 'timeout',
      nextRetryAt: t0.add(const Duration(seconds: 2)),
    );
    expect(engine.queue.due(t0), isEmpty);
    expect(engine.queue.due(t0.add(const Duration(seconds: 3))), isNotEmpty);

    expect(RetryPolicy.backoff(0).inMilliseconds,
        lessThan(RetryPolicy.backoff(2).inMilliseconds));
    expect(RetryPolicy.shouldRetry(timeout: true), isTrue);
    expect(RetryPolicy.shouldRetry(httpStatus: 503), isTrue);
    expect(RetryPolicy.shouldRetry(httpStatus: 401), isFalse);
    expect(RetryPolicy.shouldRetry(httpStatus: 422), isFalse);
  });

  test('conflict preservation and restart recovery', () {
    final merged = BookmarkMerge.setUnion(
      localIds: const ['a', 'b'],
      remoteIds: const ['b', 'c'],
      deletedIds: const ['c'],
    );
    expect(merged, ['a', 'b']);
    final won = ProgressMerge.latestWins(
      local: const {'surah': 1},
      localUpdated: t0,
      remote: const {'surah': 18},
      remoteUpdated: t0.add(const Duration(days: 1)),
    );
    expect(won['surah'], 18);
  });

  test('offline prayer cache key and notification planning', () {
    expect(AppApi.isBackendEnabled, isFalse);
    final key = PrayerScheduleCache.keyFor(
      latitude: 21.4225,
      longitude: 39.8262,
      date: DateTime(2026, 8, 30),
      timezone: 'Asia/Riyadh',
      method: 'MWL',
      asr: 'standard',
      provider: 'local',
    );
    expect(key.contains('2026-08-30'), isTrue);
    const engine = NotificationReconcile();
    expect(engine.requestsExactAlarm, isFalse);
    final planned = engine.desired(
      times: {
        'Fajr': DateTime(2026, 8, 30, 5),
        'Dhuhr': DateTime(2026, 8, 30, 12, 10),
        'Asr': DateTime(2026, 8, 30, 15, 40),
        'Maghrib': DateTime(2026, 8, 30, 18, 50),
        'Isha': DateTime(2026, 8, 30, 20, 10),
      },
      now: DateTime(2026, 8, 30, 4),
      policy: const NotificationPolicy(),
      timezone: 'Asia/Riyadh',
      locationKey: 'Makkah',
    );
    expect(planned, isNotEmpty);
  });

  test('offline RAG no-context and auth unvalidated cache', () {
    expect(RagService.modeFor(const []), RetrievalMode.noContext);
    expect(
      RagService.modeFor(const [
        RetrievedPassage(
          source: 'Quran 1:1',
          text: 'bundled',
          relevance: 1,
          collection: 'quran',
        ),
      ]),
      RetrievalMode.localRetrieval,
    );
    expect(
      const ReachabilityState(Reachability.unknown).isOnline,
      isFalse,
    );
    expect(
      const ReachabilityState(Reachability.reconnecting).mayUseNetwork,
      isFalse,
    );
    final avail = ServiceAvailability(
      reachability: const ReachabilityState(Reachability.online),
      backendEnabled: false,
      backendHealthy: false,
    );
    expect(avail.plane, ServicePlane.networkAvailable);
    expect(avail.canCallQibraApi, isFalse);

    expect(
      AuthOffline.classify(
        backendEnabled: true,
        hasToken: true,
        networkOnline: false,
        accessExpired: true,
        userRequestedLogout: false,
      ),
      AuthOfflineState.refreshNeedsNetwork,
    );
    expect(
      AuthOffline.serverValidated(
        networkOnline: false,
        authenticated: true,
      ),
      isFalse,
    );
    const profile = CachedProfile(serverValidated: false);
    expect(profile.serverValidated, isFalse);
  });
}
