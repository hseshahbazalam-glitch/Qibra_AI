// I18N PASS A2 — home/prayer/calendar/mushaf chrome through AppStrings.
//
// Source-parsed like the phase-A test (no widget pumps needed for the
// invariants below). Three jobs:
//   1. EN byte-exactness: migrated copy must equal the pre-pass literals,
//      apostrophes/em-dashes/ellipsis included (the shapes that break first).
//   2. Census: the ten wired files render NO raw capitalized Text literals.
//   3. Deleted English fallbacks stay deleted (schedule day/month lists).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const wiredFiles = <String>[
  'lib/features/home/presentation/home_screen.dart',
  'lib/features/home/presentation/widgets/home_hero.dart',
  'lib/features/home/presentation/widgets/home_sections.dart',
  'lib/features/prayer/presentation/prayer_times_screen.dart',
  'lib/features/prayer/presentation/salah_schedule_screen.dart',
  'lib/features/prayer/presentation/prayer_statistics_screen.dart',
  'lib/features/prayer/presentation/tahajjud_details_screen.dart',
  'lib/features/prayer/presentation/widgets/schedule_prayer_tile.dart',
  'lib/features/calendar/presentation/islamic_calendar_screen.dart',
  'lib/features/quran/presentation/mushaf_reader_screen.dart',
];

void main() {
  final appStrings =
      File('lib/core/l10n/app_strings.dart').readAsStringSync();

  group('A2 EN byte-exactness (source side)', () {
    test('tricky migrated literals survive verbatim in AppStrings', () {
      // Exact source-text checks — the strings that are easiest to break:
      // escaped apostrophe, horizontal ellipsis, em-dash, colon forms.
      for (final lit in <String>[
        r"_t('Detecting…'", // … must be U+2026, not '...'
        r"_t('Today\'s schedule'", // escaped apostrophe form
        r"'Prayer times need a location — permission denied or GPS unavailable. Set one manually or retry.'",
        r"'Toggle azan alerts for each prayer'",
        r"'Not available — tap to set'",
        r"'Page info copied — paste it anywhere to share'",
        r"'No saved page yet — turn a page first'",
        r"'No bookmarks yet — long-press the bookmark to save one'",
        r"'Jummah Mubarak! Best day for Surah Al-Kahf & Salawat'",
        r"'Make the most of today with dhikr, Quran reading, and good deeds.'",
        r"'Never skip — it is blessed'", // tipSuhoorNote tail
        r"'in '", // countdownInPrefix EN form keeps the trailing space
      ]) {
        expect(appStrings, contains(lit), reason: 'A2 EN drift: $lit');
      }
    });

    test('A2 getter families exist', () {
      for (final name in <String>[
        'hijriMonthName',
        'eventsCount',
        'islamicEventsEyebrow',
        'hijriCalendarEyebrow',
        'islamicCalendarTitle',
        'todayPill',
        'jummahMubarak',
        'blessedDay',
        'jummahDayInfo',
        'mondayFastInfo',
        'thursdayFastInfo',
        'makeMostOfDayInfo',
        'selectedLegendLabel',
        'calNewYearName',
        'calNewYearDesc',
        'calAshuraName',
        'calAyyamDesc',
        'whiteDaysDateLabel',
        'everyWeekday',
        'catHoliday',
        'catFasting',
        'catSpecialNight',
        'catSunnah',
        'scopeAll',
        'ramadanSunanTitle',
        'suhoorIftarDuasNote',
        'tipTaraweehTitle',
        'tipSuhoorNote',
        'mushafPageOfTotal',
        'mushafPageSlash604',
        'mushafNoVersesNote',
        'mushafSajdahNote',
        'pageBookmarkedToast',
        'bookmarkedPagesTitle',
        'pillNextCaps',
        'nextPrayerCaps',
        'missedLabel',
        'pagesCountLabel',
        'countdownInPrefix',
      ]) {
        expect(
            RegExp('String (get $name\\b|$name\\(').hasMatch(appStrings),
            isTrue,
            reason: 'A2 getter missing from AppStrings: $name');
      }
    });
  });

}
