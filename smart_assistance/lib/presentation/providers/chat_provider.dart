import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/locale/app_locale.dart';
import '../../data/models/message.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/stt_service.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/settings_repository.dart';

class ChatProvider extends ChangeNotifier {
  final AIService _aiService;
  final TTSService _ttsService;
  final STTService _sttService;
  final HistoryRepository _historyRepository;
  final SettingsRepository _settingsRepository;
  final Uuid _uuid;

  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  bool _ttsEnabled = true;
  bool _sttEnabled = true;
  ThemeMode _themeMode = ThemeMode.system;
  AppLocale _locale = AppLocale.french;
  String _lastRecognizedText = '';
  String? _errorMessage;

  ChatProvider({
    AIService? aiService,
    TTSService? ttsService,
    STTService? sttService,
    HistoryRepository? historyRepository,
    SettingsRepository? settingsRepository,
    Uuid? uuid,
  })  : _aiService = aiService ?? AIService(),
        _ttsService = ttsService ?? TTSService(),
        _sttService = sttService ?? STTService(),
        _historyRepository = historyRepository ?? HistoryRepository(),
        _settingsRepository = settingsRepository ?? SettingsRepository(),
        _uuid = uuid ?? const Uuid();

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isListening => _isListening;
  bool get ttsEnabled => _ttsEnabled;
  bool get sttEnabled => _sttEnabled;
  ThemeMode get themeMode => _themeMode;
  AppLocale get locale => _locale;
  String get lastRecognizedText => _lastRecognizedText;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    await _ttsService.initialize();
    await _sttService.initialize();

    _ttsEnabled = await _settingsRepository.getTtsEnabled();
    _sttEnabled = await _settingsRepository.getSttEnabled();
    _themeMode = await _settingsRepository.getThemeMode();
    _locale = await _settingsRepository.getLocale();

    final history = await _historyRepository.getHistory();
    _messages = List<Message>.from(history);

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _settingsRepository.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setLocale(AppLocale locale) async {
    _locale = locale;
    await _settingsRepository.setLocale(locale);
    notifyListeners();
  }

  void initSTTCallbacks() {
    _sttService.onResult = (text) {
      _lastRecognizedText = text;
      if (text.isNotEmpty) {
        sendMessage(text);
      }
      notifyListeners();
    };

    _sttService.onStart = () {
      _isListening = true;
      _errorMessage = null;
      notifyListeners();
    };

    _sttService.onEnd = () {
      _isListening = false;
      notifyListeners();
    };

    _sttService.onError = (error) {
      _errorMessage = error;
      _isListening = false;
      notifyListeners();
    };
  }

  /// Ajoute un message statique du bot sans appel API.
  /// Utilisé pour le message d'accueil au premier lancement.
  /// Si [speak] est true et TTS activé, le texte est aussi lu à voix haute.
  Future<void> addLocalBotMessage(String content, {bool speak = false}) async {
    final message = Message(
      id: _uuid.v4(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      status: MessageStatus.received,
    );
    _messages.add(message);
    await _historyRepository.addMessage(message);
    notifyListeners();
    if (speak && _ttsEnabled) {
      await _ttsService.speak(content);
    }
  }

  Future<void> sendMessage(String content, {List<String>? imagePaths}) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty && (imagePaths == null || imagePaths.isEmpty)) {
      return;
    }

    final userMessage = Message(
      id: _uuid.v4(),
      content: trimmed.isEmpty ? 'Image envoyée' : trimmed,
      isUser: true,
      timestamp: DateTime.now(),
      status: MessageStatus.received,
      imagePaths: imagePaths,
    );

    _messages.add(userMessage);
    await _historyRepository.addMessage(userMessage);

    final botId = _uuid.v4();
    var botMessage = Message(
      id: botId,
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    _messages.add(botMessage);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    String fullReply = '';
    bool gotError = false;

    try {
      await for (final event in _aiService.streamResponse(trimmed,
          imagePaths: imagePaths, locale: _locale.code)) {
        switch (event) {
          case AiChunk(content: final chunk):
            final idx = _messages.indexWhere((m) => m.id == botId);
            if (idx >= 0) {
              final updated =
                  _messages[idx].copyWith(content: _messages[idx].content + chunk);
              _messages[idx] = updated;
              notifyListeners();
            }
            break;
          case AiDone(fullText: final text):
            fullReply = text;
            final idx = _messages.indexWhere((m) => m.id == botId);
            if (idx >= 0) {
              _messages[idx] = _messages[idx].copyWith(
                content: text,
                status: MessageStatus.received,
              );
            }
            break;
          case AiError(message: final msg):
            gotError = true;
            _errorMessage = msg;
            final idx = _messages.indexWhere((m) => m.id == botId);
            if (idx >= 0) {
              _messages[idx] = _messages[idx].copyWith(
                content: 'Désolé, j\'ai rencontré une erreur. Réessayez.',
                status: MessageStatus.error,
              );
            }
            break;
        }
      }
    } catch (e) {
      gotError = true;
      _errorMessage = 'Erreur lors de la génération de la réponse';
      if (kDebugMode) {
        debugPrint('ChatProvider stream error: $e');
      }
      final idx = _messages.indexWhere((m) => m.id == botId);
      if (idx >= 0) {
        _messages[idx] = _messages[idx].copyWith(
          content: 'Désolé, j\'ai rencontré une erreur. Réessayez.',
          status: MessageStatus.error,
        );
      }
    }

    final idx = _messages.indexWhere((m) => m.id == botId);
    if (idx >= 0) {
      await _historyRepository.addMessage(_messages[idx]);
    }

    if (!gotError && fullReply.isNotEmpty && _ttsEnabled) {
      await _ttsService.speak(fullReply);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> startListening() async {
    if (!_sttEnabled) {
      _errorMessage = 'La reconnaissance vocale est désactivée';
      notifyListeners();
      return;
    }

    initSTTCallbacks();
    await _sttService.startListening();
  }

  Future<void> stopListening() async {
    await _sttService.stopListening();
  }

  Future<void> speakMessage(String text) async {
    if (_ttsEnabled) {
      await _ttsService.speak(text);
    }
  }

  Future<void> stopSpeaking() async {
    await _ttsService.stop();
  }

  Future<void> clearHistory() async {
    await _historyRepository.clearHistory();
    _messages = [];
    notifyListeners();
  }

  Future<void> deleteMessage(String messageId) async {
    await _historyRepository.deleteMessage(messageId);
    _messages.removeWhere((m) => m.id == messageId);
    notifyListeners();
  }

  Future<void> setTtsEnabled(bool enabled) async {
    _ttsEnabled = enabled;
    await _settingsRepository.setTtsEnabled(enabled);
    notifyListeners();
  }

  Future<void> setSttEnabled(bool enabled) async {
    _sttEnabled = enabled;
    await _settingsRepository.setSttEnabled(enabled);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    _sttService.dispose();
    _aiService.dispose();
    super.dispose();
  }
}
