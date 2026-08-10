// lib/features/ai/services/voice_service.dart

// ============================================================
// QIBRA AI — VOICE SERVICE
// Speech-to-Text + Text-to-Speech
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  // Singleton
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  // Services
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  // State
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _currentLocale = 'en_US';

  // Callbacks
  void Function(String)? onResult;
  void Function(String)? onPartialResult;
  void Function()? onListeningStart;
  void Function()? onListeningStop;
  void Function()? onSpeakingStart;
  void Function()? onSpeakingStop;
  void Function(String)? onError;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get currentLocale => _currentLocale;

  // ============================================================
  // INITIALIZE
  // ============================================================
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Mic permission
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        debugPrint('Microphone permission denied');
        onError?.call('Microphone permission required');
        return false;
      }

      // Speech-to-Text init
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          _isListening = false;
          onError?.call(error.errorMsg);
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            onListeningStop?.call();
          }
        },
      );

      // Text-to-Speech setup
      await _setupTTS();

      debugPrint('Voice Service initialized: $_isInitialized');
      return _isInitialized;
    } catch (e) {
      debugPrint('Voice init error: $e');
      onError?.call('Voice service failed to initialize');
      return false;
    }
  }

  // ============================================================
  // SETUP TTS
  // ============================================================
  Future<void> _setupTTS() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
        onSpeakingStart?.call();
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        onSpeakingStop?.call();
      });

      _tts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _isSpeaking = false;
        onSpeakingStop?.call();
      });
    } catch (e) {
      debugPrint('TTS setup error: $e');
    }
  }

  // ============================================================
  // START LISTENING
  // ============================================================
  Future<void> startListening({String? localeId}) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    if (_isListening) {
      await stopListening();
      return;
    }

    // Stop TTS if speaking
    if (_isSpeaking) {
      await stopSpeaking();
    }

    try {
      _isListening = true;
      onListeningStart?.call();

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (result.finalResult) {
            final text = result.recognizedWords;
            if (text.isNotEmpty) {
              onResult?.call(text);
            }
            _isListening = false;
            onListeningStop?.call();
          } else {
            onPartialResult?.call(result.recognizedWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          localeId: localeId ?? _currentLocale,
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('Listen error: $e');
      _isListening = false;
      onListeningStop?.call();
      onError?.call('Voice recognition failed');
    }
  }

  // ============================================================
  // STOP LISTENING
  // ============================================================
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      onListeningStop?.call();
    }
  }

  // ============================================================
  // CANCEL LISTENING
  // ============================================================
  Future<void> cancelListening() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
      onListeningStop?.call();
    }
  }

  // ============================================================
  // SPEAK
  // ============================================================
  Future<void> speak(String text, {String? language}) async {
    if (text.isEmpty) return;

    try {
      if (_isSpeaking) {
        await _tts.stop();
      }

      final ttsLanguage = language ?? _detectTTSLanguage(text);
      await _tts.setLanguage(ttsLanguage);

      final cleanText = _cleanTextForSpeech(text);
      if (cleanText.isEmpty) return;

      await _tts.speak(cleanText);
    } catch (e) {
      debugPrint('Speak error: $e');
    }
  }

  // ============================================================
  // STOP SPEAKING
  // ============================================================
  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
      onSpeakingStop?.call();
    }
  }

  // ============================================================
  // SET LANGUAGE
  // ============================================================
  Future<void> setLanguage(String localeId) async {
    _currentLocale = localeId;
  }

  // ============================================================
  // SET TTS SPEED
  // ============================================================
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  // ============================================================
  // SET TTS PITCH
  // ============================================================
  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch);
  }

  // ============================================================
  // GET AVAILABLE LANGUAGES
  // ============================================================
  Future<List<String>> getAvailableLanguages() async {
    try {
      final locales = await _speech.locales();
      return locales.map((l) => l.localeId).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getTTSLanguages() async {
    try {
      final dynamic langs = await _tts.getLanguages;
      if (langs is List<dynamic>) {
        return langs;
      }
      return <dynamic>[];
    } catch (e) {
      return <dynamic>[];
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================
  String _detectTTSLanguage(String text) {
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) {
      if (RegExp(r'[ٹڈڑ]').hasMatch(text)) {
        return 'ur-PK';
      }
      return 'ar-SA';
    }
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
      return 'hi-IN';
    }
    return 'en-US';
  }

  String _cleanTextForSpeech(String text) {
    String cleaned = text;

    cleaned = cleaned.replaceAll(RegExp(r'```json[\s\S]*?```'), '');
    cleaned = cleaned.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'\*(.*?)\*'), r'$1');
    cleaned = cleaned.replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}'
        r'\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
        unicode: true,
      ),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  // ============================================================
  // DISPOSE
  // ============================================================
  Future<void> dispose() async {
    await stopListening();
    await stopSpeaking();
  }
}
