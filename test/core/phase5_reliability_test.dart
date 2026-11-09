import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/sync/account_migration.dart';
import 'package:qibra_ai/core/sync/sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Truth-up (owner flip abee22e, 2026-09-02; this pin missed in 1fd6ee9):
  // the build enables the backend. What the OLD test actually guarded —
  // that the flag state is conscious, not drift — is what this pins now.
  test('backend is enabled in this build (owner flip, pinned)', () {
    expect(AppApi.isBackendEnabled, isTrue);
  });

  test('account migration enqueues without wiping existing ops', () {
    final queue = SyncQueue();
    queue.enqueue(SyncOp(
      id: 'local-1',
      collection: 'quran',
      type: SyncOpType.upsert,
      payload: const {'surah': 1},
      updatedAt: DateTime.utc(2026, 1, 1),
    ));
    AccountMigration.attachLocal(
      queue: queue,
      localOps: [
        SyncOp(
          id: 'local-2',
          collection: 'hadith',
          type: SyncOpType.upsert,
          payload: const {'ref': 'bukhari:1'},
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      ],
    );
    expect(queue.pending.map((o) => o.id).toList(), ['local-1', 'local-2']);
  });

  test('sync queue persists and reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final engine = SyncEngine.instance;
    engine.queue.clear();
    engine.queue.enqueue(SyncOp(
      id: '2:255',
      collection: 'quran',
      type: SyncOpType.upsert,
      payload: const {'surah': 2, 'ayah': 255},
      updatedAt: DateTime.utc(2026, 1, 1),
    ));
    await engine.persist(prefs);
    engine.queue.clear();
    expect(engine.queue.pending, isEmpty);
    await engine.load(prefs);
    expect(engine.queue.pending, hasLength(1));
    expect(engine.queue.pending.first.id, '2:255');
  });

  test('flushWhenOnline gate: BOTH branches pinned through the seam', () async {
    // The disabled-branch behavior must stay tested after abee22e — but
    // via the injectable flag, never by mutating (or praying over) the
    // global constant. Fresh standalone engines keep the queue isolated.
    SyncOp op(String id) => SyncOp(
          id: id,
          collection: 'quran',
          type: SyncOpType.upsert,
          payload: const {'surah': 1},
          updatedAt: DateTime.utc(2026, 1, 1),
        );

    final disabledEngine = SyncEngine.standalone();
    disabledEngine.queue.enqueue(op('a1'));
    var sentWhileDisabled = false;
    await disabledEngine.flushWhenOnline(
      online: true,
      backendEnabled: false,
      sender: (_) async => sentWhileDisabled = true,
    );
    expect(sentWhileDisabled, isFalse,
        reason: 'disabled branch stays a no-op even while the app ships enabled');

    final offlineEngine = SyncEngine.standalone();
    offlineEngine.queue.enqueue(op('b1'));
    var sentWhileOffline = false;
    await offlineEngine.flushWhenOnline(
      online: false,
      backendEnabled: true,
      sender: (_) async => sentWhileOffline = true,
    );
    expect(sentWhileOffline, isFalse);

    final liveEngine = SyncEngine.standalone();
    liveEngine.queue.enqueue(op('c1'));
    var sent = false;
    await liveEngine.flushWhenOnline(
      online: true,
      backendEnabled: true,
      sender: (_) async => sent = true,
    );
    expect(sent, isTrue, reason: 'enabled+online must hand the batch to the sender');
  });
}
