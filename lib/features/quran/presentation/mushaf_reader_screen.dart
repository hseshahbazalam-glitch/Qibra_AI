// lib/features/quran/presentation/mushaf_reader_screen.dart
// ============================================================
// QIBRA AI — Premium Mushaf Reader v4.0
// Ornamental Corners + Golden Borders + Luxury Design
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository/reading_progress_repository.dart';
import '../data/services/mushaf_page_service.dart';
import '../providers/reading_progress_provider.dart';

// ============================================================
// READING MODE
// ============================================================

enum ReadingMode {
  light,
  night,
  sepia;

  String get label {
    return switch (this) {
      ReadingMode.light => 'Light',
      ReadingMode.night => 'Night',
      ReadingMode.sepia => 'Sepia',
    };
  }

  IconData get icon {
    return switch (this) {
      ReadingMode.light => Icons.wb_sunny_rounded,
      ReadingMode.night => Icons.nightlight_round,
      ReadingMode.sepia => Icons.local_cafe_rounded,
    };
  }

  Color get pageBackground {
    return switch (this) {
      ReadingMode.light => const Color(0xFFFBF6E9),
      ReadingMode.night => const Color(0xFF0F1B15),
      ReadingMode.sepia => const Color(0xFFF4E8CD),
    };
  }

  Color get pageBackgroundEnd {
    return switch (this) {
      ReadingMode.light => const Color(0xFFF5EDD5),
      ReadingMode.night => const Color(0xFF0A1410),
      ReadingMode.sepia => const Color(0xFFEDDCB0),
    };
  }

  Color get textColor {
    return switch (this) {
      ReadingMode.light => const Color(0xFF1A1A1A),
      ReadingMode.night => const Color(0xFFF0E6CC),
      ReadingMode.sepia => const Color(0xFF3D2914),
    };
  }

  Color get accentColor {
    return switch (this) {
      ReadingMode.light => const Color(0xFFB8860B),
      ReadingMode.night => const Color(0xFFD4AF37),
      ReadingMode.sepia => const Color(0xFF8B4513),
    };
  }

  Color get borderColor {
    return switch (this) {
      ReadingMode.light => const Color(0xFFB8860B),
      ReadingMode.night => const Color(0xFFD4AF37),
      ReadingMode.sepia => const Color(0xFF8B4513),
    };
  }

  Color get scaffoldBg {
    return switch (this) {
      ReadingMode.light => const Color(0xFF000000),
      ReadingMode.night => const Color(0xFF000000),
      ReadingMode.sepia => const Color(0xFF1A0F05),
    };
  }
}

// ============================================================
// FONT SIZE
// ============================================================

enum MushafFontSize {
  small(20),
  medium(24),
  large(28),
  xLarge(32);

  final double size;
  const MushafFontSize(this.size);

  String get label {
    return switch (this) {
      MushafFontSize.small => 'S',
      MushafFontSize.medium => 'M',
      MushafFontSize.large => 'L',
      MushafFontSize.xLarge => 'XL',
    };
  }
}

// ============================================================
// JUZ DATA
// ============================================================

class _JuzData {
  static const List<Map<String, dynamic>> juzPages = [
    {'juz': 1, 'startPage': 1},
    {'juz': 2, 'startPage': 22},
    {'juz': 3, 'startPage': 42},
    {'juz': 4, 'startPage': 62},
    {'juz': 5, 'startPage': 82},
    {'juz': 6, 'startPage': 102},
    {'juz': 7, 'startPage': 121},
    {'juz': 8, 'startPage': 142},
    {'juz': 9, 'startPage': 162},
    {'juz': 10, 'startPage': 182},
    {'juz': 11, 'startPage': 201},
    {'juz': 12, 'startPage': 222},
    {'juz': 13, 'startPage': 242},
    {'juz': 14, 'startPage': 262},
    {'juz': 15, 'startPage': 282},
    {'juz': 16, 'startPage': 302},
    {'juz': 17, 'startPage': 322},
    {'juz': 18, 'startPage': 342},
    {'juz': 19, 'startPage': 362},
    {'juz': 20, 'startPage': 382},
    {'juz': 21, 'startPage': 402},
    {'juz': 22, 'startPage': 422},
    {'juz': 23, 'startPage': 442},
    {'juz': 24, 'startPage': 462},
    {'juz': 25, 'startPage': 482},
    {'juz': 26, 'startPage': 502},
    {'juz': 27, 'startPage': 522},
    {'juz': 28, 'startPage': 542},
    {'juz': 29, 'startPage': 562},
    {'juz': 30, 'startPage': 582},
  ];

  static int getJuzForPage(int page) {
    int juz = 1;
    for (final j in juzPages) {
      if (page >= (j['startPage'] as int)) {
        juz = j['juz'] as int;
      } else {
        break;
      }
    }
    return juz;
  }
}

// ============================================================
// MUSHAF READER SCREEN
// ============================================================

class MushafReaderScreen extends ConsumerStatefulWidget {
  final int initialPage;

  const MushafReaderScreen({
    super.key,
    this.initialPage = 1,
  });

  @override
  ConsumerState<MushafReaderScreen> createState() => _MushafReaderScreenState();
}

class _MushafReaderScreenState extends ConsumerState<MushafReaderScreen> {
  late PageController _pageController;
  final _mushafService = MushafPageService.instance;

  int _currentPage = 1;
  static const int _totalPages = 604;

  bool _showControls = true;
  bool _isLoading = true;
  Timer? _controlsTimer;
  Timer? _saveTimer;

  DateTime? _pageOpenedAt;
  int _totalReadingSeconds = 0;

  final TextEditingController _pageInputController = TextEditingController();

  ReadingMode _readingMode = ReadingMode.light;
  MushafFontSize _fontSize = MushafFontSize.medium;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, _totalPages);

    _pageController = PageController(
      initialPage: _currentPage - 1,
      viewportFraction: 1.0,
    );

    _pageOpenedAt = DateTime.now();

    _initService();
    _startControlsTimer();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  Future<void> _initService() async {
    await _mushafService.initialize();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controlsTimer?.cancel();
    _saveTimer?.cancel();
    _pageInputController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startControlsTimer();
  }

  void _onPageChanged(int index) {
    final newPage = index + 1;
    setState(() => _currentPage = newPage);

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () {
      _saveProgress(newPage);
    });
  }

  Future<void> _saveProgress(int page) async {
    final pageData = _mushafService.getPageSync(page);

    if (_pageOpenedAt != null) {
      _totalReadingSeconds +=
          DateTime.now().difference(_pageOpenedAt!).inSeconds;
      _pageOpenedAt = DateTime.now();
    }

    final model = MushafPageModel(
      pageNumber: page,
      surahNumber: pageData?.primarySurahNumber ?? 1,
      surahName: pageData?.primarySurahNameEnglish ?? 'Al-Fatihah',
      ayahNumber: pageData?.ayahs.first.ayahNumber ?? 1,
      juzNumber: pageData?.juz ?? _JuzData.getJuzForPage(page),
      hizbNumber: ((_JuzData.getJuzForPage(page) - 1) * 2) + 1,
      savedAt: DateTime.now(),
      totalReadingSeconds: _totalReadingSeconds,
    );

    await ref.read(readingProgressProvider.notifier).savePage(model);
  }

  void _jumpToPage(int page) {
    final target = page.clamp(1, _totalPages);
    _pageController.animateToPage(
      target - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _readingMode.scaffoldBg,
        body: Center(
          child: CircularProgressIndicator(
            color: _readingMode.accentColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _readingMode.scaffoldBg,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: _readingMode.scaffoldBg,
        child: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            children: [
              // Main Page View
              PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _totalPages,
                reverse: true,
                itemBuilder: (context, index) {
                  return _MushafPageWidget(
                    pageNumber: index + 1,
                    service: _mushafService,
                    readingMode: _readingMode,
                    fontSize: _fontSize,
                  );
                },
              ),

              if (_showControls) _buildTopBar(),
              if (_showControls) _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    final pageData = _mushafService.getPageSync(_currentPage);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _showControls ? 1.0 : 0.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.92),
                Colors.black.withValues(alpha: 0.5),
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  _iconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        pageData?.primarySurahName ?? '',
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          color: Color(0xFFD4AF37),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'JUZ ${pageData?.juz ?? 1}  •  PAGE $_currentPage',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _iconButton(
                    icon: Icons.tune_rounded,
                    onTap: _showSettings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM BAR
  // ============================================================

  Widget _buildBottomBar() {
    final progress = _currentPage / _totalPages;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _showControls ? 1.0 : 0.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.97),
                Colors.black.withValues(alpha: 0.6),
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Page $_currentPage',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFD4AF37).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                const Color(0xFFD4AF37).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${(progress * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$_totalPages',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFD4AF37),
                              Color(0xFFF4CE5B),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37)
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _navButton(
                        icon: Icons.chevron_left_rounded,
                        label: 'Previous',
                        onTap: _currentPage > 1
                            ? () => _jumpToPage(_currentPage - 1)
                            : null,
                      ),
                      _navButton(
                        icon: Icons.menu_book_rounded,
                        label: 'Juz',
                        onTap: _showJuzSelector,
                      ),
                      _navButton(
                        icon: Icons.format_list_numbered_rounded,
                        label: 'Page',
                        onTap: _showPageJumper,
                      ),
                      _navButton(
                        icon: Icons.chevron_right_rounded,
                        label: 'Next',
                        onTap: _currentPage < _totalPages
                            ? () => _jumpToPage(_currentPage + 1)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _iconButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: enabled
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF1A2744),
                        const Color(0xFF0F1B2E),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              color: enabled ? null : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: enabled
                    ? const Color(0xFFD4AF37).withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.05),
                width: 1.2,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: enabled ? const Color(0xFFD4AF37) : Colors.white24,
              size: 24,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: enabled
                  ? Colors.white.withValues(alpha: 0.75)
                  : Colors.white24,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1B2A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: Color(0xFFD4AF37),
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Reading Settings',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _sectionLabel('READING MODE'),
                  const SizedBox(height: 12),
                  Row(
                    children: ReadingMode.values.map((mode) {
                      final isSelected = _readingMode == mode;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _readingMode = mode);
                              setModalState(() {});
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFD4AF37),
                                          Color(0xFFB8860B),
                                        ],
                                      )
                                    : null,
                                color:
                                    isSelected ? null : const Color(0xFF1A2744),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFD4AF37)
                                      : Colors.white.withValues(alpha: 0.1),
                                  width: 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFD4AF37)
                                              .withValues(alpha: 0.4),
                                          blurRadius: 15,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    mode.icon,
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white,
                                    size: 26,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    mode.label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  _sectionLabel('FONT SIZE'),
                  const SizedBox(height: 12),
                  Row(
                    children: MushafFontSize.values.map((size) {
                      final isSelected = _fontSize == size;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _fontSize = size);
                              setModalState(() {});
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFD4AF37),
                                          Color(0xFFB8860B),
                                        ],
                                      )
                                    : null,
                                color:
                                    isSelected ? null : const Color(0xFF1A2744),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFD4AF37)
                                      : Colors.white.withValues(alpha: 0.1),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  size.label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // PAGE JUMPER
  // ============================================================

  void _showPageJumper() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
          ),
        ),
        title: const Text(
          'Jump to Page',
          style: TextStyle(color: Color(0xFFD4AF37)),
        ),
        content: TextField(
          controller: _pageInputController,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '1 - 604',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFD4AF37)),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final page = int.tryParse(_pageInputController.text);
              if (page != null) {
                Navigator.pop(ctx);
                _pageInputController.clear();
                _jumpToPage(page);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // JUZ SELECTOR
  // ============================================================

  void _showJuzSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Jump to Juz',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: 30,
                  itemBuilder: (context, index) {
                    final juz = index + 1;
                    final isCurrent =
                        _JuzData.getJuzForPage(_currentPage) == juz;

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        final juzData = _JuzData.juzPages[index];
                        _jumpToPage(juzData['startPage'] as int);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isCurrent
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFD4AF37),
                                    Color(0xFFB8860B),
                                  ],
                                )
                              : null,
                          color: isCurrent ? null : const Color(0xFF1A2744),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent
                                ? const Color(0xFFD4AF37)
                                : Colors.white.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$juz',
                            style: TextStyle(
                              color: isCurrent ? Colors.black : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
        );
      },
    );
  }
}

// ============================================================
// MUSHAF PAGE WIDGET — LUXURY DESIGN
// ============================================================

class _MushafPageWidget extends StatelessWidget {
  final int pageNumber;
  final MushafPageService service;
  final ReadingMode readingMode;
  final MushafFontSize fontSize;

  const _MushafPageWidget({
    required this.pageNumber,
    required this.service,
    required this.readingMode,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final pageData = service.getPageSync(pageNumber);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: readingMode.scaffoldBg,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        left: 8,
        right: 8,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              readingMode.pageBackground,
              readingMode.pageBackgroundEnd,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 25,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: readingMode.accentColor.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: readingMode.accentColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: readingMode.accentColor.withValues(alpha: 0.7),
                        width: 0.8,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        _buildHeader(pageData),
                        _buildFancyDivider(),
                        Expanded(
                          child: pageData == null
                              ? _buildLoading()
                              : _buildAyahs(pageData, context),
                        ),
                        _buildFancyDivider(),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Corner Ornaments
            _cornerOrnament(Alignment.topLeft),
            _cornerOrnament(Alignment.topRight),
            _cornerOrnament(Alignment.bottomLeft),
            _cornerOrnament(Alignment.bottomRight),
          ],
        ),
      ),
    );
  }

  Widget _cornerOrnament(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: readingMode.accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: readingMode.accentColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.star_rounded,
            size: 18,
            color: readingMode.accentColor.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildFancyDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    readingMode.accentColor.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.circle,
              size: 4,
              color: readingMode.accentColor.withValues(alpha: 0.6),
            ),
          ),
          Icon(
            Icons.star_rounded,
            size: 14,
            color: readingMode.accentColor,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.circle,
              size: 4,
              color: readingMode.accentColor.withValues(alpha: 0.6),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    readingMode.accentColor.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(MushafPageData? pageData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            pageData?.primarySurahNameEnglish ?? '',
            style: TextStyle(
              fontSize: 13,
              color: readingMode.accentColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: readingMode.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: readingMode.accentColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'الجزء ${pageData?.juz ?? _JuzData.getJuzForPage(pageNumber)}',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 14,
                color: readingMode.accentColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: readingMode.accentColor,
      ),
    );
  }

  Widget _buildAyahs(MushafPageData pageData, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._buildSurahHeaders(pageData),
          _buildAyahsRichText(pageData),
        ],
      ),
    );
  }

  List<Widget> _buildSurahHeaders(MushafPageData pageData) {
    final headers = <Widget>[];
    final shownSurahs = <int>{};

    for (final ayah in pageData.ayahs) {
      if (ayah.ayahNumber == 1 && !shownSurahs.contains(ayah.surahNumber)) {
        shownSurahs.add(ayah.surahNumber);
        headers.add(_buildSurahHeader(ayah));
        headers.add(const SizedBox(height: 12));
      }
    }

    return headers;
  }

  Widget _buildSurahHeader(MushafAyah ayah) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            readingMode.accentColor.withValues(alpha: 0.05),
            readingMode.accentColor.withValues(alpha: 0.25),
            readingMode.accentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: readingMode.accentColor.withValues(alpha: 0.6),
          width: 1.8,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star_rounded,
                size: 14,
                color: readingMode.accentColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Text(
                ayah.surahName,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: readingMode.accentColor,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.star_rounded,
                size: 14,
                color: readingMode.accentColor.withValues(alpha: 0.7),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ayah.surahNameEnglish.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              color: readingMode.accentColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyahsRichText(MushafPageData pageData) {
    final spans = <TextSpan>[];

    for (int i = 0; i < pageData.ayahs.length; i++) {
      final ayah = pageData.ayahs[i];

      String text = ayah.arabicText;
      if (ayah.isBismillah) {
        text = text.replaceFirst(
          RegExp(r'^بِسْمِ.*?الرَّحِيمِ\s*'),
          '',
        );
        if (text.trim().isEmpty) continue;
      }

      spans.add(
        TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: fontSize.size,
            height: 2.3,
            color: readingMode.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

      spans.add(
        TextSpan(
          text: ' ﴿${_toArabicNumber(ayah.ayahNumber)}﴾ ',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: fontSize.size * 0.75,
            color: readingMode.accentColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RichText(
        text: TextSpan(children: spans),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            height: 1.5,
            width: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  readingMode.accentColor.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  readingMode.accentColor.withValues(alpha: 0.15),
                  readingMode.accentColor.withValues(alpha: 0.25),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: readingMode.accentColor,
                width: 1.2,
              ),
            ),
            child: Text(
              _toArabicNumber(pageNumber),
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                color: readingMode.accentColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          Container(
            height: 1.5,
            width: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  readingMode.accentColor.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _toArabicNumber(int number) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => arabic[int.parse(d)]).join();
  }
}
