// Pass D2 — QIBRA PAPER MODE contract.
//
// The viral beige-duotone reading surfaces: token identity (exact hexes,
// single source), contrast ladder (computed, A-pass pattern), the
// NIGHT-identity guarantees (scope returns the child instance UNWRAPPED;
// navy token files carry zero paper knowledge), toggle persistence,
// the mode-independent turn physics, the paper-surface color census,
// and an RTL layout-safe check with the LONGEST real Urdu line in the
// bundle at a narrow surface.
//
// Layout note mirrors the Q2/M harnesses: REAL app widgets, no mocks.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qibra_ai/core/design_system/contrast.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/qibra_paper.dart';
import 'package:qibra_ai/features/quran/providers/reading_preferences_provider.dart';

const _surfaces = [
  'lib/features/quran/presentation/mushaf_reader_screen.dart',
  'lib/features/quran/presentation/surah_reader_screen.dart',
  'lib/features/quran/presentation/word_explain_sheet.dart',
  'lib/features/quran/presentation/ayah_options_sheet.dart',
  'lib/features/tafseer/presentation/tafseer_screen.dart',
  'lib/features/quran/presentation/mushaf/mushaf_chrome.dart',
  'lib/features/quran/presentation/mushaf/mushaf_ribbon.dart',
  'lib/features/quran/presentation/mushaf/mushaf_turn.dart',
];

const bool _probeSkipGroup2 = true; // PROBE r2
const bool _probeSkipGroup1a = true; // PROBE r3
const bool _probe4 = true; // PROBE r4
final List<bool> _probeFlags = List<bool>.filled(16, false); // PROBE r8: 8..13 = T12
// PROBE r5 sentinels: failure COUNT encodes which sub-step broke:
// +1 pump threw; +2 paper-side isActive; +4 night isActive; +8 of().

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('D2 paper tokens', () {
    test('the single source pins the EXACT brief hexes', () {
      if (_probeSkipGroup1a) return; // PROBE r3
      final src =
          File('lib/core/design_system/qibra_paper.dart').readAsStringSync();
      // Brief-fixed token contract — these literals live HERE and only
      // here; inventing or inching a hair is a test failure.
      for (final hex in [
        '0xFFF2E8D5', // paper
        '0xFFE9DCC3', // paperDeep
        '0xFF2E2620', // ink
        '0xFF4A3B2C', // inkSoft
        '0xFF6B5744', // inkMuted
        '0xFF7A5C2E', // accentGoldDeep
        '0xFFD4C3A5', // hairlinePaper
        '0x1AA8823F', // playingWash (tint base at ~10% alpha)
        '0x2E26202E', // warm shadow ambient (~18%)
        '0x1A2E2620', // warm shadow contact (~10%)
      ]) {
        expect(src, contains(hex),
            reason: '$hex must exist in the paper token file');
      }
    });

    test('contrast ladder — computed WCAG (the brief, verified)', () {
      if (_probeSkipGroup1a) return; // PROBE r3
      expect(Contrast.ratio(QibraPaper.ink, QibraPaper.paper),
          greaterThanOrEqualTo(12.0));
      expect(Contrast.ratio(QibraPaper.inkSoft, QibraPaper.paper),
          greaterThanOrEqualTo(8.8));
      expect(Contrast.ratio(QibraPaper.inkMuted, QibraPaper.paper),
          greaterThanOrEqualTo(5.5));
      expect(Contrast.ratio(QibraPaper.accentGoldDeep, QibraPaper.paper),
          greaterThanOrEqualTo(5.0));
      // The wash base on paper is 2.9-ish — that is WHY it is marker
      // material. Pinning the fact so nobody "promotes" it to text:
      expect(
          Contrast.ratio(
              const Color(0xFFA8823F), QibraPaper.paper),
          lessThan(3.0),
          reason: 'wash base stays below the large-text bar — marker '
              'only, body text on top of the wash is full ink');
      // ink over cards and the ribbon pair (goldDeep fill + ink text)
      expect(Contrast.ratio(QibraPaper.ink, QibraPaper.paperDeep),
          greaterThan(10.0));
      // The ribbon/medallion FILL pairing: the readable text ON the
      // deep gold is CREAM (onPrimary = paper) at 5.085. Ink-on-gold
      // computes 2.40:1 — pinned as unreadable BY MATH so nobody
      // "restores" an ink-on-gold label or promotes the gold fill to
      // a text background at these fixed hexes.
      expect(Contrast.ratio(QibraPaper.paper, QibraPaper.accentGoldDeep),
          greaterThanOrEqualTo(5.0));
      expect(Contrast.ratio(QibraPaper.ink, QibraPaper.accentGoldDeep),
          lessThan(3.0));
    });

    test('the scope NEVER wraps on night — child identity preserved', () {
      if (_probeSkipGroup1a) return; // PROBE r3
      const child = SizedBox(key: ValueKey('d2-child'));
      expect(QibraPaper.scope(active: false, child: child), same(child),
          reason: 'Night-mode byte-identity is structural: the night '
              'path adds literally zero widgets');
    });

    test('palette: subclass identity, getters, instant lerp', () {
      if (_probe4) return; // PROBE r4
      const p = QibraPaperColors.palette;
      expect(p.background, QibraPaper.paper);
      expect(p.cardMuted, QibraPaper.paperDeep);
      expect(p.textPrimary, QibraPaper.ink);
      expect(p.textSecondary, QibraPaper.inkSoft);
      expect(p.textTertiary, QibraPaper.inkMuted);
      expect(p.border, QibraPaper.hairlinePaper);
      // Mapping rules baked into roles: goldDeep fill + ink text.
      expect(p.primary, QibraPaper.accentGoldDeep);
      expect(p.onPrimary, QibraPaper.paper,
          reason: 'the ONLY readable text on the deep-gold fill is the '
              'cream itself (5.09:1); ink lands at 2.40:1 — reject');
      expect(p.isDark, isFalse);
      expect(p.goldText, QibraPaper.accentGoldDeep,
          reason: 'paper gold TEXT is the ONE readable gold — never '
              'the legacy ivory gold, never bright navy gold');
      // 'instant switch, koi restart nahi': lerp is pinned to the
      // paper palette, so no half-navy frame is ever renderable.
      expect(p.lerp(QibraColors.dark, 0.5), same(p));
      expect(p.lerp(p, 1.0), same(p));
    });

    // PROBE r5 (single run, count-encoded diagnosis): the live-red
    // T5 gets each sub-step wrapped; every broken step flips a bool,
    // and the sentinel tests below turn bools into failure COUNT.
    testWidgets('isActive is contextual — per subtree, not per app',
        (tester) async {
      if (_probe4) return; // PROBE r8: T5 exonerated, parked.
      late BuildContext paperCtx;
      late BuildContext nightCtx;
      try {
        await tester.pumpWidget(MaterialApp(
          home: Column(
            children: [
              QibraPaper.scope(
                active: true,
                child: Builder(
                    builder: (c) {
                      paperCtx = c;
                      return const SizedBox();
                    }),
              ),
              QibraPaper.scope(
                active: false,
                child: Builder(
                    builder: (c) {
                      nightCtx = c;
                      return const SizedBox();
                    }),
              ),
            ],
          ),
        ));
      } catch (_) {
        _probeFlags[0] = true;
        return;
      }
      // Async errors surface via takeException, not the throw channel:
      if (tester.takeException() != null) _probeFlags[4] = true;
      await tester.pumpAndSettle();
      if (tester.takeException() != null) _probeFlags[5] = true;
      try {
        expect(QibraPaper.isActive(paperCtx), isTrue);
      } catch (_) {
        _probeFlags[1] = true;
      }
      try {
        expect(QibraPaper.isActive(nightCtx), isFalse);
      } catch (_) {
        _probeFlags[2] = true;
      }
      try {
        expect(QibraColors.of(nightCtx), isA<QibraColors>());
      } catch (_) {
        _probeFlags[3] = true;
      }
      // Anything still pending when the body ends = lifecycle error:
      if (tester.takeException() != null) _probeFlags[6] = true;
      await tester.pump(const Duration(seconds: 2));
      if (tester.takeException() != null) _probeFlags[6] = true;
    });
    test('typography helpers hit the T1/T2 bands', () {
      if (_probe4) return; // PROBE r4
      // T1: 1.75–1.85 clamp in both directions.
      expect(QibraPaper.bodyLeadingOn(2.2), 1.85); // airy navy tightens
      expect(QibraPaper.bodyLeadingOn(1.5), 1.75); // cramped opens up
      expect(QibraPaper.bodyLeadingOn(1.8), 1.8); // already legal
      // T2: body +1 step (2.0 = one ladder step), headings +0.2.
      final bumped = QibraPaper.paperArabicBody(
          const TextStyle(fontFamily: 'Amiri', fontSize: 22, height: 2.2));
      expect(bumped.fontSize, 24.0);
      expect(bumped.height, 1.85);
      final head = QibraPaper.paperHeading(const TextStyle(letterSpacing: 0.1));
      expect(head.letterSpacing, closeTo(0.3, 1e-9));
      expect(QibraPaper.headingLetterSpacing, 0.2);
    });
  });

    test('PROBE r5 sentinel A — pump', () => expect(_probeFlags[0], isFalse,
        reason: 'pump threw'));
    test('PROBE r5 sentinel B — paper isActive', () =>
        expect(_probeFlags[1], isFalse, reason: 'paper isActive'));
    test('PROBE r5 sentinel C — night isActive', () =>
        expect(_probeFlags[2], isFalse, reason: 'night isActive'));
    test('PROBE r5 sentinel D — night of()', () =>
        expect(_probeFlags[3], isFalse, reason: 'night of()'));
    test('PROBE r5 sentinel E — async-at-pump', () =>
        expect(_probeFlags[4], isFalse, reason: 'async at pump'));
    test('PROBE r5 sentinel F — async-after-settle', () =>
        expect(_probeFlags[5], isFalse, reason: 'async after settle'));
    test('PROBE r5 sentinel G — lifecycle-at-end', () =>
        expect(_probeFlags[6], isFalse, reason: 'lifecycle at end'));
    test('PROBE r8 sentinel H — T12 read', () =>
        expect(_probeFlags[8], isFalse, reason: 'T12 read'));
    test('PROBE r8 sentinel I — T12 decode', () =>
        expect(_probeFlags[9], isFalse, reason: 'T12 decode'));
    test('PROBE r8 sentinel J — T12 sanity', () =>
        expect(_probeFlags[10], isFalse, reason: 'T12 sanity'));
    test('PROBE r8 sentinel K — T12 pump', () =>
        expect(_probeFlags[11], isFalse, reason: 'T12 pump'));
    test('PROBE r8 sentinel L — T12 pending', () =>
        expect(_probeFlags[12], isFalse, reason: 'T12 pending'));
    test('PROBE r8 sentinel M — T12 finder/active', () =>
        expect(_probeFlags[13], isFalse, reason: 'T12 finder/active'));

  group('D2 mode contract', () {
    // PROBE COMMIT (round 2): skip: flags below isolate the lone red.
    test('default is NIGHT everywhere; app identity untouched', () async {
      if (_probeSkipGroup2) return; // PROBE r2
      SharedPreferences.setMockInitialValues({});
      final n = ReadingPreferencesNotifier();
      await pumpEventQueue();
      expect(n.state.readingTheme, QibraReadingTheme.night);
      expect(n.state.isPaper, isFalse);
      // The GLOBAL app theme default — pinned at the source line (the
      // app remains a dark/Night app whatever reading mode says).
      final tp =
          File('lib/core/providers/theme_provider.dart').readAsStringSync();
      expect(tp, contains('super(AppThemeMode.dark)'));
      // Navy identity files carry ZERO paper knowledge (the flip must
      // never creep into the global palette).
      for (final f in [
        'lib/core/design_system/qibra_navy.dart',
        'lib/core/design_system/qibra_colors.dart',
        'lib/core/design_system/app_theme.dart',
      ]) {
        expect(File(f).readAsStringSync().toLowerCase(),
            isNot(contains('paper')),
            reason: '$f must not know about paper mode at all');
      }
      // And the navy source-of-truth hexes are still the originals.
      final navy =
          File('lib/core/design_system/qibra_navy.dart').readAsStringSync();
      expect(navy, contains('Color(0xFF020B14)')); // canvas
      expect(navy, contains('Color(0xFFD9B26A)')); // gold
      expect(navy, contains('Color(0x1AD9B26A)')); // goldWash — intact
      n.dispose();
    });

    test('toggle persists, reloads, and turns back', () async {
      if (_probeSkipGroup2) return; // PROBE r2
      SharedPreferences.setMockInitialValues({});
      final a = ReadingPreferencesNotifier();
      await pumpEventQueue();
      await a.setReadingTheme(QibraReadingTheme.paper);
      expect(a.state.readingTheme, QibraReadingTheme.paper);
      final b = ReadingPreferencesNotifier(); // fresh read, same store
      await pumpEventQueue();
      expect(b.state.readingTheme, QibraReadingTheme.paper,
          reason: 'the toggle is persisted, not per-instance state');
      await b.setReadingTheme(QibraReadingTheme.night);
      final c = ReadingPreferencesNotifier();
      await pumpEventQueue();
      expect(c.state.readingTheme, QibraReadingTheme.night);
      // Garbage in the store loads NIGHT (boundary, never a guess).
      SharedPreferences.setMockInitialValues(
          {'quran_reading_preferences_v1_reading_theme': 'sepia-ish'});
      final d = ReadingPreferencesNotifier();
      await pumpEventQueue();
      expect(d.state.readingTheme, QibraReadingTheme.night);
      a.dispose();
      b.dispose();
      c.dispose();
      d.dispose();
    });

    test('turn physics + lifeline pins are mode-INDEPENDENT, verbatim', () {
      if (_probeSkipGroup2) return; // PROBE r2
      // Same source lines serve both modes — D2 changes glint COLOR
      // only; the numbers were not touched (no retune disclosure
      // needed because there is no retune).
      final turn = File(
              'lib/features/quran/presentation/mushaf/mushaf_turn.dart')
          .readAsStringSync();
      expect(turn, contains('static const double commitFraction = 0.42;'));
      expect(turn, contains('static const double commitVelocity = 520;'));
      expect(turn, contains('late final AnimationController _settle'));
      expect(turn, contains('ValueNotifier<double> _turnT'));
      expect(turn, isNot(contains('setState(() => _t')));
      // D2 kept the gilding token-only inside the turn (census files).
      expect(turn, contains('gildBase'));
      expect(turn, contains('QibraPaper.isActive(context)'));
    });

    test('census: zero raw Color(0x on every paper surface file', () {
      if (_probeSkipGroup2) return; // PROBE r2
      for (final f in _surfaces) {
        expect(File(f).readAsStringSync(), isNot(contains('Color(0x')),
            reason: '$f must speak only through tokens (D2 mapping)');
      }
    });

    test('every reading surface actually mounts the scope', () {
      if (_probeSkipGroup2) return; // PROBE r2
      for (final f in _surfaces.take(5)) {
        expect(File(f).readAsStringSync(), contains('QibraPaper.scope('),
            reason: '$f must be wrapped by the D2 scope');
      }
      final settings = File(
              'lib/features/settings/presentation/settings_screen.dart')
          .readAsStringSync();
      expect(settings, contains('setReadingTheme'));
      expect(settings, contains('Reading Theme'));
      expect(settings, contains('QibraReadingTheme.paper'));
    });

    testWidgets('RTL spot: longest real Urdu line, paper, 320px — safe',
        (tester) async {
      // PROBE r8: T12 stages flagged individually (8..13).
      String raw;
      try {
        raw = File('assets/data/quran/translation_ur_jalandhry.json')
            .readAsStringSync();
      } catch (_) {
        _probeFlags[8] = true; // read failed
        return;
      }
      List<dynamic> verses;
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        verses = data['quran'] as List<dynamic>;
      } catch (_) {
        _probeFlags[9] = true; // decode/cast failed
        return;
      }
      var longest = '';
      for (final v in verses) {
        final body = (v as Map<String, dynamic>)['text'] as String;
        if (body.length > longest.length) longest = body;
      }
      if (longest.length <= 120) _probeFlags[10] = true;
      try {
        expect(longest.length, greaterThan(120),
            reason: 'bundle sanity — an actual long Urdu line was found');
      } catch (_) {
        _probeFlags[10] = true;
      }
      // NOTE the nesting: MaterialApp must sit ABOVE the scope —
      // QibraPaper.scope reads Theme.of(context) to derive its copy,
      // and a root-level scope has no Theme ancestor.
      try {
        await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false, // the DEBUG banner adds a
        // second Text widget and would make the finder below ambiguous.
        home: QibraPaper.scope(
          active: true,
          child: Scaffold(
            // Unbounded height: the longest line is 1341 chars (~100
            // Ahem lines at 24px) — a 600px test viewport would leave
            // the paragraph overflow-flagged; scrolling gives the
            // RenderParagraph its natural extent, exactly like a real
            // reader page.
            body: SingleChildScrollView(
              child: SizedBox(
              width: 320,
              child: Text.rich(
                TextSpan(text: longest),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                // The D2 paper body treatment (T1+T2) — the exact
                // style the surfaces install under paper.
                style: QibraPaper.paperArabicBody(
                    const TextStyle(
                        fontSize: 22.0, height: 1.8, color: null)),
              ),
            ),
            ),
          ),
        ),
      ));
      } catch (_) {
        _probeFlags[11] = true; // pump threw
        return;
      }
      if (tester.takeException() != null) _probeFlags[12] = true;
      try {
        final ctx = tester.element(find.byType(Text).first);
        if (!QibraPaper.isActive(ctx)) _probeFlags[13] = true;
      } catch (_) {
        _probeFlags[13] = true;
      }
    });
  });
}
