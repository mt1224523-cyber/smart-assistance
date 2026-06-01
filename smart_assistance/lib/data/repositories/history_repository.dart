import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/message.dart';

/// Persiste l'historique des messages dans le stockage sécurisé de la plateforme
/// (EncryptedSharedPreferences sur Android, Keychain sur iOS).
class HistoryRepository {
  static const _storageKey = 'history_v1';
  static const _maxMessages = 100;

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final FlutterSecureStorage _storage;
  List<Message>? _cache;

  HistoryRepository({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: _androidOptions,
              iOptions: _iosOptions,
            );

  Future<List<Message>> getHistory() async {
    final cached = _cache;
    if (cached != null) return List.unmodifiable(cached);

    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = [];
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _cache = [];
        return const [];
      }
      final messages = decoded
          .whereType<Map<String, dynamic>>()
          .map(Message.fromJson)
          .toList();
      _cache = messages;
      return List.unmodifiable(messages);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HistoryRepository: corrupt store, resetting ($e)');
      }
      await _storage.delete(key: _storageKey);
      _cache = [];
      return const [];
    }
  }

  Future<void> addMessage(Message message) async {
    final messages = await _mutable();
    messages.add(message);
    while (messages.length > _maxMessages) {
      messages.removeAt(0);
    }
    await _persist(messages);
  }

  Future<void> addMessages(List<Message> newMessages) async {
    final messages = await _mutable();
    messages.addAll(newMessages);
    while (messages.length > _maxMessages) {
      messages.removeAt(0);
    }
    await _persist(messages);
  }

  Future<void> clearHistory() async {
    _cache = [];
    await _storage.delete(key: _storageKey);
  }

  Future<void> deleteMessage(String messageId) async {
    final messages = await _mutable();
    messages.removeWhere((m) => m.id == messageId);
    await _persist(messages);
  }

  Future<List<Message>> _mutable() async {
    if (_cache == null) {
      await getHistory();
    }
    return _cache!;
  }

  Future<void> _persist(List<Message> messages) async {
    _cache = messages;
    final encoded = jsonEncode(messages.map((m) => m.toJson()).toList());
    await _storage.write(key: _storageKey, value: encoded);
  }
}
