import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';

abstract class SettingsRepository {
  Future<AiProviderConfig?> getAiProviderConfig();
  Future<void> saveAiProviderConfig(AiProviderConfig config);
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
}

class InMemorySettingsRepository implements SettingsRepository {
  AiProviderConfig? _config;
  final Map<String, String> _strings = {};

  InMemorySettingsRepository() {
    _config = AiProviderConfig(
      id: 'test',
      displayName: 'Test',
      baseUrl: 'https://api.test.com',
      model: 'test-model',
      apiKey: 'test-key',
    );
  }

  @override
  Future<AiProviderConfig?> getAiProviderConfig() async => _config;

  @override
  Future<void> saveAiProviderConfig(AiProviderConfig config) async {
    _config = config;
  }

  @override
  Future<String?> getString(String key) async => _strings[key];

  @override
  Future<void> setString(String key, String value) async {
    _strings[key] = value;
  }
}
