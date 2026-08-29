// Client sync engine. Merge is last-write-wins on the server; client queues ops.

enum SyncOpType { upsert, delete }

class SyncOp {
  const SyncOp({
    required this.id,
    required this.collection,
    required this.type,
    required this.payload,
    required this.updatedAt,
  });

  final String id;
  final String collection;
  final SyncOpType type;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
}

class SyncQueue {
  final List<SyncOp> _ops = [];

  List<SyncOp> get pending => List.unmodifiable(_ops);

  void enqueue(SyncOp op) {
    _ops.removeWhere((o) => o.collection == op.collection && o.id == op.id);
    _ops.add(op);
  }

  void ack(String id, String collection) {
    _ops.removeWhere((o) => o.id == id && o.collection == collection);
  }

  void clear() => _ops.clear();
}

class SyncEngine {
  SyncEngine._();
  static final SyncEngine instance = SyncEngine._();

  final SyncQueue queue = SyncQueue();
  bool _inFlight = false;

  bool get isInFlight => _inFlight;

  Future<void> runSingleFlight(Future<void> Function() work) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      await work();
    } finally {
      _inFlight = false;
    }
  }

  Duration jitteredBackoff(int attempt, {int maxMs = 30000}) {
    final base = 250 * (1 << attempt.clamp(0, 6));
    final jitter = DateTime.now().microsecond % 180;
    return Duration(milliseconds: (base + jitter).clamp(250, maxMs));
  }

  Future<T> retry<T>(Future<T> Function() work, {int times = 3}) async {
    Object? last;
    for (var i = 0; i < times; i++) {
      try {
        return await work();
      } catch (e) {
        last = e;
        await Future<void>.delayed(jitteredBackoff(i));
      }
    }
    throw last ?? StateError('retry exhausted');
  }
}
