import 'package:flutter_test/flutter_test.dart';
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

}
