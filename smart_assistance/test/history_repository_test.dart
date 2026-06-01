import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_assistance/data/models/message.dart';
import 'package:smart_assistance/data/repositories/history_repository.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

Message _msg(String id, {bool isUser = true, String content = 'hello'}) =>
    Message(
      id: id,
      content: content,
      isUser: isUser,
      timestamp: DateTime(2026, 1, 1),
      status: MessageStatus.received,
    );

void main() {
  late _MockStorage storage;
  late HistoryRepository repo;
  late Map<String, String> backing;

  setUp(() {
    storage = _MockStorage();
    backing = {};

    when(() => storage.read(key: any(named: 'key'))).thenAnswer(
      (invocation) async => backing[invocation.namedArguments[#key] as String],
    );
    when(() => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((invocation) async {
      backing[invocation.namedArguments[#key] as String] =
          invocation.namedArguments[#value] as String;
    });
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer(
      (invocation) async {
        backing.remove(invocation.namedArguments[#key]);
      },
    );

    repo = HistoryRepository(storage: storage);
  });

  test('getHistory retourne vide quand le stockage est vide', () async {
    final history = await repo.getHistory();
    expect(history, isEmpty);
  });

  test('addMessage persiste et getHistory relit', () async {
    await repo.addMessage(_msg('a'));
    await repo.addMessage(_msg('b'));

    // Nouvelle instance pour vérifier la persistance.
    final fresh = HistoryRepository(storage: storage);
    final history = await fresh.getHistory();
    expect(history.map((m) => m.id), ['a', 'b']);
  });

  test('addMessage applique la limite de 100', () async {
    for (var i = 0; i < 110; i++) {
      await repo.addMessage(_msg('m$i'));
    }
    final history = await repo.getHistory();
    expect(history.length, 100);
    // Les 10 plus anciens doivent avoir été retirés.
    expect(history.first.id, 'm10');
    expect(history.last.id, 'm109');
  });

  test('deleteMessage retire le message ciblé', () async {
    await repo.addMessage(_msg('a'));
    await repo.addMessage(_msg('b'));
    await repo.deleteMessage('a');

    final history = await repo.getHistory();
    expect(history.map((m) => m.id), ['b']);
  });

  test('clearHistory vide tout', () async {
    await repo.addMessage(_msg('a'));
    await repo.clearHistory();
    final history = await repo.getHistory();
    expect(history, isEmpty);
  });

  test('JSON corrompu déclenche un reset propre', () async {
    backing['history_v1'] = 'pas du json valide';
    final history = await repo.getHistory();
    expect(history, isEmpty);
    // Le repository doit avoir supprimé l'entrée corrompue.
    expect(backing.containsKey('history_v1'), isFalse);
  });

  test('encodage JSON contient bien les champs attendus', () async {
    await repo.addMessage(_msg('a', content: 'salut'));
    final raw = backing['history_v1'];
    expect(raw, isNotNull);
    final decoded = jsonDecode(raw!) as List;
    expect(decoded, hasLength(1));
    expect(decoded.first['id'], 'a');
    expect(decoded.first['content'], 'salut');
  });
}
