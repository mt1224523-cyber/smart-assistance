import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/locale/app_locale.dart';

/// Paramètres utilisateur persistés dans le stockage sécurisé.
class SettingsRepository {
  static const _ttsKey = 'settings_tts_enabled';
  static const _sttKey = 'settings_stt_enabled';
  static const _themeKey = 'settings_theme_mode';
  static const _localeKey = 'settings_locale';

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final FlutterSecureStorage _storage;

  SettingsRepository({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: _androidOptions,
              iOptions: _iosOptions,
            );

  Future<bool> getTtsEnabled() => _readBool(_ttsKey, defaultValue: true);

  Future<void> setTtsEnabled(bool enabled) => _writeBool(_ttsKey, enabled);

  Future<bool> getSttEnabled() => _readBool(_sttKey, defaultValue: true);

  Future<void> setSttEnabled(bool enabled) => _writeBool(_sttKey, enabled);

  Future<ThemeMode> getThemeMode() async {
    final raw = await _storage.read(key: _themeKey);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _storage.write(key: _themeKey, value: mode.name);
  }

  Future<AppLocale> getLocale() async {
    final raw = await _storage.read(key: _localeKey);
    return AppLocale.fromCode(raw);
  }

  Future<void> setLocale(AppLocale locale) async {
    await _storage.write(key: _localeKey, value: locale.code);
  }

  Future<void> clearSettings() async {
    await _storage.delete(key: _ttsKey);
    await _storage.delete(key: _sttKey);
    await _storage.delete(key: _themeKey);
    await _storage.delete(key: _localeKey);
  }

  Future<bool> _readBool(String key, {required bool defaultValue}) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return defaultValue;
    return raw == 'true';
  }

  Future<void> _writeBool(String key, bool value) async {
    await _storage.write(key: key, value: value ? 'true' : 'false');
  }
}
