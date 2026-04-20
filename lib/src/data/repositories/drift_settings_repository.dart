import 'package:drift/drift.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);
  final AppDatabase _db;

  @override
  Future<AiProviderConfig?> getAiProviderConfig() async {
    final id = await getString('ai_provider_id');
    final displayName = await getString('ai_provider_display_name');
    final baseUrl = await getString('ai_base_url');
    final apiKey = await getString('ai_api_key');
    final model = await getString('ai_model');
    if (id == null || displayName == null || baseUrl == null || apiKey == null || model == null) return null;
    return AiProviderConfig(
      id: id,
      displayName: displayName,
      baseUrl: baseUrl,
      apiKey: apiKey,
      model: model,
    );
  }

  @override
  Future<void> saveAiProviderConfig(AiProviderConfig config) async {
    await setString('ai_provider_id', config.id);
    await setString('ai_provider_display_name', config.displayName);
    await setString('ai_base_url', config.baseUrl);
    await setString('ai_api_key', config.apiKey);
    await setString('ai_model', config.model);
  }

  @override
  Future<String?> getString(String key) async {
    final row = await (_db.select(_db.settingsEntries)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> setString(String key, String value) async {
    await _db.into(_db.settingsEntries).insertOnConflictUpdate(
          SettingsEntriesCompanion(
            key: Value(key),
            value: Value(value),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }
}