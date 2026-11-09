
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/features/prayer/data/services/next_prayer_engine.dart';

void main() {
  // M6RED-REPORT (transient): name the culprit test on failure —
  // same annotation channel as the M5 TALLY, one tearDown, deleted
  // with the probe commit.
  tearDown(() {
    if (testState == TestState.failed) {
      print('::error::M6RED ${testCase.name}');
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
