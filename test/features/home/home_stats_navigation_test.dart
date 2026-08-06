import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/features/home/presentation/home_screen.dart';

QuestionRecord _question({
  required String id,
  required DateTime createdAt,
  required MasteryLevel masteryLevel,
}) {
  final draft = QuestionRecord.draft(
    id: id,
    imagePath: '/tmp/$id.jpg',
    subject: Subject.math,
    recognizedText: '题目 $id',
  ).copyWith(
    contentStatus: ContentStatus.ready,
    masteryLevel: masteryLevel,
  );
  return QuestionRecord.fromJson(<String, dynamic>{
    ...draft.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': createdAt.toIso8601String(),
  });
}

void main() {
  testWidgets('home statistics navigate with matching notebook filters',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final container = ProviderContainer(overrides: <Override>[
      questionRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: HomeScreen()),
        ),
        GoRoute(
          path: '/notebook',
          builder: (_, __) => const Scaffold(body: Text('错题本目标页')),
        ),
        GoRoute(
          path: '/review',
          builder: (_, __) => const Scaffold(body: Text('复习目标页')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    Future<void> returnHome() async {
      router.go('/');
      await tester.pumpAndSettle();
    }

    await tester.ensureVisible(find.text('题库总量'));
    await tester.tap(find.text('题库总量'));
    await tester.pumpAndSettle();
    expect(find.text('错题本目标页'), findsOneWidget);
    expect(container.read(selectedMasteryFilterProvider), isNull);
    expect(container.read(selectedCreatedTodayFilterProvider), isFalse);

    await returnHome();
    await tester.ensureVisible(find.text('今日新增'));
    await tester.tap(find.text('今日新增'));
    await tester.pumpAndSettle();
    expect(find.text('错题本目标页'), findsOneWidget);
    expect(container.read(selectedCreatedTodayFilterProvider), isTrue);

    await returnHome();
    await tester.ensureVisible(find.text('已掌握'));
    await tester.tap(find.text('已掌握'));
    await tester.pumpAndSettle();
    expect(find.text('错题本目标页'), findsOneWidget);
    expect(
        container.read(selectedMasteryFilterProvider), MasteryLevel.mastered);
    expect(container.read(selectedCreatedTodayFilterProvider), isFalse);

    await returnHome();
    await tester.ensureVisible(find.text('待复习'));
    await tester.tap(find.text('待复习'));
    await tester.pumpAndSettle();
    expect(find.text('复习目标页'), findsOneWidget);
  });

  test('today and mastery filters select the expected questions', () async {
    final repository = InMemoryQuestionRepository();
    final now = DateTime.now();
    await repository.saveDraft(_question(
      id: 'today-mastered',
      createdAt: now,
      masteryLevel: MasteryLevel.mastered,
    ));
    await repository.saveDraft(_question(
      id: 'older-reviewing',
      createdAt: now.subtract(const Duration(days: 2)),
      masteryLevel: MasteryLevel.reviewing,
    ));
    final container = ProviderContainer(overrides: <Override>[
      questionRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);

    container.read(selectedCreatedTodayFilterProvider.notifier).state = true;
    final todayQuestions =
        await container.read(filteredQuestionListProvider.future);
    expect(todayQuestions.map((question) => question.id),
        <String>['today-mastered']);

    container.read(selectedCreatedTodayFilterProvider.notifier).state = false;
    container.read(selectedMasteryFilterProvider.notifier).state =
        MasteryLevel.mastered;
    final masteredQuestions =
        await container.refresh(filteredQuestionListProvider.future);
    expect(masteredQuestions.map((question) => question.id),
        <String>['today-mastered']);
  });
}
