import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_session.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/features/notebook/presentation/notebook_screen.dart';
import 'package:smart_wrong_notebook/src/features/ocr/presentation/question_split_confirmation_screen.dart';

GoRouter _router() {
  return GoRouter(
    initialLocation: '/capture/split-confirmation',
    routes: <RouteBase>[
      GoRoute(
        path: '/capture/split-confirmation',
        builder: (_, __) => const QuestionSplitConfirmationScreen(),
      ),
      GoRoute(
        path: '/notebook',
        builder: (_, __) => const NotebookScreen(),
      ),
      GoRoute(
        path: '/notebook/question/:id',
        builder: (_, state) => Scaffold(
          body: Text('question ${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/analysis/result',
        builder: (_, __) => const Scaffold(body: Text('analysis result')),
      ),
    ],
  );
}

QuestionRecord _sourceRecord() {
  return QuestionRecord.draft(
    id: 'q-batch',
    imagePath: '',
    subject: Subject.math,
    recognizedText: '原始整题',
  ).copyWith(
    analysisResult: const AnalysisResult(
      finalAnswer: '答案',
      steps: <String>['步骤1'],
      aiTags: <String>['方程'],
      knowledgePoints: <String>['代数'],
      mistakeReason: '审题不清',
      studyAdvice: '多复习',
    ),
    candidateAnalyses: <CandidateAnalysisSnapshot>[
      CandidateAnalysisSnapshot(
        candidateId: 'candidate-0',
        order: 1,
        questionText: r'第一题：已知 \(x+1=3\)，求 \(x\)',
        analysisResult: const AnalysisResult(
          finalAnswer: 'x=2',
          steps: <String>['移项'],
          aiTags: <String>['一次方程'],
          knowledgePoints: <String>['移项法则'],
          mistakeReason: '符号错误',
          studyAdvice: '注意变号',
          subject: Subject.math,
        ),
        savedExercises: <GeneratedExercise>[
          GeneratedExercise(
            id: 'e-1',
            questionId: 'q-batch-1',
            generationMode: ExerciseGenerationMode.practice,
            difficulty: '同级',
            question: '练习题1',
            answer: 'A',
            explanation: '解析1',
            createdAt: DateTime(2026),
          ),
        ],
        aiTags: <String>['一次方程'],
        aiKnowledgePoints: <String>['移项法则'],
      ),
      CandidateAnalysisSnapshot(
        candidateId: 'candidate-1',
        order: 2,
        questionText: '第二题：求 y=2x 的值',
        analysisResult: const AnalysisResult(
          finalAnswer: 'y=4',
          steps: <String>['代入'],
          aiTags: <String>['函数'],
          knowledgePoints: <String>['函数值'],
          mistakeReason: '代入错误',
          studyAdvice: '检查变量',
          subject: Subject.math,
        ),
        savedExercises: <GeneratedExercise>[
          GeneratedExercise(
            id: 'e-2',
            questionId: 'q-batch-2',
            generationMode: ExerciseGenerationMode.practice,
            difficulty: '同级',
            question: '练习题2',
            answer: 'B',
            explanation: '解析2',
            createdAt: DateTime(2026),
          ),
        ],
        aiTags: <String>['函数'],
        aiKnowledgePoints: <String>['函数值'],
      ),
    ],
  );
}

QuestionSplitSession _session({
  bool firstSelected = true,
  bool secondSelected = false,
  String firstText = r'第一题：已知 \(x+1=3\)，求 \(x\)',
  String secondText = '第二题：求 y=2x 的值',
}) {
  return QuestionSplitSession(
    source: _sourceRecord(),
    strategy: QuestionSplitStrategy.fallback,
    drafts: <QuestionSplitDraft>[
      QuestionSplitDraft(
        id: 'd-1',
        text: firstText,
        selected: firstSelected,
        originalOrder: 1,
      ),
      QuestionSplitDraft(
        id: 'd-2',
        text: secondText,
        selected: secondSelected,
        originalOrder: 2,
      ),
    ],
  );
}

QuestionSplitSession _partialSession() {
  return QuestionSplitSession(
    source: _sourceRecord(),
    strategy: QuestionSplitStrategy.numbered,
    failedCandidateCount: 1,
    drafts: <QuestionSplitDraft>[
      QuestionSplitDraft(
        id: 'd-1',
        text: r'第一题：已知 \(x+1=3\)，求 \(x\)',
        selected: true,
        originalOrder: 1,
      ),
    ],
  );
}

Future<void> _pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
  GoRouter router,
) async {
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

Future<void> _scrollToActions(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -900));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'partial result saves only successful questions after confirmation',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final container = ProviderContainer(
      overrides: [questionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.read(currentQuestionSplitSessionProvider.notifier).state =
        _partialSession();

    final router = _router();
    addTearDown(router.dispose);
    await _pumpScreen(tester, container, router);

    expect(find.text('可保存 1 题'), findsOneWidget);
    expect(find.text('1 题未解析成功'), findsOneWidget);
    await _scrollToActions(tester);
    await tester.tap(find.text('保存已勾选题目 (1)'));
    await tester.pumpAndSettle();
    expect(find.text('保存已解析题目'), findsOneWidget);
    expect(find.textContaining('另 1 道未解析成功的题不会保存'), findsOneWidget);

    await tester.tap(find.text('返回处理'));
    await tester.pumpAndSettle();
    expect(await repository.listAll(), isEmpty);

    await tester.tap(find.text('保存已勾选题目 (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续保存'));
    await tester.pumpAndSettle();
    final saved = await repository.listAll();
    expect(saved, hasLength(1));
    expect(saved.single.splitOrder, 1);
  });

  testWidgets('split confirmation screen saves selected questions',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final container = ProviderContainer(
      overrides: [questionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionSplitSessionProvider.notifier).state =
        _session();

    final router = _router();
    addTearDown(router.dispose);

    await _pumpScreen(tester, container, router);

    expect(find.text('逐题确认后保存'), findsOneWidget);
    expect(find.text('题目列表'), findsOneWidget);
    expect(find.text('当前题目内容'), findsOneWidget);

    await _scrollToActions(tester);
    await tester.tap(find.text('保存已勾选题目 (1)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('保存失败'), findsNothing);

    final saved = await repository.listAll();
    expect(saved.length, 1);
    expect(saved.first.correctedText, r'第一题：已知 \(x+1=3\)，求 \(x\)');
    expect(saved.first.correctedText, isNot(contains(r'\\(')));
    expect(saved.first.analysisResult?.finalAnswer, 'x=2');
    expect(saved.first.aiTags, <String>['一次方程']);
    expect(saved.first.aiKnowledgePoints, <String>['移项法则']);
    expect(
        saved.first.savedExercises
            .map((exercise) => exercise.question)
            .toList(),
        <String>['练习题1']);
    expect(container.read(currentQuestionProvider)?.id, 'q-batch-1');
    expect(container.read(currentQuestionSplitSessionProvider), isNull);
  });

  testWidgets('split confirmation screen can select all before saving',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final container = ProviderContainer(
      overrides: [questionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionSplitSessionProvider.notifier).state =
        _session(firstSelected: false, secondSelected: false);

    final router = _router();
    addTearDown(router.dispose);

    await _pumpScreen(tester, container, router);

    await tester.tap(find.text('全选'));
    await tester.pumpAndSettle();
    await _scrollToActions(tester);
    await tester.tap(find.text('保存已勾选题目 (2)'));
    await tester.pumpAndSettle();

    final saved = await repository.listAll();
    expect(saved.length, 2);
    expect(saved.map((record) => record.correctedText).toList(), <String>[
      r'第一题：已知 \(x+1=3\)，求 \(x\)',
      '第二题：求 y=2x 的值',
    ]);
    expect(container.read(currentQuestionProvider)?.id, 'q-batch-1');
  });

  testWidgets('split confirmation screen disables save when none selected',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final container = ProviderContainer(
      overrides: [questionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionSplitSessionProvider.notifier).state =
        _session(firstSelected: false, secondSelected: false);

    final router = _router();
    addTearDown(router.dispose);

    await _pumpScreen(tester, container, router);
    await _scrollToActions(tester);

    final button = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, '保存已勾选题目 (0)'));
    expect(button.onPressed, isNull);
    expect(find.text('请至少勾选一道题后再保存。'), findsOneWidget);
  });

  testWidgets('split confirmation screen shows editor for unselected draft',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(currentQuestionSplitSessionProvider.notifier).state =
        QuestionSplitSession(
      source: QuestionRecord.draft(
        id: 'q-empty',
        imagePath: '',
        subject: Subject.math,
        recognizedText: '原始整题',
      ),
      strategy: QuestionSplitStrategy.fallback,
      drafts: const <QuestionSplitDraft>[
        QuestionSplitDraft(
            id: 'd-1', text: '第一题', selected: false, originalOrder: 1),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: QuestionSplitConfirmationScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('题目列表'), findsOneWidget);
    expect(find.text('当前题目内容'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
