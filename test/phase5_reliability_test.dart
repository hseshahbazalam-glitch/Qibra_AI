import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/sync/account_migration.dart';
import 'package:qibra_ai/core/sync/sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('backend remains disabled in this build', () {
    expect(AppApi.isBackendEnabled, isFalse);
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

  test('flushWhenOnline is a no-op while backend is disabled', () async {
    var sent = false;
    await SyncEngine.instance.flushWhenOnline(
      online: true,
      sender: (_) async {
        sent = true;
      },
    );
    expect(sent, isFalse);
  });
}
