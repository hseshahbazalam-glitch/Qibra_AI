import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;
import 'package:qibra_ai/core/sync/conflict.dart';
import 'package:qibra_ai/core/sync/sync_engine.dart';


// M6SHADOW3 (transient, one round): file-local wrappers with the SDK's
// EXACT test/testWidgets signatures (read from flutter 3.44.6 sources).
// Bodies are caught and the name rides the ::error:: annotation channel.
final _m6bad = <String>[];

void testWidgets(
  String d,
  WidgetTesterCallback cb, {
  bool? skip,
  Timeout? timeout,
}) {
  ft.testWidgets(d, (t) async {
    try {
      await cb(t);
    } catch (e) {
      _m6bad.add('core_phase4_sync_queue_test :: $d :: ${e.toString().split('\n').first}');
      rethrow;
    }
  }, skip: skip, timeout: timeout);
}

void test(
  Object d,
  dynamic Function() body, {
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  dynamic tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) {
  ft.test(d, () async {
    try {
      await body();
    } catch (e) {
      _m6bad.add('core_phase4_sync_queue_test :: $d :: ${e.toString().split('\n').first}');
      rethrow;
    }
  },
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      tags: tags,
      onPlatform: onPlatform,
      retry: retry);
}

void main() {

  tearDownAll(() {
    for (final x in _m6bad) {
      print('::error::M6BAD ${x.length > 230 ? x.substring(0, 230) : x}');
    }
  });

  test('sync queue does not keep tokens in payload contract', () {
    final q = SyncQueue();
    q.enqueue(SyncOp(
      id: '2:255',
      collection: 'quran',
      type: SyncOpType.upsert,
      payload: const {'surah': 2, 'ayah': 255},
      updatedAt: DateTime.utc(2026, 1, 1),
    ));
    expect(q.pending, hasLength(1));
    expect(q.snapshot().first['payload'].toString().contains('token'), isFalse);
  });

  test('bookmark set merge keeps tombstones out', () {
    final merged = BookmarkMerge.setUnion(
      localIds: const ['bukhari:1', 'muslim:1'],
      remoteIds: const ['muslim:1', 'nasai:1'],
      deletedIds: const ['nasai:1'],
    );
    expect(merged, ['bukhari:1', 'muslim:1']);
  });

  test('progress latest wins', () {
    final older = DateTime.utc(2026, 1, 1);
    final newer = DateTime.utc(2026, 1, 2);
    final won = ProgressMerge.latestWins(
      local: const {'surah': 1},
      localUpdated: older,
      remote: const {'surah': 18},
      remoteUpdated: newer,
    );
    expect(won['surah'], 18);
  });
}
