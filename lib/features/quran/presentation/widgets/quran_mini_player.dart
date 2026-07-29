import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/quran_audio_service.dart';
import 'quran_audio_player_sheet.dart';

class QuranMiniPlayer extends StatefulWidget {
  const QuranMiniPlayer({super.key});

  @override
  State<QuranMiniPlayer> createState() => _QuranMiniPlayerState();
}

class _QuranMiniPlayerState extends State<QuranMiniPlayer> {
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

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (_audio.currentSurah == null) return const SizedBox.shrink();

    final reciter = _audio.currentReciter;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => const QuranAudioPlayerSheet(),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              reciter.themeColor.withValues(alpha: 0.15),
              reciter.themeColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: reciter.themeColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  reciter.themeColor,
                  reciter.themeColor.withValues(alpha: 0.6),
                ]),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🕌', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _audio.currentSurahName ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    reciter.name,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _audio.togglePlayPause(),
              icon: Icon(
                _audio.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: reciter.themeColor,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
