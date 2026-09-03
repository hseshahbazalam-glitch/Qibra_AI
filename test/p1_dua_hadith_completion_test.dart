// test/p1_dua_hadith_completion_test.dart
// ============================================================
// P1 completion pass: dua reminders (policy math), hadith view
// history (LRU store), same-chapter selection, and the wiring pins
// that keep the UI glued to the real services. No plugin is loaded —
// scheduling itself is proven by the existing adhkar/Tahajjud path
// this reuses; here we pin that the call sites exist.
// ============================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/notifications/dua_reminder_policy.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_view_history.dart';
import 'package:qibra_ai/features/hadith/presentation/hadith_related_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('dua reminder policy', () {
    test('defaults mirror the app adhkar times', () {
      expect(
        DuaReminderPolicy.defaultFor(
            category: 'morning_evening', titleEnglish: 'Morning — Waking Up'),
        const DuaReminderTime(7, 0),
      );
      expect(
        DuaReminderPolicy.defaultFor(
            category: 'morning_evening', titleEnglish: 'Evening Remembrance'),
        const DuaReminderTime(17, 30),
      );
      expect(
        DuaReminderPolicy.defaultFor(
            category: 'sleep', titleEnglish: 'Before Sleeping'),
        const DuaReminderTime(22, 0),
      );
      expect(
        DuaReminderPolicy.defaultFor(
            category: 'protection', titleEnglish: 'Morning & Evening Protection'),
        const DuaReminderTime(17, 30), // evening wins by documented order
      );
      expect(
        DuaReminderPolicy.defaultFor(
            category: 'travel', titleEnglish: 'Travel Departure'),
        const DuaReminderTime(8, 0),
      );
    });

    test('nextOccurrence stays today when due, else rolls over', () {
      const t = DuaReminderTime(7, 0);
      expect(t.nextOccurrence(DateTime(2026, 9, 3, 6, 0)),
          DateTime(2026, 9, 3, 7, 0));
      expect(t.nextOccurrence(DateTime(2026, 9, 3, 7, 0)),
          DateTime(2026, 9, 4, 7, 0),
          reason: 'exact now must not schedule in the past');
      expect(t.nextOccurrence(DateTime(2026, 9, 3, 23, 30)),
          DateTime(2026, 9, 4, 7, 0));
    });

    test('title/body truncated to one line within budget', () {
      final long = 'x' * 120;
      final out = DuaReminderPolicy.truncateTitle(long);
      expect(out.length, lessThanOrEqualTo(DuaReminderPolicy.maxTitleChars));
      expect(out.endsWith('…'), isTrue);
      expect(DuaReminderPolicy.truncateTitle('a\n\nb'), 'a b');
      expect(
        DuaReminderPolicy.truncateBody('y' * 500).length,
        lessThanOrEqualTo(DuaReminderPolicy.maxBodyChars),
      );
    });

    test('prefs entry roundtrips; malformed entries are skipped', () {
      final raw = DuaReminderPolicy.encodeEntry('me_001', 7, 30);
      final p = DuaReminderPolicy.parseEntry(raw);
      expect(p, isNotNull);
      expect(p!.duaId, 'me_001');
      expect(p.time, const DuaReminderTime(7, 30));
      expect(DuaReminderPolicy.parseEntry('no-pipe'), isNull);
      expect(DuaReminderPolicy.parseEntry('a|99|0'), isNull);
      expect(DuaReminderPolicy.parseEntry('|7|0'), isNull);
    });

    test('label is 12-hour zero-padded', () {
      expect(const DuaReminderTime(7, 0).label, '07:00 AM');
      expect(const DuaReminderTime(17, 30).label, '05:30 PM');
      expect(const DuaReminderTime(0, 5).label, '12:05 AM');
      expect(const DuaReminderTime(12, 0).label, '12:00 PM');
    });
  });

  group('hadith view history (persisted LRU)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('record dedupes to front and caps at 50', () async {
      for (int i = 1; i <= 55; i++) {
        await HadithViewHistory.record('bukhari', i);
      }
      var entries = await HadithViewHistory.entries();
      expect(entries.length, HadithViewHistory.cap);
      expect(entries.first, 'bukhari#55');
      expect(entries.last, 'bukhari#6');

      await HadithViewHistory.record('bukhari', 20);
      entries = await HadithViewHistory.entries();
      expect(entries.first, 'bukhari#20');
      expect(entries.where((e) => e == 'bukhari#20').length, 1);
      expect(entries.length, HadithViewHistory.cap);
    });

    test('record ignores empty slug and non-positive numbers', () async {
      await HadithViewHistory.record('', 5);
      await HadithViewHistory.record('muslim', 0);
      expect(await HadithViewHistory.entries(), isEmpty);
    });

    test('clear empties the store', () async {
      await HadithViewHistory.record('muslim', 1);
      await HadithViewHistory.clear();
      expect(await HadithViewHistory.entries(), isEmpty);
    });

    test('parseRef accepts only honest refs', () {
      expect(HadithViewHistory.parseRef('bukhari#12'),
          (bookSlug: 'bukhari', hadithNumber: 12));
      expect(HadithViewHistory.parseRef('#5'), isNull);
      expect(HadithViewHistory.parseRef('bukhari#'), isNull);
      expect(HadithViewHistory.parseRef('bukhari#x'), isNull);
      expect(HadithViewHistory.parseRef('bukhari#0'), isNull);
    });
  });

  group('more-from-chapter selection (real same-chapter only)', () {
    LocalHadith h(int n) => LocalHadith(
          hadithNumber: n,
          arabicNumber: n,
          textArabic: '',
          textEnglish: 'english $n',
          textUrdu: '',
          bookSlug: 'bukhari',
          bookName: 'Sahih al-Bukhari',
          bookNumber: 3,
          chapterHadithNumber: n,
          chapterName: 'Chapter of Knowledge',
          grade: '',
        );

    test('caps at 10 and excludes the current hadith', () {
      final chapter = List.generate(25, (i) => h(i + 1));
      final out = selectMoreFromChapter(
        chapterHadiths: chapter,
        currentHadithNumber: 7,
      );
      expect(out.length, 10);
      expect(out.any((x) => x.hadithNumber == 7), isFalse);
      expect(out.map((x) => x.hadithNumber).take(4).toList(), [1, 2, 3, 4]);
    });

    test('empty or unknown chapter yields nothing', () {
      expect(
        selectMoreFromChapter(chapterHadiths: const [], currentHadithNumber: 1),
        isEmpty,
      );
      final only = [h(9)];
      expect(
        selectMoreFromChapter(
            chapterHadiths: only, currentHadithNumber: 9),
        isEmpty,
      );
    });

    test('cap is respected from the head of the chapter', () {
      final chapter = List.generate(40, (i) => h(i + 1));
      final out = selectMoreFromChapter(
        chapterHadiths: chapter,
        currentHadithNumber: 999, // not in chapter
      );
      expect(out.length, 10);
    });
  });

  group('wiring pins — UI glued to the real services', () {
    test('dua reminder schedules through NotificationService and taps route',
        () {
      final svc =
          File('lib/core/services/notification_service.dart')
              .readAsStringSync();
      expect(svc.contains("payload: 'dua:\$duaId'"), isTrue);
      expect(svc.contains('Future<void> setDuaReminder('), isTrue);
      expect(svc.contains('Future<void> removeDuaReminder('), isTrue);
      expect(svc.contains('Future<DuaReminderTime?> duaReminderFor('), isTrue);
      expect(svc.contains('dispatchNotificationTap(response.payload)'), isTrue,
          reason: 'the previously-empty tap callback must dispatch payloads');
      expect(svc.contains('static set onNotificationTap('), isTrue);

      final detail = File('lib/features/duas/presentation/dua_detail_screen.dart')
          .readAsStringSync();
      expect(detail.contains('setDuaReminder('), isTrue);
      expect(detail.contains('removeDuaReminder('), isTrue);
      expect(detail.contains('duaReminderFor('), isTrue);
      expect(detail.contains('showTimePicker('), isTrue);
      expect(detail.contains("'Daily Reminder'"), isTrue);

      final main = File('lib/main.dart').readAsStringSync();
      expect(main.contains('NotificationService.onNotificationTap'), isTrue);
      expect(main.contains("startsWith('dua:')"), isTrue);
      expect(main.contains('AppRoutes.duaDetail'), isTrue);
      expect(main.contains('WidgetsFlutterBinding.instance'), isFalse,
          reason: 'no such static on stable Flutter — '
              'WidgetsBinding.instance is the version-safe receiver (G13)');

      final router = File('lib/core/router/app_router.dart').readAsStringSync();
      expect(router.contains('navigatorKey: rootNavigatorKey'), isTrue);
      expect(router.contains('AppRoutes.duaDetail'), isTrue);
      expect(
          router.contains('DuaDetailScreen(duaId: state.uri.queryParameters'),
          isTrue);
    });

    test('AI explain takes dua context; dua detail offers it in violet', () {
      final ai = File('lib/features/ai/presentation/ai_explain_screen.dart')
          .readAsStringSync();
      expect(ai.contains('this.duaTitle'), isTrue);
      expect(ai.contains('this.duaArabic'), isTrue);
      expect(ai.contains('this.duaTranslation'), isTrue);
      expect(ai.contains("'What is the significance of this dua?'"), isTrue);
      expect(ai.contains('_buildDuaContext'), isTrue);
      expect(ai.contains("if (widget.ayahText != null || widget._hasDuaContext)"),
          isTrue,
          reason: 'initial question must fire for dua context too');

      final detail = File('lib/features/duas/presentation/dua_detail_screen.dart')
          .readAsStringSync();
      expect(detail.contains('AIExplainScreen('), isTrue);
      expect(detail.contains('duaTitle: dua.titleEnglish'), isTrue);
      expect(detail.contains('QibraNavy.violet'), isTrue,
          reason: 'violet marks the AI surface only');
    });

    test('hadith detail opens record history; both sheets show the section',
        () {
      final book = File('lib/features/hadith/presentation/hadith_book_screen.dart')
          .readAsStringSync();
      final home = File('lib/features/hadith/presentation/hadith_screen.dart')
          .readAsStringSync();
      expect(book.contains('recordHadithView(ref, hadith)'), isTrue);
      expect(home.contains('recordHadithView(ref, hadith)'), isTrue);
      expect(book.contains('HadithMoreFromChapter('), isTrue);
      expect(home.contains('HadithMoreFromChapter('), isTrue);
      expect(home.contains("'Recently Read'"), isTrue);
      expect(home.contains('HadithViewHistory.clear()'), isTrue);

      final provider =
          File('lib/features/hadith/providers/hadith_provider.dart')
              .readAsStringSync();
      expect(provider.contains('final hadithHistoryProvider = FutureProvider'),
          isTrue);
    });

    test('related section is labeled by position, never as AI similarity',
        () {
      final section =
          File('lib/features/hadith/presentation/hadith_related_section.dart')
              .readAsStringSync();
      expect(section.contains("'More from this chapter'"), isTrue);
      expect(section.contains('by position, not AI'), isTrue);
      expect(section.contains('return const SizedBox.shrink();'), isTrue,
          reason: 'missing chapter metadata must render nothing');
    });

    test('no share package snuck in, no new permission either', () {
      final pub = File('pubspec.yaml').readAsStringSync();
      expect(RegExp(r'^\s*share_\w+:', multiLine: true).hasMatch(pub), isFalse);
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest.contains('POST_NOTIFICATIONS'), isTrue,
          reason: 'already declared by the app; this pass must not touch it');
      expect(manifest.contains('RECORD_AUDIO'), isFalse);
    });
  });
}
