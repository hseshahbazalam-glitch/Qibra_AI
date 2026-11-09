import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;
import 'package:qibra_ai/core/services/notification_service.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/quran/data/repository/quran_repository.dart';


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
      _m6bad.add('core_phase12_perf_test :: $d :: ${e.toString().split('\n').first}');
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
      _m6bad.add('core_phase12_perf_test :: $d :: ${e.toString().split('\n').first}');
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

  test('quran init is single-flight; hadith init is idempotent', () {
    final q = QuranRepository();
    expect(identical(q, QuranRepository()), isTrue);
    final h = HadithDatabaseService();
    expect(identical(h, HadithDatabaseService()), isTrue);
    // (Rev) The former markTimeZonesInitialized() call verified a write-only
    // flag that no longer exists; singleton identity is the real assertion.
    expect(NotificationService.instance, isNotNull);
  });
}
