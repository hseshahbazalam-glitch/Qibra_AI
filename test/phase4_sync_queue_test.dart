import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/sync/conflict.dart';
import 'package:qibra_ai/core/sync/sync_engine.dart';

void main() {
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
