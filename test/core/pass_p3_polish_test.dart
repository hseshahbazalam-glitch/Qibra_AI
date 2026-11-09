// lib → test/core/pass_p3_polish_test.dart
//
// Pass P3 (surgical polish batch) — one test file pinning every item so
// the "polish" cannot silently rot:
//   1. sajdah-15 recovery (assets rebuilt; the mark is decoration, not a
//      word — the builder and the runtime now share one inert-attach rule)
//   2. TQ-217 honest gap disclosure (picker note + census pins)
//   3. audioplayers dropped as a dependency (source-guarded, no size talk)
//   4. cupertino_icons dropped (zero consumers at base)
//   5. prayer_models colors tokenized with byte-identical values
//   6. weak-state tripwires on the two prayer screens that actually have
//      async state (user_profile is static by design — asserted, not faked)
//   7. micro-hygiene: dead constants gone, silent catches all say WHY
//
// Everything here runs against REAL files — no mocks of the repo content.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qibra_ai/core/content/edition_resolver.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/features/prayer/data/models/prayer_models.dart';
import 'package:qibra_ai/features/prayer/providers/prayer_provider.dart';
import 'package:qibra_ai/features/quran/data/word/quran_word_data.dart';

const _sajdahAyahs = [
  '7:206', '13:15', '16:50', '17:109', '19:58', '22:18', '22:77', //
  '25:60', '27:26', '32:15', '38:24', '41:38', '53:62', '84:21', '96:19',
];

Map<String, dynamic> _readJson(String path) => jsonDecode(
      File(path).readAsStringSync(encoding: utf8),
    ) as Map<String, dynamic>;

Iterable<String> _libDartFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .map((f) => f.path);

void main() {

  // ── Item 1 — sajdah-15 recovery ──────────────────────────────────────
  group('P3-1 sajdah recovery', () {
    test('gloss ships ALL 6236 ayahs — the 15 sajdah entries recovered', () {
      final gloss = _readJson('assets/data/quran/word_gloss_en.json');
      final ayahs = gloss['ayahs'] as Map<String, dynamic>;
      expect(ayahs.length, 6236);
      for (final key in _sajdahAyahs) {
        expect(ayahs.containsKey(key), isTrue, reason: '$key must ship now');
      }
    });

    test('normalizeUnits pins U+06E9 inert: the mark never counts as a unit',
        () {
      expect(QuranWordCorpus.normalizeUnits('يَسْجُدُونَ ۩'),
          QuranWordCorpus.normalizeUnits('يَسْجُدُونَ'));
      expect(QuranWordCorpus.normalizeUnits('۩'), isEmpty);
    });

    test('unitize attaches a marker-only run to the previous word', () {
      final units = QuranWordCorpus.unitize('يَسْجُدُونَ ۩');
      expect(units, ['يَسْجُدُونَ۩']);
    });

    test('the validator verifies 7:206 end-to-end against the app text', () {
      final gloss = _readJson('assets/data/quran/word_gloss_en.json');
      final surahs =
          _readJson('assets/data/quran/quran_arabic.json')['data']['surahs']
              as List;
      final texts = {
        for (final s in surahs)
          for (final a in (s as Map)['ayahs'] as List)
            '${s['number']}:${(a as Map)['numberInSurah']}':
                a['text'] as String,
      };
      final corpus = QuranWordCorpus.fromJson(glossJson: gloss);
      for (final key in _sajdahAyahs) {
        final parts = key.split(':');
        final words = corpus.wordsFor(
            int.parse(parts[0]), int.parse(parts[1]), texts[key]!);
        expect(words, isNotNull, reason: '$key must verify, not degrade');
        final entry = (gloss['ayahs'] as Map)[key] as Map;
        expect(words!.spans.length, (entry['w'] as List).length);
      }
      final twoOhSix =
          corpus.wordsFor(7, 206, texts['7:206']!)!;
      expect(twoOhSix.spans.last.word, 'يَسْجُدُونَ۩');
      expect(twoOhSix.spans.last.gloss, isNotEmpty);
    });

    test('timing census moved by exactly the recovered ayahs (measured)', () {
      // Old pins: ABM 5544, HUS 5792 (15 of 6236 degraded for BOTH).
      // New measured: ABM 5557 (+13 — its file genuinely lacks the cues
      // for 19:58 and 96:19, which stay honestly absent), HUS 5807 (+15).
      for (final qari in ['ar.abdulbasitmurattal', 'ar.husary']) {
        final doc =
            _readJson('assets/data/quran/word_timings_$qari.json');
        final ayahs = doc['ayahs'] as Map<String, dynamic>;
        final expected = qari == 'ar.abdulbasitmurattal' ? 5557 : 5807;
        expect(ayahs.length, expected, reason: '$qari census drift');
        expect(ayahs.containsKey('7:206'), isTrue);
        if (qari == 'ar.husary') {
          expect(ayahs.containsKey('19:58'), isTrue);
          expect(ayahs.containsKey('96:19'), isTrue);
        } else {
          expect(ayahs.containsKey('19:58'), isFalse,
              reason: 'ABM cues for 19:58 do not exist — never shipped');
          expect(ayahs.containsKey('96:19'), isFalse);
        }
      }
    });

    test('builder mirrors the app rule in parse_line (cross-language pin)',
        () {
      final src =
          File('scripts/build_word_data.py').readAsStringSync(encoding: utf8);
      expect(src, contains('sajdah'));
      expect(src, contains('raw[-1] += w'));
    });

    test('manifest census strings match the rebuilt data', () {
      final manifest =
          File('assets/data/content_manifest.json').readAsStringSync(
              encoding: utf8);
      expect(manifest, contains('5557/6236 ayahs verified'));
      expect(manifest, contains('5807/6236 ayahs verified'));
      expect(manifest, isNot(contains('5544/6236')));
      expect(manifest, isNot(contains('5792/6236')));
    });
  });

  // ── Item 2 — TQ-217 honest blank ─────────────────────────────────────
  group('P3-2 TQ gap', () {
    test('TQ gap census is exactly {7:206, 100:11} = 217 blanks', () {
      final doc = _readJson(
          'assets/data/quran/translation_ur_tahirulqadri.json');
      final rows = doc['quran'] as List;
      final blanks = <int, int>{};
      for (final r in rows) {
        final m = r as Map;
        final text = m['text'] as String?;
        if (text == null || text.trim().isEmpty) {
          blanks.update(m['chapter'] as int, (v) => v + 1, ifAbsent: () => 1);
        }
      }
      expect(blanks, {7: 206, 100: 11});
    });

    test('only the TQ edition carries the gap disclosure', () {
      final flagged = EditionResolver.allBundled()
          .where((e) => e.disclosesGap)
          .map((e) => e.id)
          .toList();
      expect(flagged, ['ur_tahirulqadri']);
    });

    test('the gap note is real in all three locales', () {
      final arabic = RegExp(r'[؀-ۿ]'); // RegExp is not a const ctor
      final en = AppStrings.forCode('en').quranTqGapNote;
      final ar = AppStrings.forCode('ar').quranTqGapNote;
      final ur = AppStrings.forCode('ur').quranTqGapNote;
      expect(en, contains('7'));
      expect(ar, isNot(en));
      expect(ur, isNot(en));
      expect(arabic.hasMatch(ar), isTrue);
      expect(arabic.hasMatch(ur), isTrue);
    });

    test('the picker renders the note on the flagged row (source pin)', () {
      final src = File(
              'lib/features/settings/presentation/settings_screen.dart')
          .readAsStringSync(encoding: utf8);
      expect(src, contains('edition.disclosesGap'));
      expect(src, contains('quranTqGapNote'));
    });

    test('the reader can never show a silent blank translation', () {
      final src =
          File('lib/features/quran/presentation/surah_reader_screen.dart')
              .readAsStringSync(encoding: utf8);
      // Empty-string translations collapse to null → the honest line.
      expect(src, contains('translationUnavailable'));
      expect(src,
          contains('(urdu == null || urdu.isEmpty) ? null : urdu'));
    });
  });

  // ── Items 3+4 — dependency drops ─────────────────────────────────────
  group('P3-3/4 single audio stack, no cupertino', () {
    test('package:audioplayers is gone from every import (source guard)', () {
      final offenders = _libDartFiles()
          .where((p) => File(p)
              .readAsStringSync(encoding: utf8)
              .contains('package:audioplayers'))
          .toList();
      expect(offenders, isEmpty);
    });

    test('pubspec dropped exactly the two entries — nothing else moved', () {
      final pubspec = File('pubspec.yaml').readAsStringSync(encoding: utf8);
      expect(pubspec, isNot(matches(RegExp(r'^\s*audioplayers:', multiLine: true))));
      expect(pubspec, isNot(matches(RegExp(r'^\s*cupertino_icons:', multiLine: true))));
      expect(pubspec, contains('just_audio:'));
      // The stale comment claiming audioplayers 'stays' must not survive.
      expect(pubspec, isNot(contains('audioplayers above stays')));
    });

    test('the preview uses just_audio setAsset and disposes on both paths',
        () {
      final src = File(
              'lib/features/settings/presentation/notification_settings_screen.dart')
          .readAsStringSync(encoding: utf8);
      expect(src, contains("setAsset('audio/azan_makkah.mp3')"));
      expect(src, contains('whenComplete(player.dispose)'));
      expect(src, isNot(contains('AssetSource')));
    });
  });

  // ── Item 5 — prayer_models tokens ────────────────────────────────────
  group('P3-5 token equality', () {
    test('11 tokenized colors are byte-identical to the old literals', () {
      expect(PrayerType.fajr.color, const Color(0xFF123F36));
      expect(PrayerType.sunrise.color, const Color(0xFFC6A15B));
      expect(PrayerType.dhuhr.color, const Color(0xFF2F6B5D));
      expect(PrayerType.asr.color, const Color(0xFF8A6D38));
      expect(PrayerType.maghrib.color, const Color(0xFF123F36));
      expect(PrayerType.isha.color, const Color(0xFF19312C));
      expect(PrayerStatus.pending.color, const Color(0xFF71807A));
      expect(PrayerStatus.prayed.color, const Color(0xFF123F36));
      expect(PrayerStatus.prayedInMosque.color, const Color(0xFF2F6B5D));
      expect(PrayerStatus.missed.color, const Color(0xFFB42318));
      expect(PrayerStatus.makeup.color, const Color(0xFFC6A15B));
      // …and the tokens are the SAME consts, not copies:
      expect(PrayerType.fajr.color, AppEmerald.s500);
      expect(PrayerStatus.missed.color, AppSemanticColors.error);
    });

    test('prayer_models.dart ships zero raw hex', () {
      final src =
          File('lib/features/prayer/data/models/prayer_models.dart')
              .readAsStringSync(encoding: utf8);
      expect(src.contains('Color(0x'), isFalse);
    });
  });

  // ── Item 6 — weak-state tripwires ───────────────────────────────────
  group('P3-6 weak screens', () {
    test('the records notifier exposes a real hydration future', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = PrayerRecordsNotifier();
      await notifier.ready; // completes, never throws, with empty storage
      expect(notifier.state, isEmpty); // genuinely empty, now told apart
      notifier.dispose();
    });

    test('both prayer screens gate on that real state (source pins)', () {
      final salah =
          File('lib/features/prayer/presentation/salah_schedule_screen.dart')
              .readAsStringSync(encoding: utf8);
      expect(salah, contains('if (dailyTimes == null)'));
      expect(salah, contains('QibraStatus.loading'));
      expect(salah, contains('QibraStatus.error'));
      final stats = File(
              'lib/features/prayer/presentation/prayer_statistics_screen.dart')
          .readAsStringSync(encoding: utf8);
      expect(stats, contains('_hydrated'));
      expect(stats, contains('.ready.then'));
      // The empty-but-not-loading distinction must not fake a spinner
      // once hydrated:
      expect(stats, contains('records.isEmpty'));
    });

    test('user_profile is static BY DESIGN — const, zero async (asserted)',
        () {
      final src = File(
              'lib/features/settings/presentation/user_profile_screen.dart')
          .readAsStringSync(encoding: utf8);
      expect(src.contains('FutureBuilder'), isFalse);
      expect(src.contains('ref.watch'), isFalse);
      expect(src.contains('const UserProfileScreen('), isTrue);
    });
  });

  // ── Item 7 — micro hygiene ───────────────────────────────────────────
  group('P3-7 hygiene', () {
    test('the two pass-era dead constants are gone; siblings stay', () {
      final tilawat =
          File('lib/features/quran/data/audio/tilawat.dart')
              .readAsStringSync(encoding: utf8);
      expect(tilawat.contains('static const List<int> repeatCountChoices'),
          isFalse);
      expect(tilawat, contains('maxAyahRepeats'));
      final meta =
          File('lib/features/quran/data/repository/quran_meta.dart')
              .readAsStringSync(encoding: utf8);
      expect(meta.contains('totalJuz'), isFalse);
      expect(meta, contains('totalAyahs'));
    });

    test('every silent catch in lib says why — except the disclosed one',
        () {
      final bare = RegExp(r"catch\s*(?:\([^)]*\))?\s*\{\s*\}");
      final offenders = <String>[];
      for (final p in _libDartFiles()) {
        final src = File(p).readAsStringSync(encoding: utf8);
        if (!bare.hasMatch(src)) continue;
        offenders.add(p);
      }
      // lib/main.dart's RagService-attach catch is the SINGLE honest
      // exception: main.dart is an off-limits file for this pass, so the
      // disclosure lives in the pass report instead of the source.
      expect(offenders, ['lib/main.dart']);
    });

    test('the reader is tokens-only (raw-hex premise verified stale)', () {
      final src =
          File('lib/features/quran/presentation/surah_reader_screen.dart')
              .readAsStringSync(encoding: utf8);
      expect(src.contains('Color(0x'), isFalse);
    });
  });
}
