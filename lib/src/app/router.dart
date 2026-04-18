import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/core/constants/app_strings.dart';
import 'package:smart_wrong_notebook/src/features/home/presentation/home_screen.dart';
import 'package:smart_wrong_notebook/src/features/notebook/presentation/notebook_screen.dart';
import 'package:smart_wrong_notebook/src/features/notebook/presentation/question_detail_screen.dart';
import 'package:smart_wrong_notebook/src/features/review/presentation/review_screen.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/settings_screen.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/provider_config_screen.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/subject_management_screen.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/prompt_settings_screen.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/data_management_screen.dart';
import 'package:smart_wrong_notebook/src/features/capture/presentation/question_correction_screen.dart';
import 'package:smart_wrong_notebook/src/features/ocr/presentation/ocr_confirmation_screen.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/analysis_loading_screen.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/analysis_result_screen.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(path: '/notebook', builder: (_, __) => const NotebookScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(path: '/review', builder: (_, __) => const ReviewScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsScreen(),
                routes: <RouteBase>[
                  GoRoute(path: 'provider', builder: (_, __) => const ProviderConfigScreen(config: null)),
                  GoRoute(path: 'subjects', builder: (_, __) => const SubjectManagementScreen()),
                  GoRoute(path: 'prompts', builder: (_, __) => const PromptSettingsScreen()),
                  GoRoute(path: 'data', builder: (_, __) => const DataManagementScreen()),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/capture/correction', builder: (_, __) => const QuestionCorrectionScreen()),
      GoRoute(path: '/capture/ocr-confirmation', builder: (_, __) => const OcrConfirmationScreen(initialText: '')),
      GoRoute(path: '/analysis/loading', builder: (_, __) => const AnalysisLoadingScreen()),
      GoRoute(
        path: '/analysis/result',
        builder: (_, state) => AnalysisResultScreen(record: state.extra as QuestionRecord),
      ),
      GoRoute(
        path: '/notebook/question/:id',
        builder: (_, state) => QuestionDetailScreen(record: state.extra as QuestionRecord),
      ),
    ],
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
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: AppStrings.homeTab),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: AppStrings.notebookTab),
          NavigationDestination(icon: Icon(Icons.refresh_outlined), label: AppStrings.reviewTab),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: AppStrings.settingsTab),
        ],
      ),
    );
  }
}
