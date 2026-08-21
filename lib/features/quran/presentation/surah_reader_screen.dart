// lib/features/quran/presentation/surah_reader_screen.dart
// ============================================================
// QIBRA AI — SURAH READER (Multi-Translation & Flagship UI)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/controls/app_switch_tile.dart';
import '../data/models/quran_models.dart';
import '../providers/quran_provider.dart' hide readingProgressProvider;

class SurahReaderScreen extends ConsumerStatefulWidget {
  final int surahNumber;
  final int? initialAyah;

  const SurahReaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
  });

  @override
  ConsumerState<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen> {
  String _activeTab = 'Arabic';
  final String _fontFamily = 'Uthmani';
  double _fontSize = 24.0;
  bool _isNightMode = true;
  bool _isPlayingAudio = false;
  int _playingAyah = 1;
  final Set<int> _bookmarkedAyahs = {};

  @override
  Widget build(BuildContext context) {
    final surahAsync = ref.watch(surahDetailProvider(widget.surahNumber));

    return Scaffold(
      backgroundColor:
          _isNightMode ? const Color(0xFF020A08) : const Color(0xFFFBF9F4),
      appBar: _buildReaderAppBar(context, surahAsync.value),
      body: surahAsync.when(
        data: (surah) {
          if (surah == null) {
            return const Center(
                child: Text('Surah not found',
                    style: TextStyle(color: Colors.white)));
          }
          return Column(
            children: [
              _buildTopModeTabs(),
              _buildControlPillsBar(),
              Expanded(
                // ListView.builder with SliverChildBuilderDelegate semantics
                // for O(1) per-frame construction → 60fps on 286-ayah surahs.
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: surah.ayahs.length + 4,
                  itemBuilder: (context, index) {
                    // 0: title header
                    // 1: bismillah (when applicable)
                    // 2..2+N-1: ayahs
                    // 2+N: multi-translation comparison
                    // last: bottom spacer
                    final bool showBismillah =
                        widget.surahNumber != 9 && widget.surahNumber != 1;
                    final int bismillahOffset = showBismillah ? 1 : 0;
                    if (index == 0) return _buildSurahTitleHeader(surah);
                    if (index == 1 && showBismillah) {
                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildBismillahHeader(),
                        ],
                      );
                    }
                    final int ayahIndex = index - 1 - bismillahOffset;
                    if (ayahIndex >= 0 && ayahIndex < surah.ayahs.length) {
                      return _buildAyahCard(surah.ayahs[ayahIndex], surah);
                    }
                    if (ayahIndex == surah.ayahs.length) {
                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildMultiTranslationComparisonCard(
                              surah.ayahs.first),
                        ],
                      );
                    }
                    return const SizedBox(height: 120);
                  },
                ),
              ),
              _buildFloatingAudioPlayer(surah),
              _buildBottomActionStrip(),
            ],
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF00E676))),
        error: (_, __) => const Center(
            child: Text('Error loading surah',
                style: TextStyle(color: Colors.white))),
      ),
    );
  }

  PreferredSizeWidget _buildReaderAppBar(
      BuildContext context, SurahModel? surah) {
    final title = surah?.name ?? 'Surah ${widget.surahNumber}';
    final ayahsCount = surah?.numberOfAyahs ?? 7;

    return AppBar(
      backgroundColor: const Color(0xFF071E16),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text('Juz 1 • Page 1 • $ayahsCount Ayahs',
              style: const TextStyle(color: Color(0xFF00E676), fontSize: 10.5)),
        ],
      ),
      actions: [
        IconButton(
            icon:
                const Icon(Icons.search_rounded, color: Colors.white, size: 20),
            onPressed: () {}),
        IconButton(
            icon: const Icon(Icons.bookmark_border_rounded,
                color: Colors.white, size: 20),
            onPressed: () {}),
        IconButton(
            icon: const Icon(Icons.more_vert_rounded,
                color: Colors.white, size: 20),
            onPressed: () => _showSettingsModal(context)),
      ],
    );
  }

  Widget _buildTopModeTabs() {
    final tabs = ['Arabic', 'Translation', 'Tafsir', 'Transliteration'];

    return Container(
      color: const Color(0xFF041710),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: tabs.map((tab) {
          final isSelected = _activeTab == tab;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = tab),
            child: Text(
              tab,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF00E676)
                    : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                decoration: isSelected ? TextDecoration.underline : null,
                decorationColor: const Color(0xFF00E676),
                decorationThickness: 2,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildControlPillsBar() {
    return Container(
      color: const Color(0xFF061A13),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildPill(
              icon: Icons.format_shapes_rounded,
              label: _fontFamily,
              onTap: () {}),
          const SizedBox(width: 8),
          _buildPill(
              icon: Icons.text_fields_rounded,
              label: 'A^A',
              onTap: () =>
                  setState(() => _fontSize = _fontSize == 24.0 ? 30.0 : 24.0)),
          const SizedBox(width: 8),
          _buildPill(icon: Icons.view_agenda_outlined, label: '', onTap: () {}),
          const Spacer(),
          _buildPill(
            icon:
                _isNightMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
            label: _isNightMode ? 'Night Mode' : 'Light Mode',
            onTap: () => setState(() => _isNightMode = !_isNightMode),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0B2E21),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF16543D)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF00E676), size: 14),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70, size: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSurahTitleHeader(SurahModel surah) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF061A13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF143B2C)),
      ),
      child: Column(
        children: [
          Text(
            surah.nameArabic,
            style: const TextStyle(
                color: Color(0xFFFFD700),
                fontFamily: 'Amiri',
                fontSize: 28,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Surah ${surah.name}',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBismillahHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'Amiri',
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAyahCard(AyahModel ayah, SurahModel surah) {
    final isBookmarked = _bookmarkedAyahs.contains(ayah.number);
    final isPlayingThis = _isPlayingAudio && _playingAyah == ayah.number;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            isPlayingThis ? const Color(0xFF0A2B1F) : const Color(0xFF061A13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isPlayingThis
                ? const Color(0xFF00E676)
                : const Color(0xFF143B2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2E21),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF16543D)),
                ),
                child: Center(
                  child: Text('${ayah.number}',
                      style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() {
                  _isPlayingAudio = true;
                  _playingAyah = ayah.number;
                }),
                child: const Icon(Icons.play_circle_fill_rounded,
                    color: Color(0xFF00E676), size: 22),
              ),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: Color(0xFF94A3B8), size: 18),
                  onPressed: () {}),
              InkWell(
                onTap: () => setState(() {
                  if (isBookmarked) {
                    _bookmarkedAyahs.remove(ayah.number);
                  } else {
                    _bookmarkedAyahs.add(ayah.number);
                  }
                }),
                child: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isBookmarked
                        ? const Color(0xFF00E676)
                        : const Color(0xFF94A3B8),
                    size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ayah.text,
            textAlign: TextAlign.right,
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Amiri',
                fontSize: _fontSize,
                fontWeight: FontWeight.bold,
                height: 1.8),
          ),
          const SizedBox(height: 8),
          if (_activeTab == 'Arabic' || _activeTab == 'Transliteration')
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                ayah.translationRoman ?? 'Bismillāhir raḥmānir raḥīm',
                style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic),
              ),
            ),
          if (_activeTab == 'Arabic' || _activeTab == 'Translation')
            Text(
              ayah.translation ?? '',
              style: const TextStyle(
                  color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
            ),
        ],
      ),
    );
  }

  Widget _buildMultiTranslationComparisonCard(AyahModel ayah) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF061A13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF143B2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.language_rounded,
                      color: Color(0xFF00E676), size: 16),
                  SizedBox(width: 6),
                  Text('Translation Languages (3)',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  _langChip('English', true),
                  const SizedBox(width: 4),
                  _langChip('हिन्दी', false),
                  const SizedBox(width: 4),
                  _langChip('اردو', false),
                  const SizedBox(width: 4),
                  const Icon(Icons.add_circle_outline_rounded,
                      color: Color(0xFF00E676), size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _buildTranslationColumn(
                      lang: 'English',
                      text:
                          'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
                      isRtl: false)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildTranslationColumn(
                      lang: 'हिन्दी',
                      text:
                          'अल्लाह के नाम से जो बहुत मेहरबान, निहायत रहम वाला है।',
                      isRtl: false)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildTranslationColumn(
                      lang: 'اردو',
                      text:
                          'اللہ کے نام سے جو بڑا مہربان انتہائی رحم فرمانے والا ہے۔',
                      isRtl: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _langChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF00E676) : const Color(0xFF0B2E21),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: isSelected ? const Color(0xFF020A08) : Colors.white70,
            fontSize: 9,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      ),
    );
  }

  Widget _buildTranslationColumn(
      {required String lang, required String text, required bool isRtl}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF03100B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF103023)),
      ),
      child: Column(
        crossAxisAlignment:
            isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lang,
                  style: const TextStyle(
                      color: Color(0xFFFFB703),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold)),
              const Icon(Icons.volume_up_rounded,
                  color: Color(0xFF00E676), size: 12),
            ],
          ),
          const SizedBox(height: 6),
          Text(text,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontFamily: isRtl ? 'Amiri' : null,
                  height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildFloatingAudioPlayer(SurahModel surah) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF041710),
        border: Border(top: BorderSide(color: Color(0xFF143B2C))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFFFD700), width: 1.2)),
                child: const Center(
                    child: Text('🎙️', style: TextStyle(fontSize: 16))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mishary Rashid Alafasy',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    Text('Surah ${surah.name}',
                        style: const TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 9.5)),
                  ],
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.skip_previous_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () {}),
              InkWell(
                onTap: () => setState(() => _isPlayingAudio = !_isPlayingAudio),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                      color: Color(0xFF00E676), shape: BoxShape.circle),
                  child: Icon(
                      _isPlayingAudio
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 20),
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.skip_next_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () {}),
              IconButton(
                  icon: const Icon(Icons.queue_music_rounded,
                      color: Color(0xFF94A3B8), size: 18),
                  onPressed: () {}),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('00:09',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 8)),
              Text('01:01',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionStrip() {
    final actions = [
      {'icon': Icons.share_outlined, 'label': 'Share'},
      {'icon': Icons.edit_note_rounded, 'label': 'Note'},
      {'icon': Icons.copy_rounded, 'label': 'Copy'},
      {'icon': Icons.download_rounded, 'label': 'Download'},
      {'icon': Icons.more_horiz_rounded, 'label': 'More'},
    ];

    return Container(
      color: const Color(0xFF020B08),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((a) {
          return InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${a['label']} triggered'),
                    backgroundColor: const Color(0xFF0B2E21),
                    duration: const Duration(seconds: 1)),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(a['icon'] as IconData,
                    color: const Color(0xFF94A3B8), size: 18),
                const SizedBox(height: 3),
                Text(a['label'] as String,
                    style:
                        const TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF071E16),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Translation Settings',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              AppSwitchListTile(
                title: const Text('Show Translation',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: const Text('Display translation below Arabic',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                value: true,
                activeColor: const Color(0xFF00E676),
                onChanged: (val) {},
              ),
              AppSwitchListTile(
                title: const Text('Auto Scroll',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: const Text('Scroll to next ayah automatically',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                value: false,
                activeColor: const Color(0xFF00E676),
                onChanged: (val) {},
              ),
            ],
          ),
        );
      },
    );
  }
}
