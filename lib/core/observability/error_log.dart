// lib/core/observability/error_log.dart
// On-device crash diagnostics ring log. NO analytics, NO network, and NO
// consent gate by design: crash diagnostics are not behavioral analytics —
// the Observability consent flag gates allowlisted events only, and this
// log never leaves the device (it lands under the app support directory),
// which is precisely why it needs no consent. That on-device status is
// what makes the absolute PII rule below non-negotiable: email, GPS,
// tokens, receipts, Quran/Hadith text, and AI prompts must NEVER reach
// this log. Every string passes through the shared LogRedactor in
// observability.dart — one implementation, no duplicates (module philosophy
// header, pinned by phase11_observability_test.dart).

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:qibra_ai/core/observability/observability.dart';

/// Where capped contents go. Injectable so ring/format/cap/truncate logic
/// tests never touch a real filesystem. The default writer is the only
/// path_provider/IO user.
typedef ErrorLogWriter = FutureOr<void> Function(String contents);

class LocalErrorLog {
  LocalErrorLog._() : _writer = _writeToFile;

  /// Test seam: capture flushed contents instead of writing a file.
  @visibleForTesting
  LocalErrorLog.forTesting(ErrorLogWriter writer) : _writer = writer;

  static const int ringCap = 100; // oldest evicted beyond this
  static const int fileLineCap = 200; // last N lines survive a flush
  static const int fileByteCap = 256 * 1024; // hard size ceiling
  static const String fileName = 'error_log.txt';

  static final LocalErrorLog instance = LocalErrorLog._();

  final ErrorLogWriter _writer;
  final List<String> _ring = <String>[];
  bool _flushScheduled = false;

  /// Append one entry. Synchronous and never throws; persistence is
  /// deferred to a microtask and coalesced (a burst of records collapses
  /// into one flush of the capped tail — the "periodic flush on new
  /// records" pattern, with no timer keeping the isolate alive).
  void record(Object error, StackTrace? stack, {String? context}) {
    try {
      _ring.add(formatEntry(error, stack, context: context));
      if (_ring.length > ringCap) _ring.removeAt(0);
      _scheduleFlush();
    } catch (_) {
      // A diagnostics logger must never become the crash it records.
    }
  }

  /// One line, four '|'-separated fields: ISO timestamp | context |
  /// redacted error | first three stack frames. Newlines and '|' inside
  /// payloads are flattened so the single-line contract holds.
  static String formatEntry(
    Object error,
    StackTrace? stack, {
    String? context,
  }) {
    final ts = DateTime.now().toUtc().toIso8601String();
    final ctx = (context == null || context.isEmpty) ? '-' : _clean(context);
    final frames = stack == null
        ? '-'
        : _clean(stack.toString().trimRight().split('\n').take(3).join(' <- '));
    return '$ts | $ctx | ${_clean(error.toString())} | $frames';
  }

  static String _clean(String s) =>
      LogRedactor.redact(s.replaceAll('\n', ' ').replaceAll('|', '/'));

  /// File cap policy (pure, testable): keep the LAST [fileLineCap] lines;
  /// if the result still exceeds [fileByteCap], drop from the FRONT on a
  /// line boundary (a lone over-cap line keeps its trailing bytes).
  @visibleForTesting
  static String capFileContents(Iterable<String> lines) {
    var kept = lines.toList();
    if (kept.length > fileLineCap) {
      kept = kept.sublist(kept.length - fileLineCap);
    }
    if (kept.isEmpty) return '';
    var contents = '${kept.join('\n')}\n';
    if (contents.length > fileByteCap) {
      final cut = contents.length - fileByteCap;
      final nl = contents.indexOf('\n', cut);
      contents = nl == -1
          ? contents.substring(contents.length - fileByteCap)
          : contents.substring(nl + 1);
    }
    return contents;
  }

  /// The capped snapshot a flush would write (also the ring contract
  /// surface tests read).
  List<String> lines() => List.unmodifiable(_ring);

  void _scheduleFlush() {
    if (_flushScheduled) return;
    _flushScheduled = true;
    scheduleMicrotask(_runFlush);
  }

  Future<void> _runFlush() async {
    _flushScheduled = false;
    try {
      await _writer(capFileContents(_ring));
    } catch (_) {
      // Swallowed on purpose: failing to persist must not crash the app.
    }
  }

  static Future<void> _writeToFile(String contents) async {
    // String concat (not package:path): path is not a direct dependency and
    // new packages are out of contract. '/' is the separator on every
    // supported target (Android/iOS/web paths are POSIX-like).
    final dir = await getApplicationSupportDirectory();
    await File('${dir.path}/$fileName').writeAsString(contents, flush: true);
  }
}
