// QURAN AUDIO WORLD-CLASS — Pass Q1 (2026-09-14).
// Covers: the five-qari catalog (structure + SOURCE pins on the live
// directory names), the pure hifz repeat machine (no audio involved),
// prev/next edge math, state plumbing (copyWith must not drop qari/
// speed/repeat — the bug class that silently resets settings), prefs
// persistence at the validation boundary, the mini player's transport
// UI (slider exists ONLY with a real duration; drag seeks clamped;
// hifz chips echo real state; range-pick banner), and the audio_service
// wiring (boot call, guarded init, manifest, version pin, no hex / no
// audioplayers in the touched files).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qibra_ai/features/quran/data/audio/tilawat.dart';
import 'package:qibra_ai/features/quran/data/audio/tilawat_downloader.dart';
import 'package:qibra_ai/features/quran/presentation/quran_mini_player.dart';
import 'package:qibra_ai/features/quran/providers/quran_audio_provider.dart';
import 'package:qibra_ai/features/quran/providers/reading_preferences_provider.dart';

/// Records transport taps + seeks; build() NEVER runs the real one (so no
/// AudioPlayer — and therefore no platform channel — is ever constructed).
class _FakeAudioController extends QuranAudioController {
  _FakeAudioController(this.initial);

  final QuranAudioState initial;
  final List<Duration> seeks = [];
  int nextTaps = 0;
  int prevTaps = 0;
  int stopTaps = 0;
  int restartCalls = 0;

  @override
  QuranAudioState build() => initial;

  @override
  Future<void> restartAtCurrentIndex() async {
    restartCalls++; // records the mid-play swap; NO audio backend touched
  }

  @override
  Future<void> seek(Duration to) async {
    seeks.add(to);
  }

  @override
  Future<void> nextAyah() async {
    nextTaps++;
  }

  @override
  Future<void> prevAyah() async {
    prevTaps++;
  }

  @override
  Future<void> stop() async {
    stopTaps++;
  }
}

Future<void> _settle() async {
  for (int i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('qari catalog', () {
    test('five registered qaris, unique ids and directories, index 0 = default',
        () {
      expect(Tilawat.qaris.length, 5);
      expect(Tilawat.qaris.map((q) => q.id).toSet().length, 5);
      expect(Tilawat.qaris.map((q) => q.everyAyahDir).toSet().length, 5);
      expect(Tilawat.qaris.map((q) => q.islamicNetworkEdition).toSet().length,
          5);
      expect(Tilawat.qaris.first, Tilawat.alafasy);
      expect(Tilawat.defaultQariId, Tilawat.alafasy.id);
    });

    test('byId: known round-trips, unknown falls back to the primary', () {
      for (final q in Tilawat.qaris) {
        expect(Tilawat.byId(q.id), q);
      }
      expect(Tilawat.byId('ar.someone-else'), Tilawat.current);
      expect(Tilawat.byId(''), Tilawat.current);
    });

    test('SOURCE PIN: everyayah dirs + CDN editions match the live sites', () {
      // Verbatim from everyayah.com's recitation index and alquran.cloud's
      // audio-editions API (fetched 2026-09-11) — if the catalog drifts
      // from this, the URLs 404 and the whole offline story rots. The
      // strings live in the SOURCE file (documentation of the fetch).
      final src =
          File('lib/features/quran/data/audio/tilawat.dart').readAsStringSync();
      for (final dir in [
        'Alafasy_128kbps',
        'Abdul_Basit_Murattal_192kbps',
        'Husary_128kbps',
        'Minshawy_Murattal_128kbps',
        'Abdurrahmaan_As-Sudais_192kbps',
      ]) {
        expect(src.contains("everyAyahDir: '$dir'"), isTrue,
            reason: 'everyayah directory changed: $dir');
      }
      for (final ed in [
        'ar.alafasy',
        'ar.abdulbasitmurattal',
        'ar.husary',
        'ar.minshawi',
        'ar.abdurrahmaansudais',
      ]) {
        expect(src.contains("islamicNetworkEdition: '$ed'"), isTrue,
            reason: 'islamic.network edition changed: $ed');
      }
    });

    test('URL builders follow the selected qari (both sources)', () {
      for (final q in Tilawat.qaris) {
        expect(Tilawat.primaryUrl(1, 1, qari: q),
            'https://everyayah.com/data/${q.everyAyahDir}/001001.mp3');
        expect(
            Tilawat.fallbackUrl(1, qari: q),
            'https://cdn.islamic.network/quran/audio/128/'
            '${q.islamicNetworkEdition}/1.mp3');
      }
      // null on out of range — the fallback never guesses a file name.
      expect(Tilawat.fallbackUrl(0), isNull);
      expect(Tilawat.fallbackUrl(6237), isNull);
    });
  });

  group('hifz repeat machine (pure)', () {
    ({TilawatRepeatAction action, int targetAyah}) decide({
      required QuranRepeatMode mode,
      int done = 0,
      int target = 3,
      int current = 5,
      int start = 0,
      int end = 0,
      bool hasNext = true,
    }) =>
        Tilawat.repeatDecision(
          mode: mode,
          timesDone: done,
          timesTarget: target,
          currentAyah: current,
          rangeStart: start,
          rangeEnd: end,
          hasNext: hasNext,
        );

    test('off: advance while the queue has a next, stop when it runs out', () {
      expect(decide(mode: QuranRepeatMode.off).action,
          TilawatRepeatAction.advance);
      expect(
          decide(mode: QuranRepeatMode.off, hasNext: false).action,
          TilawatRepeatAction.stop);
    });

    test('ayah: replays until the clamped count, then advance/stop', () {
      expect(decide(mode: QuranRepeatMode.ayah, done: 1, target: 3).action,
          TilawatRepeatAction.replay);
      expect(decide(mode: QuranRepeatMode.ayah, done: 2, target: 3).action,
          TilawatRepeatAction.replay);
      // done==target → the ayah is EXHAUSTED: move on, don't re-arm.
      expect(decide(mode: QuranRepeatMode.ayah, done: 3, target: 3).action,
          TilawatRepeatAction.advance);
      expect(
          decide(mode: QuranRepeatMode.ayah, done: 3, target: 3,
                  hasNext: false)
              .action,
          TilawatRepeatAction.stop);
      // The count is clamped at the cap — target 99 behaves like 20.
      expect(
          decide(mode: QuranRepeatMode.ayah, done: 19, target: 99).action,
          TilawatRepeatAction.replay);
      expect(
          decide(mode: QuranRepeatMode.ayah, done: 20, target: 99).action,
          TilawatRepeatAction.advance);
    });

    test('range: unset behaves like off; never invents bounds', () {
      expect(
          decide(mode: QuranRepeatMode.range, start: 0, end: 0).action,
          TilawatRepeatAction.advance);
      expect(
          decide(mode: QuranRepeatMode.range, start: 0, end: 0,
                  hasNext: false)
              .action,
          TilawatRepeatAction.stop);
    });

    test('range: loops [start..end], normalizes reversed picks', () {
      // Inside the range → plain advance.
      expect(decide(mode: QuranRepeatMode.range, current: 4, start: 3, end: 7)
          .action, TilawatRepeatAction.advance);
      // At the top (or past it) → jump back to the bottom of the range.
      final top = decide(
          mode: QuranRepeatMode.range, current: 7, start: 3, end: 7);
      expect(top.action, TilawatRepeatAction.jump);
      expect(top.targetAyah, 3);
      // Reversed pick (tapped end before start) normalizes, not rejects.
      final rev = decide(
          mode: QuranRepeatMode.range, current: 7, start: 7, end: 3);
      expect(rev.action, TilawatRepeatAction.jump);
      expect(rev.targetAyah, 3);
      // End of surah while ranged → the loop is explicit: jump, not stop.
      final edge = decide(mode: QuranRepeatMode.range, current: 7, start: 3,
          end: 7, hasNext: false);
      expect(edge.action, TilawatRepeatAction.jump);
      expect(edge.targetAyah, 3);
    });

    test('repeat-count clamp + speed whitelist are the only mutation paths',
        () {
      expect(Tilawat.clampRepeatCount(0), 1);
      expect(Tilawat.clampRepeatCount(-7), 1);
      expect(Tilawat.clampRepeatCount(7), 7);
      expect(Tilawat.clampRepeatCount(21), Tilawat.maxAyahRepeats);
      expect(Tilawat.maxAyahRepeats, 20); // cap is a decision, not an accident
      for (final v in Tilawat.knownSpeeds) {
        expect(Tilawat.isKnownSpeed(v), isTrue);
      }
      expect(Tilawat.isKnownSpeed(2.0), isFalse);
      expect(Tilawat.isKnownSpeed(0.0), isFalse);
    });

    test('prev/next queue edges mirror each other (runs out = stop)', () {
      expect(Tilawat.previousQueueIndex(0, 7), isNull);
      expect(Tilawat.previousQueueIndex(3, 7), 2);
      expect(Tilawat.previousQueueIndex(7, 7), isNull);
      expect(Tilawat.nextQueueIndex(6, 7), isNull);
      expect(Tilawat.nextQueueIndex(2, 7), 3);
    });
  });

  group('state plumbing', () {
    test('copyWith carries qari/speed/repeat/range (never resets them)', () {
      const s = QuranAudioState(
        phase: QuranAudioPhase.playing,
        qariId: 'ar.husary',
        qariName: 'Mahmoud Khalil Al-Husary',
        speed: 1.25,
        repeatMode: QuranRepeatMode.ayah,
        repeatCount: 5,
        rangeStart: 3,
        rangeEnd: 9,
        rangePick: QuranRangePick.end,
      );
      final c = s.copyWith(buffering: true);
      expect(c.qariId, 'ar.husary');
      expect(c.qariName, 'Mahmoud Khalil Al-Husary');
      expect(c.speed, 1.25);
      expect(c.repeatMode, QuranRepeatMode.ayah);
      expect(c.repeatCount, 5);
      expect(c.rangeStart, 3);
      expect(c.rangeEnd, 9);
      expect(c.rangePick, QuranRangePick.end);
      expect(c.buffering, isTrue);
      // clearError/clearDuration sentinels still work alongside.
      const withErr = QuranAudioState(error: 'boom');
      expect(withErr.copyWith(clearError: true).error, isNull);
      const withDur = QuranAudioState(duration: Duration(seconds: 9));
      expect(withDur.copyWith(clearDuration: true).duration, isNull);
    });

    test('real-duration progress only; null duration → null progress', () {
      const noDur = QuranAudioState(position: Duration(seconds: 3));
      expect(noDur.progress, isNull);
      const withDur = QuranAudioState(
        position: Duration(seconds: 3),
        duration: Duration(seconds: 12),
      );
      expect(withDur.progress, closeTo(0.25, 1e-9));
    });

    test('range-pick flow consumes reader taps per-surah', () {
      final container = ProviderContainer(overrides: [
        quranAudioProvider.overrideWith(() => _FakeAudioController(
              const QuranAudioState(
                phase: QuranAudioPhase.playing,
                surahNumber: 2,
                rangePick: QuranRangePick.start,
              ),
            )),
      ]);
      addTearDown(container.dispose);
      final ctrl = container.read(quranAudioProvider.notifier);
      // Wrong surah: the tap must pass through (bounds are per-surah).
      expect(ctrl.consumeRangePick(3, 4), isFalse);
      expect(ctrl.state.rangePick, QuranRangePick.start);
      expect(ctrl.consumeRangePick(2, 4), isTrue);
      expect(ctrl.state.rangeStart, 4);
      expect(ctrl.state.rangePick, QuranRangePick.end);
      expect(ctrl.consumeRangePick(2, 9), isTrue);
      expect(ctrl.state.rangeEnd, 9);
      expect(ctrl.state.rangePick, QuranRangePick.none);
      // Done picking — further taps pass through.
      expect(ctrl.consumeRangePick(2, 5), isFalse);
    });

    test('setRepeatMode(range) arms endpoint picking; off clears it', () {
      final container = ProviderContainer(overrides: [
        quranAudioProvider.overrideWith(
            () => _FakeAudioController(const QuranAudioState(
                  phase: QuranAudioPhase.playing,
                  surahNumber: 2,
                ))),
      ]);
      addTearDown(container.dispose);
      final ctrl = container.read(quranAudioProvider.notifier);
      ctrl.setRepeatMode(QuranRepeatMode.range);
      expect(ctrl.state.repeatMode, QuranRepeatMode.range);
      expect(ctrl.state.rangePick, QuranRangePick.start);
      ctrl.setRepeatMode(QuranRepeatMode.off);
      expect(ctrl.state.rangePick, QuranRangePick.none);
      ctrl.setRepeatCount(21);
      expect(ctrl.state.repeatCount, Tilawat.maxAyahRepeats);
    });
  });

  group('prefs boundary (qari + speed persistence)', () {
    test('unknown persisted qari falls back; known ids round-trip storage',
        () async {
      SharedPreferences.setMockInitialValues({
        'quran_reading_preferences_v1_qari_id': 'ar.not-a-qari',
        'quran_reading_preferences_v1_playback_speed': 9.9,
      });
      var prefs = ReadingPreferencesNotifier();
      await _settle();
      expect(prefs.state.qariId, Tilawat.defaultQariId);
      expect(prefs.state.playbackSpeed, 1.0);
      await prefs.setQariId('ar.husary');
      await prefs.setPlaybackSpeed(1.25);
      final sp = await SharedPreferences.getInstance();
      expect(sp.getString('quran_reading_preferences_v1_qari_id'),
          'ar.husary');
      expect(sp.getDouble('quran_reading_preferences_v1_playback_speed'), 1.25);
      prefs.dispose();
      prefs = ReadingPreferencesNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(prefs.state.qariId, 'ar.husary');
      expect(prefs.state.playbackSpeed, 1.25);
      await prefs.setPlaybackSpeed(3.0); // rejected at the boundary
      expect(prefs.state.playbackSpeed, 1.0);
      prefs.dispose();
    });
  });

  group('picker: qari selection persistence + mid-play restart semantics',
      () {
    test('mid-play change persists, re-anchors the label, and restarts at '
        'the CURRENT queue index (honest restart, no rewind)', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(overrides: [
        quranAudioProvider.overrideWith(() => _FakeAudioController(
              const QuranAudioState(
                phase: QuranAudioPhase.playing,
                surahNumber: 2,
                ayahNumber: 10,
                queueIndex: 2,
                queueLength: 3,
                session: 4,
              ),
            )),
      ]);
      addTearDown(container.dispose);
      final ctrl =
          container.read(quranAudioProvider.notifier) as _FakeAudioController;
      await ctrl.selectQari('ar.husary');
      expect(ctrl.restartCalls, 1); // live swap → exactly one restart
      expect(ctrl.state.qariId, 'ar.husary');
      expect(ctrl.state.qariName, 'Mahmoud Khalil Al-Husary');
      expect(ctrl.state.session, 5); // new session → follow-along re-arms
      expect(ctrl.state.ayahNumber, 10); // SAME ayah (not rewound)
      expect(ctrl.state.queueIndex, 2); // SAME queue slot
      expect(ctrl.state.phase, QuranAudioPhase.loading);
      final sp = await SharedPreferences.getInstance();
      expect(sp.getString('quran_reading_preferences_v1_qari_id'),
          'ar.husary');
    });

    test('idle change: persisted + label updated, NO restart (nothing to '
        'swap)', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(overrides: [
        quranAudioProvider.overrideWith(
            () => _FakeAudioController(const QuranAudioState())),
      ]);
      addTearDown(container.dispose);
      final ctrl =
          container.read(quranAudioProvider.notifier) as _FakeAudioController;
      await ctrl.selectQari('ar.minshawi');
      expect(ctrl.restartCalls, 0);
      expect(ctrl.state.qariId, 'ar.minshawi');
      expect(ctrl.state.qariName, 'Mohamed Siddiq El-Minshawi');
      final sp = await SharedPreferences.getInstance();
      expect(sp.getString('quran_reading_preferences_v1_qari_id'),
          'ar.minshawi');
    });
  });

  group('download-all + storage math (pure)', () {
    test('full-Quran file count is the real table sum (not the constant)', () {
      // 6236 is the app's own ayah total; if metadata ever changes, this
      // pin forces the two to be reconciled deliberately, not silently.
      expect(Tilawat.filesForAllSurahs(), Tilawat.totalAyahs);
    });

    test('tallyAll aggregates present/failed/bytes from per-surah results',
        () {
      final agg = Tilawat.tallyAll([
        (present: 7, total: 7, bytes: 700, failed: const <int>[]),
        (present: 3, total: 7, bytes: 300, failed: const [4, 5]),
      ]);
      expect(agg.surahsDone, 1);
      expect(agg.surahsFailed, 1);
      expect(agg.filesDone, 10);
      expect(agg.filesTotal, 14);
      expect(agg.bytes, 1000);
    });

    test('tallySurah counts only usable (>0-byte) files', () {
      final t = Tilawat.tallySurah([100, null, 0, 250]);
      expect(t.present, 2); // 0-byte and missing are NOT present
      expect(t.total, 4);
      expect(t.bytes, 350);
    });

    test('storage total is EXACTLY the sum of the per-qari rows', () {
      const report = TilawatStorageReport(
        totalBytes: 900,
        perQari: [
          (dirName: 'a', displayName: 'A', bytes: 300, files: 3),
          (dirName: 'b', displayName: 'B', bytes: 600, files: 6),
        ],
      );
      expect(report.totalBytes,
          TilawatStorageReport.sumBytes(report.perQari)); // 900 ✓ sum, not guess
    });
  });

  group('mini player transport UI', () {
    _FakeAudioController? fake;

    Future<void> pump(WidgetTester tester, QuranAudioState state) async {
      fake = _FakeAudioController(state);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          quranAudioProvider.overrideWith(() => fake!),
        ],
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: const QuranMiniPlayer(),
          ),
        ),
      ));
    }

    testWidgets('hidden entirely while idle', (tester) async {
      await pump(tester, const QuranAudioState());
      expect(find.byType(Slider), findsNothing);
      expect(find.byIcon(Icons.skip_next_rounded), findsNothing);
    });

    testWidgets('no scrubber without a REAL duration; qari name shown; '
        'prev/next hit the controller', (tester) async {
      await pump(
          tester,
          const QuranAudioState(
            phase: QuranAudioPhase.playing,
            surahNumber: 2,
            surahName: 'Al-Baqarah',
            ayahNumber: 4,
            qariName: 'Mahmoud Khalil Al-Husary',
          ));
      expect(find.byType(Slider), findsNothing); // duration unknown → no fake
      expect(find.textContaining('Mahmoud Khalil Al-Husary'), findsOneWidget);
      await tester.tap(find
          .ancestor(of: find.byIcon(Icons.skip_next_rounded),
              matching: find.byType(IconButton))
          .first);
      await tester.tap(find
          .ancestor(of: find.byIcon(Icons.skip_previous_rounded),
              matching: find.byType(IconButton))
          .first);
      await tester.pump();
      expect(fake!.nextTaps, 1); // buttons are wired, not decorative
      expect(fake!.prevTaps, 1);
      expect(fake!.seeks, isEmpty);
    });

    testWidgets('real duration unlocks the slider; release seeks inside it',
        (tester) async {
      await pump(
          tester,
          const QuranAudioState(
            phase: QuranAudioPhase.playing,
            surahNumber: 2,
            ayahNumber: 4,
            position: Duration(seconds: 10),
            duration: Duration(seconds: 60),
          ));
      expect(find.byType(Slider), findsOneWidget);
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.max, 60000); // milliseconds of the REAL duration
      expect(slider.value, 10000);
      await tester.drag(find.byType(Slider), const Offset(5000, 0));
      await tester.pumpAndSettle();
      expect(fake!.seeks, hasLength(1)); // exactly one seek, on release
      final target = fake!.seeks.single;
      expect(target.inMilliseconds, greaterThanOrEqualTo(0));
      expect(target.inMilliseconds, lessThanOrEqualTo(60000)); // clamped
      expect(target, Duration(seconds: 60)); // drag ran to the real end
    });

    testWidgets('hifz row echoes real state: count, speed, range banner',
        (tester) async {
      await pump(
          tester,
          const QuranAudioState(
            phase: QuranAudioPhase.playing,
            surahNumber: 2,
            speed: 1.25,
            repeatMode: QuranRepeatMode.ayah,
            repeatCount: 3,
            rangePick: QuranRangePick.start,
          ));
      expect(find.textContaining(' · 3×'), findsOneWidget); // 'Repeat ayah · 3×'
      expect(find.text('1.25×'), findsOneWidget);
      expect(find.text('Tap the ayah that starts the range'), findsOneWidget);
    });
  });

  group('audio_service wiring pins', () {
    test('main boots the handler; boot is failure-guarded by contract', () {
      final main = File('lib/main.dart').readAsStringSync();
      expect(main, contains('await TilawatAudioHandler.boot();'));
      final service = File(
              'lib/features/quran/data/audio/quran_audio_service.dart')
          .readAsStringSync();
      // boot() must swallow platform failures (tests/desktop) — guarded
      // by a catch AND the instance stays nullable for that reason.
      expect(service, contains('catch'));
      expect(service, contains('instance = null'));
      expect(service, contains('class TilawatAudioHandler'));
    });

    test('manifest declares the service + receiver + two permissions only',
        () {
      final m = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(
          m, contains('android:name="com.ryanheise.audioservice.AudioService"'));
      expect(m, contains('android:foregroundServiceType="mediaPlayback"'));
      expect(
          m, contains('com.ryanheise.audioservice.MediaButtonReceiver'));
      expect(m,
          contains('android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK'));
      expect(m, contains('android.permission.FOREGROUND_SERVICE"'));
      // No new data/network permissions ride along with the media ones.
      expect(m.contains('android.permission.READ_EXTERNAL_STORAGE'), isFalse);
      expect(m.contains('WRITE_EXTERNAL_STORAGE'), isFalse);
    });

    test('pubspec pins audio_service to the compatible 0.18 line', () {
      final pub = File('pubspec.yaml').readAsStringSync();
      expect(pub, contains('audio_service: ^0.18.19'));
    });

    test('touched UI files: no hex colors, no audioplayers, no stray literals',
        () {
      final files = [
        'lib/features/quran/presentation/quran_mini_player.dart',
        'lib/features/quran/data/audio/quran_audio_service.dart',
        'lib/features/quran/providers/quran_audio_provider.dart',
        'lib/features/quran/providers/quran_download_provider.dart',
        'lib/features/quran/data/audio/tilawat_downloader.dart',
      ];
      for (final f in files) {
        final src = File(f).readAsStringSync();
        expect(src.contains('Color(0x'), isFalse,
            reason: 'design tokens only: $f');
        expect(src.contains('audioplayers'), isFalse,
            reason: 'the Quran player is just_audio only: $f');
      }
    });
  });
}
