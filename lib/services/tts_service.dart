import 'package:flutter_tts/flutter_tts.dart';

/// Basit TTS servisi: tek örnek üzerinden konuşma başlat/bitir.
class TtsService {
  TtsService._internal();
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> _ensureInit() async {
    if (_isInitialized) return;
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureInit();
    await _tts.stop(); // önceki sesi kes
    await _tts.speak(text);
  }

  Future<void> stop() async {
    if (!_isInitialized) return;
    await _tts.stop();
  }
}

