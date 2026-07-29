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
  final _audio = QuranAudioService.instance;

  @override
  void initState() {
    super.initState();
    _audio.addListener(_update);
  }

  @override
  void dispose() {
    _audio.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final reciter = _audio.currentReciter;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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

          const SizedBox(height: 30),

          // Album Art
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
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
                  const Text('🕌', style: TextStyle(fontSize: 70)),
                  if (_audio.isLoading)
                    const SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          Text(
            _audio.currentSurahName ?? 'No Surah Selected',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),

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
                  ),
                  child: Slider(
                    value: _audio.position.inSeconds.toDouble().clamp(
                        0.0,
                        _audio.duration.inSeconds.toDouble() > 0
                            ? _audio.duration.inSeconds.toDouble()
                            : 1.0),
                    max: _audio.duration.inSeconds.toDouble() > 0
                        ? _audio.duration.inSeconds.toDouble()
                        : 1.0,
                    onChanged: (v) {
                      _audio.seekTo(Duration(seconds: v.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_audio.position),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDuration(_audio.duration),
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
                _audio.repeatMode
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                () {
                  HapticFeedback.selectionClick();
                  _audio.toggleRepeat();
                },
                small: true,
                active: _audio.repeatMode,
                color: reciter.themeColor,
              ),
              _controlButton(
                Icons.skip_previous_rounded,
                () {
                  HapticFeedback.mediumImpact();
                  _audio.playPreviousSurah();
                },
                color: reciter.themeColor,
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  _audio.togglePlayPause();
                },
                child: Container(
                  width: 70,
                  height: 70,
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
                    _audio.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: reciter.themeColor,
                    size: 38,
                  ),
                ),
              ),
              _controlButton(
                Icons.skip_next_rounded,
                () {
                  HapticFeedback.mediumImpact();
                  _audio.playNextSurah();
                },
                color: reciter.themeColor,
              ),
              _controlButton(
                Icons.speed_rounded,
                () => _showSpeedDialog(context),
                small: true,
                color: reciter.themeColor,
              ),
            ],
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _controlButton(
    IconData icon,
    VoidCallback onTap, {
    bool small = false,
    bool active = false,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(small ? 8 : 12),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: active ? color : Colors.white,
          size: small ? 20 : 32,
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
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: famousReciters.length,
                itemBuilder: (c, i) {
                  final r = famousReciters[i];
                  final selected = r.id == _audio.currentReciter.id;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _audio.setReciter(r);
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
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: r.themeColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(r.flag,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    )),
                                Text(r.arabicName,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      color: r.themeColor,
                                      fontSize: 13,
                                    ),
                                    textDirection: TextDirection.rtl),
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
                    _audio.setSpeed(s);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${s}x',
                        style: TextStyle(
                          color: _audio.speed == s
                              ? _audio.currentReciter.themeColor
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: _audio.speed == s
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
