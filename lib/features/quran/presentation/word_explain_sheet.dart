// lib/features/quran/presentation/word_explain_sheet.dart
// ============================================================
// QIBRA AI — WORD EXPLAIN SHEET (Pass Q3, the deep layer)
// ============================================================
// LONG-PRESS of any rendered word opens this sheet. Everything it
// shows is real: the word as it appears in the app's own bundled
// Uthmani text, the English gloss from the verified word-by-word
// dataset (honest "unavailable" when the file carries none), an
// occurrence count computed LIVE from the bundled corpus with the
// search fold, and the ayah's bundled transliteration line. Root
// morphology is disclosed as NOT BUNDLED (the Quranic Arabic Corpus
// redistribution license could not be verified — deferred, per brief;
// no improvised glosses, no machine Urdu per-word layer either since
// no verifiable Urdu word-by-word source exists — the line simply
// isn't rendered rather than faked).
//
// Ayah-scoped actions stay ayah-scoped (Tafseer, AI explain): the AI
// question MENTIONS the word while grounding stays the real ayah
// passage — no fake word-scope claims anywhere.
//
// Sheet follows the CPH2573 house rule (Pass Q2 round): isScrollControlled
// + 0.85 cap + scrollable body so short screens never overflow; on
// tall screens where content fits, the scroll view is dormant.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../ai/presentation/ai_explain_screen.dart';
import '../../tafseer/presentation/tafseer_screen.dart';
import '../providers/quran_word_provider.dart';

/// Open the word explain sheet. [word] is the displayed span (raw
/// Uthmani bytes); [gloss] may be empty (honest-unavailable);
/// [hasExactTimings] = the active qari has a cue window covering this
/// span (drives the play button's honest notice, never hidden logic).
Future<void> showWordExplainSheet(
  BuildContext context, {
  required int surahNumber,
  required String surahName,
  required int ayahNumber,
  required String ayahText,
  required String word,
  required String gloss,
  required int spanIndex,
  required bool hasExactTimings,
  required String? transliteration,
  required VoidCallback onPlayFromWord,
}) {
  HapticFeedback.mediumImpact();
  final colors = QibraColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    backgroundColor: Colors.transparent,
    builder: (_) => Material(
      // Material (not a bare decorated Container) so the sheet's own
      // ink + rounded surface compose like the bookmarks sheet did
      // after its ink sweep (owner convention, Pass Q2).
      color: colors.card,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: _WordExplainBody(
            surahNumber: surahNumber,
            surahName: surahName,
            ayahNumber: ayahNumber,
            ayahText: ayahText,
            word: word,
            gloss: gloss,
            spanIndex: spanIndex,
            hasExactTimings: hasExactTimings,
            transliteration: transliteration,
            onPlayFromWord: onPlayFromWord,
          ),
        ),
      ),
    ),
  );
}

class _WordExplainBody extends ConsumerWidget {
  const _WordExplainBody({
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.ayahText,
    required this.word,
    required this.gloss,
    required this.spanIndex,
    required this.hasExactTimings,
    required this.transliteration,
    required this.onPlayFromWord,
  });

  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final String ayahText;
  final String word;
  final String gloss;
  final int spanIndex;
  final bool hasExactTimings;
  final String? transliteration;
  final VoidCallback onPlayFromWord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final strings = AppStrings.of(context);
    final occurrences = ref.watch(quranWordOccurrencesProvider(word));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Text(
              word,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppArabicStyles.quranMedium.copyWith(
                fontSize: 34,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '$surahName · $surahNumber:$ayahNumber',
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.cardMuted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gloss.isEmpty
                      ? strings.wordGlossUnavailable
                      : gloss,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: gloss.isEmpty
                        ? colors.textTertiary
                        : colors.textPrimary,
                    fontStyle:
                        gloss.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                if (transliteration != null &&
                    transliteration!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    transliteration!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          _infoRow(
            context,
            icon: Icons.tag_rounded,
            // The count is computed live from the app's own corpus with
            // the search fold; loading renders no line (never a 0).
            text: occurrences.hasValue
                ? strings.wordAppearsNTimes(occurrences.value!)
                : null,
          ),
          _infoRow(
            context,
            icon: Icons.account_tree_outlined,
            text: strings.wordRootDataNotBundled,
            muted: true,
          ),
          const SizedBox(height: 14),
          _actionRow(
            context,
            icon: Icons.play_circle_outline_rounded,
            label: strings.playFromThisWord,
            onTap: () {
              Navigator.pop(context);
              onPlayFromWord();
            },
          ),
          if (!hasExactTimings)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 2, bottom: 6),
              child: Text(
                strings.wordTimingsNotAvailable,
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ),
          _actionRow(
            context,
            icon: Icons.menu_book_rounded,
            label: strings.openTafseer,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TafseerScreen(
                    surahNumber: surahNumber,
                    initialAyah: ayahNumber,
                  ),
                ),
              );
            },
          ),
          _actionRow(
            context,
            icon: Icons.psychology_rounded,
            label: strings.askAiAboutWord,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AIExplainScreen(
                    ayahText: ayahText,
                    surahName: surahName,
                    ayahNumber: ayahNumber,
                    surahNumber: surahNumber,
                    focusWord: word,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context,
      {required IconData icon, required String? text, bool muted = false}) {
    if (text == null) return const SizedBox.shrink();
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18,
              color: muted ? colors.textTertiary : colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: muted ? colors.textTertiary : colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    final colors = QibraColors.of(context);
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
