import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistance/data/models/message.dart';

void main() {
  group('Message', () {
    test('toJson / fromJson round-trip', () {
      final original = Message(
        id: '42',
        content: 'salut',
        isUser: true,
        timestamp: DateTime.utc(2026, 6, 1, 12, 30),
        status: MessageStatus.received,
        imagePaths: const ['/tmp/a.jpg'],
      );

      final restored = Message.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.content, original.content);
      expect(restored.isUser, original.isUser);
      expect(restored.timestamp, original.timestamp);
      expect(restored.status, original.status);
      expect(restored.imagePaths, original.imagePaths);
    });

    test('copyWith modifie uniquement les champs fournis', () {
      final original = Message(
        id: '1',
        content: 'a',
        isUser: false,
        timestamp: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(
        content: 'ab',
        status: MessageStatus.error,
      );

      expect(updated.id, original.id);
      expect(updated.content, 'ab');
      expect(updated.status, MessageStatus.error);
      expect(updated.timestamp, original.timestamp);
    });

    test('fromJson tolère un statut inconnu', () {
      final json = {
        'id': '1',
        'content': 'x',
        'isUser': true,
        'timestamp': '2026-06-01T00:00:00.000Z',
        'status': 'status_inexistant',
      };
      final m = Message.fromJson(json);
      expect(m.status, MessageStatus.received);
    });
  });
}
