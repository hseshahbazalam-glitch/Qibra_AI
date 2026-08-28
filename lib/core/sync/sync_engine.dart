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
}
