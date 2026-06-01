import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';

class STTService {
  stt.SpeechToText? _speech;
  bool _isInitialized = false;
  bool _isListening = false;

  Function(String)? onResult;
  Function()? onStart;
  Function()? onEnd;
  Function(String)? onError;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    final status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      return false;
    }

    _speech = stt.SpeechToText();
    _isInitialized = await _speech!.initialize(
      onError: (error) {
        onError?.call(error.errorMsg);
        _isListening = false;
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          onEnd?.call();
        }
      },
    );
    return _isInitialized;
  }

  Future<void> startListening({String localeId = 'fr_FR'}) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('Permission microphone refusée');
        return;
      }
    }

    if (!_isInitialized || _speech == null) {
      onError?.call('Reconnaissance vocale non disponible');
      return;
    }

    _isListening = true;
    onStart?.call();

    await _speech!.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          onResult?.call(result.recognizedWords);
          _isListening = false;
          onEnd?.call();
        }
      },
      localeId: localeId,
      listenMode: stt.ListenMode.dictation,
      cancelOnError: true,
      partialResults: false,
    );
  }

  Future<void> stopListening() async {
    if (_speech != null && _isListening) {
      await _speech!.stop();
      _isListening = false;
      onEnd?.call();
    }
  }

  Future<void> cancel() async {
    if (_speech != null) {
      await _speech!.cancel();
      _isListening = false;
      onEnd?.call();
    }
  }

  bool get isListening => _isListening;

  Future<void> dispose() async {
    if (_speech != null) {
      await _speech!.cancel();
      _speech = null;
    }
    _isInitialized = false;
  }
}