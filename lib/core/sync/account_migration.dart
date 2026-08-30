// Anonymous → account attach. Never wipe local data first.

import 'package:qibra_ai/core/sync/sync_engine.dart';

class AccountMigration {
  const AccountMigration._();

  /// Keep local snapshots and enqueue them for later sync.
  /// Callers must not clear bookmarks/progress before this runs.
  static void attachLocal({
    required SyncQueue queue,
    required List<SyncOp> localOps,
  }) {
    for (final op in localOps) {
      queue.enqueue(op);
    }
  }
}
