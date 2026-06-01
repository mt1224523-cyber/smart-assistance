import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_assistance/core/locale/app_locale.dart';
import 'package:smart_assistance/data/models/message.dart';
import 'package:smart_assistance/data/repositories/history_repository.dart';
import 'package:smart_assistance/data/repositories/settings_repository.dart';
import 'package:smart_assistance/data/services/ai_service.dart';
import 'package:smart_assistance/data/services/stt_service.dart';
import 'package:smart_assistance/data/services/tts_service.dart';
import 'package:smart_assistance/presentation/providers/chat_provider.dart';

class _MockAIService extends Mock implements AIService {}

class _MockTTSService extends Mock implements TTSService {}

class _MockSTTService extends Mock implements STTService {}

class _MockHistoryRepository extends Mock implements HistoryRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late _MockAIService ai;
  late _MockTTSService tts;
  late _MockSTTService stt;
  late _MockHistoryRepository history;
  late _MockSettingsRepository settings;
  late ChatProvider provider;

  setUpAll(() {
    registerFallbackValue(Message(
      id: 'fallback',
      content: '',
      isUser: false,
      timestamp: DateTime(2026, 1, 1),
    ));
    registerFallbackValue(ThemeMode.system);
    registerFallbackValue(AppLocale.french);
  });

  setUp(() async {
    ai = _MockAIService();
    tts = _MockTTSService();
    stt = _MockSTTService();
    history = _MockHistoryRepository();
    settings = _MockSettingsRepository();

    when(() => tts.initialize()).thenAnswer((_) async {});
    when(() => stt.initialize()).thenAnswer((_) async => true);
    when(() => settings.getTtsEnabled()).thenAnswer((_) async => true);
    when(() => settings.getSttEnabled()).thenAnswer((_) async => true);
    when(() => settings.getThemeMode())
        .thenAnswer((_) async => ThemeMode.system);
    when(() => settings.getLocale()).thenAnswer((_) async => AppLocale.french);
    when(() => settings.setTtsEnabled(any())).thenAnswer((_) async {});
    when(() => settings.setSttEnabled(any())).thenAnswer((_) async {});
    when(() => settings.setThemeMode(any())).thenAnswer((_) async {});
    when(() => settings.setLocale(any())).thenAnswer((_) async {});
    when(() => history.getHistory()).thenAnswer((_) async => const []);
    when(() => history.addMessage(any())).thenAnswer((_) async {});
    when(() => history.clearHistory()).thenAnswer((_) async {});
    when(() => history.deleteMessage(any())).thenAnswer((_) async {});
    when(() => tts.speak(any())).thenAnswer((_) async {});
    when(() => ai.dispose()).thenReturn(null);

    provider = ChatProvider(
      aiService: ai,
      ttsService: tts,
      sttService: stt,
      historyRepository: history,
      settingsRepository: settings,
    );
    await provider.initialize();
  });

  test('initialize charge les paramètres et l\'historique', () async {
    verify(() => settings.getTtsEnabled()).called(1);
    verify(() => history.getHistory()).called(1);
    expect(provider.ttsEnabled, isTrue);
    expect(provider.messages, isEmpty);
  });

  test('sendMessage diffuse les chunks et compose la réponse complète',
      () async {
    when(() => ai.streamResponse(any(),
            imagePaths: any(named: 'imagePaths'),
            locale: any(named: 'locale')))
        .thenAnswer((_) => Stream<AiStreamEvent>.fromIterable(const [
              AiChunk('Bonj'),
              AiChunk('our '),
              AiChunk('Abidjan'),
              AiDone('Bonjour Abidjan'),
            ]));

    await provider.sendMessage('Salut');

    expect(provider.messages, hasLength(2));
    expect(provider.messages[0].isUser, isTrue);
    expect(provider.messages[0].content, 'Salut');
    expect(provider.messages[1].isUser, isFalse);
    expect(provider.messages[1].content, 'Bonjour Abidjan');
    expect(provider.messages[1].status, MessageStatus.received);
    expect(provider.isLoading, isFalse);
    verify(() => tts.speak('Bonjour Abidjan')).called(1);
  });

  test('AiError bascule le message bot en statut erreur', () async {
    when(() => ai.streamResponse(any(),
            imagePaths: any(named: 'imagePaths'),
            locale: any(named: 'locale')))
        .thenAnswer((_) => Stream<AiStreamEvent>.fromIterable(const [
              AiError('network', 'pas de connexion'),
            ]));

    await provider.sendMessage('Salut');

    expect(provider.messages.last.status, MessageStatus.error);
    expect(provider.errorMessage, 'pas de connexion');
    verifyNever(() => tts.speak(any()));
  });

  test('addLocalBotMessage n\'appelle pas AIService', () async {
    await provider.addLocalBotMessage('Bienvenue');

    expect(provider.messages, hasLength(1));
    expect(provider.messages.single.content, 'Bienvenue');
    expect(provider.messages.single.isUser, isFalse);
    verifyNever(() => ai.streamResponse(any(),
        imagePaths: any(named: 'imagePaths'),
        locale: any(named: 'locale')));
  });

  test('sendMessage vide ne déclenche aucun appel', () async {
    await provider.sendMessage('   ');
    expect(provider.messages, isEmpty);
    verifyNever(() => ai.streamResponse(any(),
        imagePaths: any(named: 'imagePaths'),
        locale: any(named: 'locale')));
  });

  test('clearHistory vide la liste et appelle le repository', () async {
    when(() => ai.streamResponse(any(),
            imagePaths: any(named: 'imagePaths'),
            locale: any(named: 'locale')))
        .thenAnswer((_) => Stream<AiStreamEvent>.fromIterable(const [
              AiDone('réponse'),
            ]));
    await provider.sendMessage('Salut');
    expect(provider.messages, isNotEmpty);

    await provider.clearHistory();
    expect(provider.messages, isEmpty);
    verify(() => history.clearHistory()).called(1);
  });

  test('TTS désactivée : pas de lecture audio après réponse', () async {
    when(() => settings.setTtsEnabled(any())).thenAnswer((_) async {});
    await provider.setTtsEnabled(false);

    when(() => ai.streamResponse(any(),
            imagePaths: any(named: 'imagePaths'),
            locale: any(named: 'locale')))
        .thenAnswer((_) => Stream<AiStreamEvent>.fromIterable(const [
              AiDone('réponse'),
            ]));

    await provider.sendMessage('Salut');
    verifyNever(() => tts.speak(any()));
  });
}
