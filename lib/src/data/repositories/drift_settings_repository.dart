import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository({AppDatabase? database}) : _db = database ?? AppDatabase();

  final AppDatabase _db;

  static const _aiConfigKey = 'ai_provider_config';

  @override
  Future<AiProviderConfig?> getAiProviderConfig() async {
    final results = await (_db.select(_db.settingsEntries)
      ..where((t) => t.key.equals(_aiConfigKey)))
        .get();
    if (results.isEmpty) return null;
    final json = results.first.value;
    if (json.isEmpty) return null;
    return _parseConfig(json);
  }

  @override
  Future<void> saveAiProviderConfig(AiProviderConfig config) async {
    await _db.into(_db.settingsEntries).insertOnConflictUpdate(
      SettingsEntriesCompanion(
        key: Value(_aiConfigKey),
        value: Value(_encodeConfig(config)),
      ),
    );
  }

  AiProviderConfig _parseConfig(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return AiProviderConfig(
      id: map['id'] as String? ?? 'default',
      displayName: map['displayName'] as String? ?? '默认',
      baseUrl: map['baseUrl'] as String? ?? '',
      model: map['model'] as String? ?? '',
      apiKey: map['apiKey'] as String? ?? '',
    );
  }

  String _encodeConfig(AiProviderConfig config) {
    return jsonEncode({
      'id': config.id,
      'displayName': config.displayName,
      'baseUrl': config.baseUrl,
      'model': config.model,
      'apiKey': config.apiKey,
    });
  }
}
