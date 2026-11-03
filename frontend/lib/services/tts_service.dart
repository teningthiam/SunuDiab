import 'package:flutter_tts/flutter_tts.dart';

/// Lecture vocale (français uniquement : les voix système ne gèrent pas le wolof).
class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _ready = false;

  static Future<void> speak(String text) async {
    try {
      if (!_ready) {
        await _tts.setLanguage('fr-FR');
        await _tts.setSpeechRate(0.45);
        _ready = true;
      }
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // moteur vocal indisponible : on ignore
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
