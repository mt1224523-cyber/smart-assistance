import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

/// Événement émis par le stream de réponse.
sealed class AiStreamEvent {
  const AiStreamEvent();
}

class AiChunk extends AiStreamEvent {
  final String content;
  const AiChunk(this.content);
}

class AiDone extends AiStreamEvent {
  final String fullText;
  const AiDone(this.fullText);
}

class AiError extends AiStreamEvent {
  final String code;
  final String message;
  const AiError(this.code, this.message);
}

class AIService {
  final http.Client _client;
  final String _baseUrl;
  final String _appKey;
  String _lastError = '';

  AIService({
    http.Client? client,
    String? baseUrl,
    String? appKey,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConstants.proxyBaseUrl,
        _appKey = appKey ?? AppConstants.appApiKey;

  String get lastError => _lastError;

  /// Envoie la question au proxy en mode streaming et émet les chunks au fur
  /// et à mesure. Le dernier événement est toujours [AiDone] ou [AiError].
  Stream<AiStreamEvent> streamResponse(
    String userMessage, {
    List<String>? imagePaths,
    String? locale,
  }) async* {
    if (_baseUrl.isEmpty) {
      _lastError = 'missing_proxy_url';
      yield const AiError(
        'config_missing',
        "Configuration manquante : l'URL du serveur n'est pas définie.",
      );
      return;
    }

    final List<String> images = [];
    try {
      if (imagePaths != null) {
        for (final path in imagePaths) {
          final bytes = await File(path).readAsBytes();
          images.add(base64Encode(bytes));
        }
      }
    } catch (e) {
      _lastError = 'image_read_failed';
      yield const AiError('image_read_failed', "Impossible de lire l'image.");
      return;
    }

    final uri = Uri.parse('$_baseUrl/chat');
    final request = http.Request('POST', uri);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      if (_appKey.isNotEmpty) 'X-App-Key': _appKey,
    });
    request.body = jsonEncode({
      'message': userMessage,
      'images': images,
      'stream': true,
      if (locale != null && locale.isNotEmpty) 'locale': locale,
    });

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(request).timeout(
        const Duration(seconds: 120),
        onTimeout: () =>
            throw TimeoutException('Le serveur ne répond pas à temps'),
      );
    } on TimeoutException {
      _lastError = 'timeout';
      yield const AiError('timeout', 'Délai dépassé. Réessayez.');
      return;
    } on SocketException {
      _lastError = 'network_unavailable';
      yield const AiError('network', 'Vérifiez votre connexion internet.');
      return;
    } catch (e) {
      _lastError = _classifyError(e);
      yield AiError(_lastError, 'Erreur réseau.');
      return;
    }

    if (streamed.statusCode != 200) {
      final body = await streamed.stream.bytesToString();
      _lastError = 'http_${streamed.statusCode}';
      yield AiError(_lastError, _parseHttpError(streamed.statusCode, body));
      return;
    }

    final buffer = StringBuffer();
    final full = StringBuffer();

    await for (final chunk in streamed.stream.transform(utf8.decoder)) {
      buffer.write(chunk);
      while (true) {
        final raw = buffer.toString();
        final sepIndex = raw.indexOf('\n\n');
        if (sepIndex == -1) break;
        final event = raw.substring(0, sepIndex);
        buffer
          ..clear()
          ..write(raw.substring(sepIndex + 2));

        for (final line in event.split('\n')) {
          if (!line.startsWith('data:')) continue;
          final payload = line.substring(5).trim();
          if (payload == '[DONE]') {
            yield AiDone(full.toString());
            return;
          }
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            if (data.containsKey('error')) {
              _lastError = 'server_error';
              yield AiError('server_error', data['error'].toString());
              return;
            }
            final content = data['content'];
            if (content is String && content.isNotEmpty) {
              full.write(content);
              yield AiChunk(content);
            }
          } catch (_) {
            // Ligne SSE malformée : on ignore et on continue.
          }
        }
      }
    }

    yield AiDone(full.toString());
  }

  String _classifyError(Object error) {
    if (error is TimeoutException) return 'timeout';
    if (error is SocketException) return 'network_unavailable';
    if (error is FormatException) return 'invalid_response';
    return 'internal_error';
  }

  String _parseHttpError(int statusCode, String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final message =
          (data['error'] ?? data['detail'] ?? 'Erreur inconnue').toString();
      return 'Erreur $statusCode : $message';
    } catch (_) {
      if (statusCode == 401) return 'Application non autorisée.';
      if (statusCode == 429) return 'Trop de requêtes, attendez un instant.';
      return 'Erreur $statusCode';
    }
  }

  void dispose() {
    _client.close();
  }
}
