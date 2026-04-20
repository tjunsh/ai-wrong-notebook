import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';

class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<AiProviderConfig?> getAiProviderConfig() async {
    final json = await _getString('ai_provider_config');
    if (json == null || json.isEmpty) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return AiProviderConfig(
        id: map['id'] as String? ?? 'default',
        displayName: map['displayName'] as String? ?? '默认',
        baseUrl: map['baseUrl'] as String? ?? '',
        model: map['model'] as String? ?? '',
        apiKey: map['apiKey'] as String? ?? '',
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveAiProviderConfig(AiProviderConfig config) async {
    await _setString('ai_provider_config', jsonEncode({
      'id': config.id,
      'displayName': config.displayName,
      'baseUrl': config.baseUrl,
      'model': config.model,
      'apiKey': config.apiKey,
    }));
  }

  @override
  Future<String?> getString(String key) async {
    return _getString('setting_$key');
  }

  @override
  Future<void> setString(String key, String value) async {
    await _setString('setting_$key', value);
  }

  Future<String?> _getString(String key) async {
    return (await _preferences).getString(key);
  }

  Future<void> _setString(String key, String value) async {
    await (await _preferences).setString(key, value);
  }
}
