import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/repositories/drift_settings_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/drift_question_repository.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart';
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
import 'package:smart_wrong_notebook/src/features/ocr/presentation/ocr_confirmation_screen.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/analysis_loading_screen.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/analysis_result_screen.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/exercise_practice_screen.dart';
import 'package:smart_wrong_notebook/src/features/review/presentation/review_history_screen.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/files/image_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  final settingsRepo = DriftSettingsRepository(db);
  final questionRepo = DriftQuestionRepository(db);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/notebook', builder: (_, __) => const NotebookScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/review', builder: (_, __) => const ReviewScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsScreen(),
              routes: [
                GoRoute(path: 'provider', builder: (_, __) => const ProviderConfigScreen()),
                GoRoute(path: 'subjects', builder: (_, __) => const SubjectManagementScreen()),
                GoRoute(path: 'prompts', builder: (_, __) => const PromptSettingsScreen()),
                GoRoute(path: 'data', builder: (_, __) => const DataManagementScreen()),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(path: '/capture/correction', builder: (context, state) => const QuestionCorrectionScreen()),
      GoRoute(path: '/capture/ocr-confirmation', builder: (context, state) => const OcrConfirmationScreen()),
      GoRoute(path: '/analysis/loading', builder: (context, state) => const AnalysisLoadingScreen()),
      GoRoute(path: '/analysis/result', builder: (context, state) => const AnalysisResultScreen()),
      GoRoute(path: '/exercise/practice', builder: (context, state) => const ExercisePracticeScreen()),
      GoRoute(path: '/notebook/question/:id', builder: (context, state) => const QuestionDetailScreen()),
      GoRoute(path: '/review/history', builder: (context, state) => const ReviewHistoryScreen()),
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
        aiAnalysisServiceProvider.overrideWithValue(AiAnalysisService.fake()),
        imageStorageServiceProvider.overrideWithValue(ImageStorageService()),
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          title: '智能错题本',
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: ref.watch(themeModeProvider),
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    ),
  );
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