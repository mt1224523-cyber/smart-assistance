import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persiste le consentement de l'utilisateur à la politique de confidentialité.
class ConsentRepository {
  static const _consentKey = 'privacy_consent_accepted_v1';

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final FlutterSecureStorage _storage;

  ConsentRepository({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: _androidOptions,
              iOptions: _iosOptions,
            );

  Future<bool> hasAccepted() async {
    final raw = await _storage.read(key: _consentKey);
    return raw == 'true';
  }

  Future<void> accept() => _storage.write(key: _consentKey, value: 'true');

  Future<void> revoke() => _storage.delete(key: _consentKey);
}
