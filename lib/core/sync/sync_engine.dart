// Client sync engine. Merge is last-write-wins on the server; client queues ops.
// Never enqueue passwords, tokens, GPS, or Quran/Hadith full text.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'retry_policy.dart';

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
    this.nextRetryAt,
  });

  final String id;
  final String collection;
  final SyncOpType type;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
  final SyncOpStatus status;
  final int attemptCount;
  final String? errorCode;
  final DateTime? nextRetryAt;

  String? get lastError => errorCode;

  bool isDue(DateTime now) => nextRetryAt == null || !nextRetryAt!.isAfter(now);

  SyncOp copyWith({
    SyncOpStatus? status,
    int? attemptCount,
    String? errorCode,
    DateTime? nextRetryAt,
    bool clearNextRetry = false,
  }) {
    return SyncOp(
      id: id,
      collection: collection,
      type: type,
      payload: payload,
      updatedAt: updatedAt,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      errorCode: errorCode ?? this.errorCode,
      nextRetryAt: clearNextRetry ? null : (nextRetryAt ?? this.nextRetryAt),
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
        'next_retry_at': nextRetryAt?.toIso8601String(),
      };

  factory SyncOp.fromJson(Map<String, dynamic> json) {
    return SyncOp(
      id: json['id']?.toString() ?? '',
      collection: json['collection']?.toString() ?? '',
      type: SyncOpType.values.firstWhere(
        (v) => v.name == json['type'],
        orElse: () => SyncOpType.upsert,
      ),
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : <String, dynamic>{},
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: SyncOpStatus.values.firstWhere(
        (v) => v.name == json['status'],
        orElse: () => SyncOpStatus.pending,
      ),
      attemptCount: (json['attempt_count'] as num?)?.toInt() ?? 0,
      errorCode:
          json['error_code']?.toString() ?? json['last_error']?.toString(),
      nextRetryAt: DateTime.tryParse(json['next_retry_at']?.toString() ?? ''),
    );
  }
}

class SyncQueue {
  final List<SyncOp> _ops = [];

  List<SyncOp> get pending =>
      List.unmodifiable(_ops.where((o) => o.status == SyncOpStatus.pending));

  List<SyncOp> due(DateTime now) => List.unmodifiable(_ops.where((o) =>
      (o.status == SyncOpStatus.pending ||
          (o.status == SyncOpStatus.failed && o.nextRetryAt != null)) &&
      o.isDue(now)));

  List<SyncOp> get all => List.unmodifiable(_ops);

  void enqueue(SyncOp op) {
    _ops.removeWhere((o) => o.collection == op.collection && o.id == op.id);
    _ops.add(op.copyWith(status: SyncOpStatus.pending, clearNextRetry: true));
  }

  void ack(String id, String collection) {
    _ops.removeWhere((o) => o.id == id && o.collection == collection);
  }

  void mark(
    String id,
    String collection,
    SyncOpStatus status, {
    String? errorCode,
    DateTime? nextRetryAt,
  }) {
    for (var i = 0; i < _ops.length; i++) {
      final op = _ops[i];
      if (op.id == id && op.collection == collection) {
        _ops[i] = op.copyWith(
          status: status,
          attemptCount:
              op.attemptCount + (status == SyncOpStatus.failed ? 1 : 0),
          errorCode: errorCode,
          nextRetryAt: nextRetryAt,
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

  /// Test / isolated engine. Production uses [instance].
  SyncEngine.standalone();

  final SyncQueue queue = SyncQueue();
  bool _inFlight = false;
  static const int maxBatch = 500;
  static const persistKey = 'qibra_sync_queue_v1';

  bool get isInFlight => _inFlight;

  Future<void> persist(SharedPreferences prefs) async {
    await prefs.setString(persistKey, jsonEncode(queue.snapshot()));
  }

  String dumpJson() => jsonEncode(queue.snapshot());

  void loadJson(String raw) {
    if (raw.isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return;
    queue.restore(
      decoded
          .whereType<Map<String, dynamic>>()
          .map((row) => SyncOp.fromJson(Map<String, dynamic>.from(row)))
          .toList(),
    );
  }

  Future<void> load(SharedPreferences prefs) async {
    final raw = prefs.getString(persistKey);
    if (raw == null || raw.isEmpty) return;
    loadJson(raw);
  }

  /// Flush pending ops when the device is online. No-op while backend is off.
  /// [backendEnabled] is a test seam: null uses the production constant,
  /// a value pins this one call — both branches stay testable without
  /// re-releasing the app with a flipped flag.
  Future<void> flushWhenOnline({
    required bool online,
    Future<void> Function(List<SyncOp> batch)? sender,
    SharedPreferences? prefs,
    DateTime? now,
    bool? backendEnabled,
  }) async {
    if (prefs != null) await persist(prefs);
    if (!online || !(backendEnabled ?? AppApi.isBackendEnabled)) return;
    await runSingleFlight(() async {
      final batch = takeBatch(now: now ?? DateTime.now());
      if (batch.isEmpty || sender == null) return;
      await sender(batch);
    });
  }

  Future<void> runSingleFlight(Future<void> Function() work) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      await work();
    } finally {
      _inFlight = false;
    }
  }

  List<SyncOp> takeBatch({int limit = maxBatch, DateTime? now}) {
    final due = now == null ? queue.pending : queue.due(now);
    return due.take(limit).toList();
  }

  Duration jitteredBackoff(int attempt, {int maxMs = 30000}) {
    return RetryPolicy.backoff(
      attempt,
      maxMs: maxMs,
      jitterMs: DateTime.now().microsecond % 180,
    );
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
