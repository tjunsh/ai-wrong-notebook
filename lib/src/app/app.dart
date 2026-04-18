import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/app/router.dart';
import 'package:smart_wrong_notebook/src/app/theme/app_theme.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/drift_settings_repository.dart';
import 'package:smart_wrong_notebook/src/data/files/image_storage_service.dart';

class SmartWrongNotebookApp extends StatelessWidget {
  const SmartWrongNotebookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = buildRouter();
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(DriftSettingsRepository()),
        aiAnalysisServiceProvider.overrideWithValue(AiAnalysisService.fake()),
        imageStorageServiceProvider.overrideWithValue(ImageStorageService()),
      ],
      child: MaterialApp.router(
        title: 'Smart Wrong Notebook',
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        routerConfig: router,
      ),
    );
  }
}
