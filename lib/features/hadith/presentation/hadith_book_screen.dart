// lib/features/hadith/presentation/hadith_book_screen.dart
// ============================================================
// QIBRA AI — HADITH BOOK DETAIL SCREEN (Flagship Luxury Reader)
// Complete Arabic + Urdu + English translations with chapter selector & search
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/controls/app_switch_tile.dart';
import '../data/models/hadith_models.dart';
import '../providers/hadith_provider.dart';

class HadithBookScreen extends ConsumerStatefulWidget {
  final HadithBook book;

  const HadithBookScreen({super.key, required this.book});

  @override
  ConsumerState<HadithBookScreen> createState() => _HadithBookScreenState();
}

class _HadithBookScreenState extends ConsumerState<HadithBookScreen> {
  int? _selectedChapterNumber;
  String _searchQuery = '';
  bool _showArabic = true;
  bool _showUrdu = true;
  bool _showEnglish = true;

  @override
  Widget build(BuildContext context) {
    final params = HadithsParams(
      bookSlug: widget.book.slug,
      chapterNumber: _selectedChapterNumber,
    );
    final hadithsAsync = ref.watch(hadithsProvider(params));
    final chaptersAsync = ref.watch(hadithChaptersProvider(widget.book.slug));

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. APP BAR
            _buildAppBar(context),

            // 2. BOOK HERO HEADER
            _buildBookHeader(),

            // 3. CHAPTERS & DISPLAY CONTROLS BAR
            _buildControlsBar(context, chaptersAsync.value ?? []),

            // 4. HADITH LIST
            hadithsAsync.when(
              data: (hadiths) {
                final filtered = _searchQuery.trim().isEmpty
                    ? hadiths
                    : hadiths.where((h) {
                        final q = _searchQuery.toLowerCase();
                        return h.hadithNumber.toString().contains(q) ||
                            h.textEnglish.toLowerCase().contains(q) ||
                            h.textUrdu.contains(_searchQuery) ||
                            h.textArabic.contains(_searchQuery);
                      }).toList();

                if (filtered.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'No hadiths found.',
                          style:
                              TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final h = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _HadithCard(
                            hadith: h,
                            showArabic: _showArabic,
                            showUrdu: _showUrdu,
                            showEnglish: _showEnglish,
                            onTap: () => _showHadithDetailSheet(context, h),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(color: Color(0xFF00E676)),
                  ),
                ),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.redAccent, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'Failed to load hadiths',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  // 1. APP BAR
  // ────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF000000),
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 18),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        widget.book.name,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.display_settings_rounded,
              color: Color(0xFFFFB703), size: 20),
          onPressed: () => _showDisplaySettingsDialog(context),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────
  // 2. BOOK HEADER
  // ────────────────────────────────────────────────────────
  Widget _buildBookHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF080C0A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1A221C)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B2E21),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF00E676)),
                    ),
                    child: const Center(
                      child: Icon(Icons.menu_book_rounded,
                          color: Color(0xFF00E676), size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.book.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.book.author,
                          style: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildStatChip(Icons.article_rounded, 'Hadiths',
                      '${widget.book.totalHadiths}', const Color(0xFF00E676)),
                  const SizedBox(width: 8),
                  _buildStatChip(Icons.folder_rounded, 'Chapters',
                      '${widget.book.totalChapters}', const Color(0xFFFFB703)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatChip(Icons.verified_rounded, 'Grade',
                        'Authentic', const Color(0xFF38BDF8)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w800, fontSize: 11)),
              Text(label,
                  style:
                      const TextStyle(color: Color(0xFF94A3B8), fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  // 3. CONTROLS BAR (Search + Chapter selector)
  // ────────────────────────────────────────────────────────
  Widget _buildControlsBar(BuildContext context, List<HadithChapter> chapters) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF080C0A),
                hintText: 'Search hadith number or text in this book...',
                hintStyle:
                    const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFFFFB703), size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: Colors.white70, size: 16),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF1A221C)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF1A221C)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF00E676)),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 8),
            if (chapters.isNotEmpty)
              SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: chapters.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedChapterNumber == null;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedChapterNumber = null),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF072418)
                                  : const Color(0xFF080C0A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF00E676)
                                      : const Color(0xFF1A221C)),
                            ),
                            child: Center(
                              child: Text(
                                'All Chapters',
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF00E676)
                                      : const Color(0xFFCBD5E1),
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final ch = chapters[index - 1];
                    final isSelected = _selectedChapterNumber == ch.number;

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedChapterNumber = ch.number),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF072418)
                                : const Color(0xFF080C0A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00E676)
                                    : const Color(0xFF1A221C)),
                          ),
                          child: Center(
                            child: Text(
                              'Ch ${ch.number}: ${ch.name}',
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF00E676)
                                    : const Color(0xFFCBD5E1),
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDisplaySettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF080C0A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF1E3A2B)),
              ),
              title: const Text('Display Languages',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSwitchListTile(
                    activeColor: const Color(0xFF00E676),
                    title: const Text('Arabic Text (عربي)',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    value: _showArabic,
                    onChanged: (v) {
                      setDialogState(() => _showArabic = v);
                      setState(() => _showArabic = v);
                    },
                  ),
                  AppSwitchListTile(
                    activeColor: const Color(0xFF00E676),
                    title: const Text('Urdu Translation (اردو)',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    value: _showUrdu,
                    onChanged: (v) {
                      setDialogState(() => _showUrdu = v);
                      setState(() => _showUrdu = v);
                    },
                  ),
                  AppSwitchListTile(
                    activeColor: const Color(0xFF00E676),
                    title: const Text('English Translation',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    value: _showEnglish,
                    onChanged: (v) {
                      setDialogState(() => _showEnglish = v);
                      setState(() => _showEnglish = v);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Done',
                      style: TextStyle(
                          color: Color(0xFF00E676),
                          fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showHadithDetailSheet(BuildContext context, HadithModel hadith) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF060B08),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFF1E3A2B), width: 1.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B2E21),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00E676)),
                      ),
                      child: Text(
                        '#${hadith.hadithNumber}',
                        style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hadith.displayReference,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.share_rounded,
                          color: Colors.white70),
                      onPressed: () {
                        final text =
                            '${hadith.textArabic}\n\n${hadith.textUrdu}\n\n"${hadith.textEnglish}"\n\n— ${hadith.displayReference}';
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Hadith copied! 📋'),
                              backgroundColor: Color(0xFF0B2E21)),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF142018), height: 1),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hadith.hasArabic) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A140F),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF1E3A2B)),
                          ),
                          child: SelectableText(
                            hadith.textArabic,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Amiri',
                                fontSize: 19,
                                height: 1.8,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (hadith.hasUrdu) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF081810),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFF00E676)
                                    .withValues(alpha: 0.2)),
                          ),
                          child: SelectableText(
                            hadith.textUrdu,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                                color: Color(0xFFD1FAE5),
                                fontSize: 15,
                                height: 1.8),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (hadith.hasEnglish) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B121C),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF1E3A5F)),
                          ),
                          child: SelectableText(
                            hadith.textEnglish,
                            style: const TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 13.5,
                                height: 1.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// HADITH CARD WIDGET
// ============================================================

class _HadithCard extends ConsumerWidget {
  final HadithModel hadith;
  final bool showArabic;
  final bool showUrdu;
  final bool showEnglish;
  final VoidCallback onTap;

  const _HadithCard({
    required this.hadith,
    required this.showArabic,
    required this.showUrdu,
    required this.showEnglish,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(isHadithBookmarkedProvider(hadith.id));

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF080C0A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF1A221C)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2E21),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00E676)),
                  ),
                  child: Text(
                    '#${hadith.hadithNumber}',
                    style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontWeight: FontWeight.w800,
                        fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hadith.grade.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hadith.grade.label,
                    style: TextStyle(
                        color: hadith.grade.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isBookmarked
                        ? const Color(0xFFFFB703)
                        : const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(hadithBookmarksProvider.notifier)
                        .toggleBookmark(hadith);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded,
                      color: Color(0xFF64748B), size: 18),
                  onPressed: () {
                    final shareText =
                        '${hadith.textArabic}\n\n${hadith.textUrdu}\n\n"${hadith.textEnglish}"\n\n— ${hadith.displayReference}';
                    Clipboard.setData(ClipboardData(text: shareText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Hadith copied! 📋'),
                          backgroundColor: Color(0xFF0B2E21),
                          duration: Duration(seconds: 1)),
                    );
                  },
                ),
              ],
            ),
            if (showArabic && hadith.hasArabic) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A140F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E3A2B)),
                ),
                child: Text(
                  hadith.textArabic,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                      fontSize: 17,
                      height: 1.7,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
            if (showUrdu && hadith.hasUrdu) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF081810),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF00E676).withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('اردو ترجمہ',
                          style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hadith.textUrdu,
                      style: const TextStyle(
                          color: Color(0xFFD1FAE5), fontSize: 14, height: 1.7),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
            if (showEnglish && hadith.hasEnglish) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B121C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E3A5F)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ENGLISH',
                        style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(
                      hadith.textEnglish,
                      style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 12.5,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
            if (hadith.chapterName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Chapter: ${hadith.chapterName}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
