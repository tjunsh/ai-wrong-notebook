import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wrong_notebook/src/app/app.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/app/router.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/files/image_storage_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/shared_prefs_settings_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/shared_prefs_question_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use SharedPreferences for reliable storage across all Android versions
  final settingsRepo = SharedPrefsSettingsRepository();
  final questionRepo = SharedPrefsQuestionRepository();
  final router = buildRouter(settingsRepo);

  runApp(ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(settingsRepo),
      questionRepositoryProvider.overrideWithValue(questionRepo),
      aiAnalysisServiceProvider.overrideWithValue(AiAnalysisService.fake()),
      imageStorageServiceProvider.overrideWithValue(ImageStorageService()),
    ],
    child: SmartWrongNotebookApp(routerConfig: router),
  ));
}
