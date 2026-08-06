import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/repositories/drift_settings_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/drift_question_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/drift_ai_conversation_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/drift_analysis_job_repository.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/services/app_analysis_job_runner.dart';
import 'package:smart_wrong_notebook/src/data/services/ai_learning_task_coordinator.dart';
import 'package:smart_wrong_notebook/src/data/services/question_analysis_coordinator.dart';
import 'package:smart_wrong_notebook/src/domain/services/analysis_job_queue_executor.dart';
import 'package:smart_wrong_notebook/src/app/theme/app_theme.dart';
import 'package:smart_wrong_notebook/src/features/home/presentation/home_screen.dart';
import 'package:smart_wrong_notebook/src/features/notebook/presentation/notebook_screen.dart';
import 'package:smart_wrong_notebook/src/features/notebook/presentation/question_detail_screen.dart';
import 'package:smart_wrong_notebook/src/features/review/presentation/review_screen.dart';
import 'package:smart_wrong_notebook/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/settings_screen.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/provider_config_screen.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/subject_management_screen.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/prompt_settings_screen.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/data_management_screen.dart';
import 'package:smart_wrong_notebook/src/features/capture/presentation/question_correction_screen.dart';
import 'package:smart_wrong_notebook/src/features/capture/presentation/image_crop_screen.dart';
import 'package:smart_wrong_notebook/src/features/ocr/presentation/question_save_confirmation_screen.dart';
import 'package:smart_wrong_notebook/src/features/ocr/presentation/question_split_confirmation_screen.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/analysis_loading_screen.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/analysis_result_screen.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/question_text_correction_screen.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/exercise_practice_screen.dart';
import 'package:smart_wrong_notebook/src/features/review/presentation/review_history_screen.dart';
import 'package:smart_wrong_notebook/src/data/files/image_storage_service.dart';
import 'package:smart_wrong_notebook/src/shared/widgets/katex_math_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KatexMathView.preload();

  final db = AppDatabase();
  final settingsRepo = DriftSettingsRepository(db);
  final questionRepo = DriftQuestionRepository(db);
  final aiConversationRepo = DriftAiConversationRepository(db);
  final aiService = AiAnalysisService(settingsRepository: settingsRepo);
  final analysisJobRepo = DriftAnalysisJobRepository(db);
  final analysisJobExecutor = AnalysisJobQueueExecutor(
    repository: analysisJobRepo,
    runner: AppAnalysisJobRunner(
      aiService,
      questionRepository: questionRepo,
      analysisJobRepository: analysisJobRepo,
    ),
  );
  final questionAnalysisCoordinator = QueuedQuestionAnalysisCoordinator(
    service: aiService,
    settingsRepository: settingsRepo,
    repository: analysisJobRepo,
    executor: analysisJobExecutor,
  );
  final aiLearningTaskCoordinator = QueuedAiLearningTaskCoordinator(
    settingsRepository: settingsRepo,
    repository: analysisJobRepo,
    executor: analysisJobExecutor,
    questionRepository: questionRepo,
  );

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state,
            StatefulNavigationShell navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, __) => const HomeScreen())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/notebook', builder: (_, __) => const NotebookScreen())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/review', builder: (_, __) => const ReviewScreen())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsScreen(),
              routes: [
                GoRoute(
                    path: 'provider',
                    builder: (_, __) => const ProviderConfigScreen()),
                GoRoute(
                    path: 'subjects',
                    builder: (_, __) => const SubjectManagementScreen()),
                GoRoute(
                    path: 'prompts',
                    builder: (_, __) => const PromptSettingsScreen()),
                GoRoute(
                    path: 'data',
                    builder: (_, __) => const DataManagementScreen()),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(
          path: '/capture/crop',
          builder: (context, state) => const ImageCropScreen()),
      GoRoute(
          path: '/capture/correction',
          builder: (context, state) => const QuestionCorrectionScreen()),
      GoRoute(
          path: '/capture/save-confirmation',
          builder: (context, state) => const QuestionSaveConfirmationScreen()),
      GoRoute(
          path: '/capture/split-confirmation',
          builder: (context, state) => const QuestionSplitConfirmationScreen()),
      GoRoute(
          path: '/analysis/loading',
          builder: (context, state) => const AnalysisLoadingScreen()),
      GoRoute(
          path: '/analysis/result',
          builder: (context, state) => const AnalysisResultScreen()),
      GoRoute(
        path: '/analysis/text-correction',
        builder: (context, state) => const QuestionTextCorrectionScreen(),
      ),
      GoRoute(
          path: '/exercise/practice',
          builder: (context, state) => const ExercisePracticeScreen()),
      GoRoute(
          path: '/notebook/question/:id',
          builder: (context, state) => const QuestionDetailScreen()),
      GoRoute(
          path: '/review/history',
          builder: (context, state) => const ReviewHistoryScreen()),
    ],
  );

  // Defer onboarding check to avoid blocking startup
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      final onboardingDone = await settingsRepo.getString('onboarding_done');
      if (onboardingDone == null) {
        router.go('/onboarding');
      }
    } catch (_) {}
  });

  runApp(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        questionRepositoryProvider.overrideWithValue(questionRepo),
        aiConversationRepositoryProvider.overrideWithValue(aiConversationRepo),
        analysisJobRepositoryProvider.overrideWithValue(analysisJobRepo),
        aiAnalysisServiceProvider.overrideWithValue(aiService),
        questionAnalysisCoordinatorProvider
            .overrideWithValue(questionAnalysisCoordinator),
        aiLearningTaskCoordinatorProvider
            .overrideWithValue(aiLearningTaskCoordinator),
        imageStorageServiceProvider.overrideWithValue(ImageStorageService()),
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          title: 'AI错题本',
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: ref.watch(themeModeProvider),
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    ),
  );

  unawaited(analysisJobExecutor.initialize());
}

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) => navigationShell.goBranch(index),
        destinations: const [
          NavigationDestination(
            icon: Icon(CupertinoIcons.house),
            selectedIcon: Icon(CupertinoIcons.house_fill),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.book),
            selectedIcon: Icon(CupertinoIcons.book_fill),
            label: '错题本',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.arrow_2_circlepath),
            selectedIcon: Icon(CupertinoIcons.arrow_2_circlepath),
            label: '复习',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.gear),
            selectedIcon: Icon(CupertinoIcons.gear_solid),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
