import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isPlaying = false;

  Function()? onStart;
  Function()? onComplete;
  Function(String)? onError;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _flutterTts = FlutterTts();
    await _flutterTts!.setLanguage('fr-FR');
    await _flutterTts!.setSpeechRate(0.5);
    await _flutterTts!.setVolume(1.0);
    await _flutterTts!.setPitch(1.0);

    _flutterTts!.setStartHandler(() {
      _isPlaying = true;
      onStart?.call();
    });

    _flutterTts!.setCompletionHandler(() {
      _isPlaying = false;
      onComplete?.call();
    });

    _flutterTts!.setErrorHandler((msg) {
      _isPlaying = false;
      onError?.call(msg.toString());
    });

    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_flutterTts == null) return;

    await _flutterTts!.speak(text);
  }

  Future<void> stop() async {
    if (_flutterTts != null) {
      await _flutterTts!.stop();
      _isPlaying = false;
    }
  }

  Future<void> pause() async {
    if (_flutterTts != null) {
      await _flutterTts!.pause();
      _isPlaying = false;
    }
  }

  bool get isPlaying => _isPlaying;

  Future<void> setSpeechRate(double rate) async {
    if (_flutterTts != null) {
      await _flutterTts!.setSpeechRate(rate);
    }
  }

  Future<void> setVolume(double volume) async {
    if (_flutterTts != null) {
      await _flutterTts!.setVolume(volume);
    }
  }

  Future<void> dispose() async {
    if (_flutterTts != null) {
      await _flutterTts!.stop();
      _flutterTts = null;
    }
    _isInitialized = false;
  }
}