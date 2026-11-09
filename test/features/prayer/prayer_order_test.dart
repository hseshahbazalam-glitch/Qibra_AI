
import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;
import 'package:qibra_ai/features/prayer/data/services/next_prayer_engine.dart';


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
      _m6bad.add('features_prayer_prayer_order_test :: $d :: ${e.toString().split('\n').first}');
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
      _m6bad.add('features_prayer_prayer_order_test :: $d :: ${e.toString().split('\n').first}');
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

  test('after Isha next is tomorrow Fajr', () {
    final now = DateTime(2026, 8, 28, 23, 10);
    final result = NextPrayerEngine.next(
      now: now,
      today: [
        NamedPrayerInstant(name: 'Fajr', time: DateTime(2026, 8, 28, 5, 0)),
        NamedPrayerInstant(name: 'Isha', time: DateTime(2026, 8, 28, 20, 0)),
      ],
      tomorrowFajr: NamedPrayerInstant(
        name: 'Fajr',
        time: DateTime(2026, 8, 29, 5, 1),
      ),
    );
    expect(result, isNotNull);
    expect(result!.name, 'Fajr');
    expect(result.isTomorrow, isTrue);
    expect(result.countdown.isNegative, isFalse);
  });
}
