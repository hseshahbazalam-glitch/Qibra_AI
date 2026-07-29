import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reciter_model.dart';

class QuranAudioService extends ChangeNotifier {
  static final QuranAudioService _instance = QuranAudioService._internal();
  factory QuranAudioService() => _instance;
  static QuranAudioService get instance => _instance;
  QuranAudioService._internal() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();

  Reciter _currentReciter = famousReciters[1]; // Mishary default
  int? _currentSurah;
  String? _currentSurahName;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  bool _repeatMode = false;

  // Getters
  Reciter get currentReciter => _currentReciter;
  int? get currentSurah => _currentSurah;
  String? get currentSurahName => _currentSurahName;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  double get speed => _speed;
  bool get repeatMode => _repeatMode;
  AudioPlayer get player => _player;

  Stream<Duration> get positionStream => _player.onPositionChanged;
  Stream<Duration> get durationStream => _player.onDurationChanged;

  void _init() {
    _loadSavedReciter();

    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      _isLoading = false;
      notifyListeners();
    });

    _player.onPositionChanged.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.onDurationChanged.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    _player.onPlayerComplete.listen((_) {
      if (_repeatMode) {
        _player.seek(Duration.zero);
        _player.resume();
      } else {
        playNextSurah();
      }
    });
  }

  Future<void> _loadSavedReciter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('reciter_id') ?? 'mishary';
    _currentReciter = famousReciters.firstWhere(
      (r) => r.id == savedId,
      orElse: () => famousReciters[1],
    );
    notifyListeners();
  }

  Future<void> setReciter(Reciter reciter) async {
    _currentReciter = reciter;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reciter_id', reciter.id);

    if (_currentSurah != null && _currentSurahName != null) {
      final wasPlaying = _isPlaying;
      await playSurah(_currentSurah!, _currentSurahName!);
      if (!wasPlaying) await pause();
    }
    notifyListeners();
  }

  Future<void> playSurah(int surahNumber, String surahName) async {
    try {
      _isLoading = true;
      _currentSurah = surahNumber;
      _currentSurahName = surahName;
      notifyListeners();

      final url = _currentReciter.getSurahUrl(surahNumber);
      debugPrint('🎵 Playing: $url');

      await _player.play(UrlSource(url));

      _saveLastPlayed(surahNumber, surahName);
    } catch (e) {
      debugPrint('❌ Playback error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.resume();

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentSurah = null;
    _currentSurahName = null;
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async => await _player.seek(position);

  Future<void> playNextSurah() async {
    if (_currentSurah == null) return;
    final next = _currentSurah! + 1;
    if (next <= 114) {
      await playSurah(next, 'Surah $next');
    }
  }

  Future<void> playPreviousSurah() async {
    if (_currentSurah == null) return;
    final prev = _currentSurah! - 1;
    if (prev >= 1) {
      await playSurah(prev, 'Surah $prev');
    }
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _player.setPlaybackRate(speed);
    notifyListeners();
  }

  void toggleRepeat() {
    _repeatMode = !_repeatMode;
    notifyListeners();
  }

  Future<void> _saveLastPlayed(int surah, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_played_surah', surah);
    await prefs.setString('last_played_name', name);
  }

  Future<Map<String, dynamic>?> getLastPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final surah = prefs.getInt('last_played_surah');
    final name = prefs.getString('last_played_name');
    if (surah != null && name != null) {
      return {'surah': surah, 'name': name};
    }
    return null;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
