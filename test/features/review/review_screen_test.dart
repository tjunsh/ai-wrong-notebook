import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/features/review/presentation/review_screen.dart';

final _inMemRepo = InMemoryQuestionRepository();
final _repoOverride = questionRepositoryProvider.overrideWithValue(_inMemRepo);

void main() {
  group('ReviewScreen', () {
    testWidgets('shows empty state when no questions due', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [_repoOverride],
          child: const MaterialApp(home: ReviewScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('今日待复习'), findsOneWidget);
      expect(find.text('暂无待复习错题'), findsOneWidget);
    });

    testWidgets('shows summary card with correct counts', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [_repoOverride],
          child: const MaterialApp(home: ReviewScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('整体进度'), findsOneWidget);
      expect(find.text('共 0 题'), findsOneWidget);
    });

    testWidgets('shows history link', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [_repoOverride],
          child: const MaterialApp(home: ReviewScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('复习记录'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chevron_right), findsWidgets);
    });
  });
}
