import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/app/app.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/features/capture/presentation/capture_entry_sheet.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/settings_screen.dart';
import 'package:smart_wrong_notebook/src/features/notebook/presentation/notebook_screen.dart';
import 'package:smart_wrong_notebook/src/features/review/presentation/review_screen.dart';
import 'package:smart_wrong_notebook/src/features/home/presentation/home_screen.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';

final _inMemRepo = InMemoryQuestionRepository();

final _repoOverride = questionRepositoryProvider.overrideWithValue(_inMemRepo);

void main() {
  group('MVP smoke tests', () {
    testWidgets('app boots to shell with Home tab label', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [_repoOverride],
        child: const SmartWrongNotebookApp(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('首页'), findsOneWidget);
      expect(find.text('错题本'), findsOneWidget);
      expect(find.text('复习'), findsOneWidget);
      expect(find.text('我的'), findsOneWidget);
    });

    testWidgets('app boots to home screen with default content', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [_repoOverride],
        child: const SmartWrongNotebookApp(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('开始拍错题'), findsOneWidget);
      expect(find.text('最近新增'), findsOneWidget);
    });

    testWidgets('user can tap camera button and see capture sheet', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [_repoOverride],
        child: const MaterialApp(home: HomeScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('拍照录题'));
      await tester.pumpAndSettle();

      expect(find.text('拍照'), findsOneWidget);
      expect(find.text('相册'), findsOneWidget);
    });

    testWidgets('settings screen shows all required entries', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [_repoOverride],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ));
      await tester.pumpAndSettle();

      expect(find.text('AI 服务商配置'), findsOneWidget);
      expect(find.text('科目管理'), findsOneWidget);
      expect(find.text('提示词设置'), findsOneWidget);
      expect(find.text('导出当前题库'), findsOneWidget);
    });

    testWidgets('notebook screen shows filter icons', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [_repoOverride],
        child: const MaterialApp(home: Scaffold(body: NotebookScreen())),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('review screen shows today review section', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [_repoOverride],
        child: const MaterialApp(home: ReviewScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('今日待复习'), findsOneWidget);
    });

    testWidgets('capture entry sheet has camera and gallery options', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [_repoOverride],
        child: MaterialApp(
          home: Scaffold(body: CaptureEntrySheet()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('拍照'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      expect(find.text('相册'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });
  });
}
