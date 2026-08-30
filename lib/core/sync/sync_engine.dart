// Client sync engine. Merge is last-write-wins on the server; client queues ops.
// Never enqueue passwords, tokens, or Quran/Hadith full text.

enum SyncOpType { upsert, delete }

enum SyncOpStatus { pending, processing, completed, failed, conflict }

class SyncOp {
  const SyncOp({
    required this.id,
    required this.collection,
    required this.type,
    required this.payload,
    required this.updatedAt,
    this.status = SyncOpStatus.pending,
    this.attemptCount = 0,
    this.errorCode,
  });

  final String id;
  final String collection;
  final SyncOpType type;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
  final SyncOpStatus status;
  final int attemptCount;
  final String? errorCode;

  SyncOp copyWith({
    SyncOpStatus? status,
    int? attemptCount,
    String? errorCode,
  }) {
    return SyncOp(
      id: id,
      collection: collection,
      type: type,
      payload: payload,
      updatedAt: updatedAt,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      errorCode: errorCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'collection': collection,
        'type': type.name,
        'payload': payload,
        'updated_at': updatedAt.toIso8601String(),
        'status': status.name,
        'attempt_count': attemptCount,
        'error_code': errorCode,
      };

  factory SyncOp.fromJson(Map<String, dynamic> json) {
    return SyncOp(
      id: json['id']?.toString() ?? '',
      collection: json['collection']?.toString() ?? '',
      type: SyncOpType.values.firstWhere(
        (v) => v.name == json['type'],
        orElse: () => SyncOpType.upsert,
      ),
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload'] as Map<String, dynamic>
          : <String, dynamic>{},
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: SyncOpStatus.values.firstWhere(
        (v) => v.name == json['status'],
        orElse: () => SyncOpStatus.pending,
      ),
      attemptCount: (json['attempt_count'] as num?)?.toInt() ?? 0,
      errorCode: json['error_code']?.toString(),
    );
  }
}

class SyncQueue {
  final List<SyncOp> _ops = [];

  List<SyncOp> get pending =>
      List.unmodifiable(_ops.where((o) => o.status == SyncOpStatus.pending));

  List<SyncOp> get all => List.unmodifiable(_ops);

  void enqueue(SyncOp op) {
    _ops.removeWhere((o) => o.collection == op.collection && o.id == op.id);
    _ops.add(op.copyWith(status: SyncOpStatus.pending));
  }

  void ack(String id, String collection) {
    _ops.removeWhere((o) => o.id == id && o.collection == collection);
  }

  void mark(String id, String collection, SyncOpStatus status, {String? errorCode}) {
    for (var i = 0; i < _ops.length; i++) {
      final op = _ops[i];
      if (op.id == id && op.collection == collection) {
        _ops[i] = op.copyWith(
          status: status,
          attemptCount: op.attemptCount + (status == SyncOpStatus.failed ? 1 : 0),
          errorCode: errorCode,
        );
      }
    }
  }

  void restore(List<SyncOp> ops) {
    _ops
      ..clear()
      ..addAll(ops);
  }

  List<Map<String, dynamic>> snapshot() => _ops.map((o) => o.toJson()).toList();

  void clear() => _ops.clear();
}

class SyncEngine {
  SyncEngine._();
  static final SyncEngine instance = SyncEngine._();

  final SyncQueue queue = SyncQueue();
  bool _inFlight = false;
  static const int maxBatch = 500;

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

  List<SyncOp> takeBatch({int limit = maxBatch}) {
    return queue.pending.take(limit).toList();
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
