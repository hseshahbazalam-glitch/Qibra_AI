import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/models/reciter_model.dart';

class QuranAudioPlayerSheet extends StatefulWidget {
  const QuranAudioPlayerSheet({super.key});

  @override
  State<QuranAudioPlayerSheet> createState() => _QuranAudioPlayerSheetState();
}

class _QuranAudioPlayerSheetState extends State<QuranAudioPlayerSheet> {
  final _audioService = QuranAudioService.instance;

  @override
  void initState() {
    super.initState();
    _audioService.addListener(_update);
  }

  @override
  void dispose() {
    _audioService.removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final reciter = _audioService.currentReciter;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            reciter.themeColor.withValues(alpha: 0.3),
            const Color(0xFF0A0E1A),
            const Color(0xFF0A0E1A),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
                const Spacer(),
                Text('NOW PLAYING',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    )),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showReciterSelector(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Album Art
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    reciter.themeColor,
                    reciter.themeColor.withValues(alpha: 0.6),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: reciter.themeColor.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  const Text('🕌', style: TextStyle(fontSize: 80)),
                  if (_audioService.isLoading)
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Surah Name
          Text(
            _audioService.currentSurahName ?? 'No Surah Selected',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),

          // Reciter Name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(reciter.flag, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(
                reciter.name,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: reciter.themeColor,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                    thumbColor: Colors.white,
                    overlayColor: reciter.themeColor.withValues(alpha: 0.2),
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: _audioService.position.inSeconds.toDouble(),
                    max: _audioService.duration.inSeconds.toDouble() > 0
                        ? _audioService.duration.inSeconds.toDouble()
                        : 1.0,
                    onChanged: (v) {
                      _audioService.seekTo(Duration(seconds: v.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_audioService.position),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDuration(_audioService.duration),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _controlButton(
                Icons.shuffle_rounded,
                () {},
                small: true,
              ),
              _controlButton(
                Icons.skip_previous_rounded,
                () {
                  HapticFeedback.mediumImpact();
                  _audioService.playPreviousSurah();
                },
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  _audioService.togglePlayPause();
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: reciter.themeColor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _audioService.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: reciter.themeColor,
                    size: 40,
                  ),
                ),
              ),
              _controlButton(
                Icons.skip_next_rounded,
                () {
                  HapticFeedback.mediumImpact();
                  _audioService.playNextSurah();
                },
              ),
              _controlButton(
                _audioService.repeatMode
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                () {
                  HapticFeedback.selectionClick();
                  _audioService.toggleRepeat();
                },
                small: true,
                active: _audioService.repeatMode,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Extra Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _optionChip('${_audioService.speed}x', Icons.speed_rounded,
                    () => _showSpeedDialog(context)),
                _optionChip('Download', Icons.download_rounded, () {}),
                _optionChip('Share', Icons.share_rounded, () {}),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onTap,
      {bool small = false, bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(small ? 8 : 12),
        decoration: BoxDecoration(
          color: active
              ? _audioService.currentReciter.themeColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color:
              active ? _audioService.currentReciter.themeColor : Colors.white,
          size: small ? 20 : 32,
        ),
      ),
    );
  }

  Widget _optionChip(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReciterSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141926),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Reciter',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${famousReciters.length} world-class Qaris',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: famousReciters.length,
                itemBuilder: (c, i) {
                  final r = famousReciters[i];
                  final selected = r.id == _audioService.currentReciter.id;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _audioService.setReciter(r);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected
                            ? r.themeColor.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? r.themeColor
                              : Colors.white.withValues(alpha: 0.05),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                r.themeColor,
                                r.themeColor.withValues(alpha: 0.6),
                              ]),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(r.flag,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  r.arabicName,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    color: r.themeColor,
                                    fontSize: 14,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                Text(
                                  '${r.country} • ${r.bitrate}kbps',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            Icon(Icons.check_circle_rounded,
                                color: r.themeColor, size: 22),
                        ],
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

  void _showSpeedDialog(BuildContext context) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141926),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Playback Speed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ...speeds.map((s) => GestureDetector(
                  onTap: () {
                    _audioService.setSpeed(s);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${s}x',
                          style: TextStyle(
                            color: _audioService.speed == s
                                ? _audioService.currentReciter.themeColor
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: _audioService.speed == s
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
