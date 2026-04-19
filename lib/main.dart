import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wrong_notebook/src/app/app.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/app/router.dart';
import 'package:smart_wrong_notebook/src/data/repositories/drift_settings_repository.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/files/image_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) debugPrint('FlutterError: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) debugPrint('PlatformError: $error\n$stack');
    return true;
  };

  try {
    final settingsRepo = DriftSettingsRepository();
    final router = buildRouter(settingsRepo);

    runApp(ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(AiAnalysisService.fake()),
        imageStorageServiceProvider.overrideWithValue(ImageStorageService()),
      ],
      child: SmartWrongNotebookApp(routerConfig: router),
    ));
  } catch (e, stack) {
    if (kDebugMode) debugPrint('InitializationError: $e\n$stack');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('初始化失败: $e'),
        ),
      ),
    ));
  }
}
