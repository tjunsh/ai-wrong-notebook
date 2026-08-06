import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart'
    hide AnalysisJob, AiConversationMessage, GeneratedExercise, QuestionRecord;
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/drift_analysis_job_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_conversation_message.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/domain/repositories/ai_conversation_repository.dart';
import 'package:smart_wrong_notebook/src/domain/services/ai_route_resolver.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/exercise_practice_screen.dart';
import 'package:smart_wrong_notebook/src/features/notebook/presentation/notebook_screen.dart';
import 'package:smart_wrong_notebook/src/features/notebook/presentation/question_detail_screen.dart';

class _ExerciseGeneratingAiService extends AiAnalysisService {
  _ExerciseGeneratingAiService({
    this.overrideExercises,
  }) : super(settingsRepository: InMemorySettingsRepository());

  final List<GeneratedExercise>? overrideExercises;
  int generateCallCount = 0;
  int followUpCallCount = 0;
  String? lastFollowUpQuestion;

  @override
  Future<List<GeneratedExercise>> generateExercisesForQuestion(
    QuestionRecord question,
  ) async {
    generateCallCount++;
    if (overrideExercises != null) {
      return overrideExercises!;
    }
    final now = DateTime(2026);
    return <GeneratedExercise>[
      GeneratedExercise(
        id: '${question.id}-round-1-exercise-1',
        questionId: question.id,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '简单',
        question: '已知 x+2=5，求 x',
        options: const <String>['A. 1', 'B. 2', 'C. 3', 'D. 4'],
        answer: 'C',
        explanation: '两边同时减 2，得到 x=3。',
        createdAt: now,
        order: 0,
      ),
      GeneratedExercise(
        id: '${question.id}-round-1-exercise-2',
        questionId: question.id,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '同级',
        question: '已知 y+4=9，求 y',
        options: const <String>['A. 3', 'B. 4', 'C. 5', 'D. 6'],
        answer: 'C',
        explanation: '两边同时减 4，得到 y=5。',
        createdAt: now,
        order: 1,
      ),
      GeneratedExercise(
        id: '${question.id}-round-1-exercise-3',
        questionId: question.id,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '提高',
        question: '已知 2z+1=7，求 z',
        options: const <String>['A. 2', 'B. 3', 'C. 4', 'D. 5'],
        answer: 'B',
        explanation: '先移项得 2z=6，再除以 2 得 z=3。',
        createdAt: now,
        order: 2,
      ),
    ];
  }

  @override
  Future<String> answerQuestionFollowUp({
    required QuestionRecord question,
    required String userQuestion,
    List<AiFollowUpMessage> history = const <AiFollowUpMessage>[],
  }) async {
    followUpCallCount++;
    lastFollowUpQuestion = userQuestion;
    return r'''因为等式两边同时减去同一个数，等式仍然成立，所以可以先移项。

移项的目的，是把含有 \(x\) 的部分单独留下。

\[
x^2+1=5
\]

两边同时减去 \(1\)，得到：

\[
x^2=4
\]

所以 \(x=2\) 或 \(x=-2\)。''';
  }
}

QuestionRecord _buildSavedSplitQuestion({
  String id = 'q-batch-1',
  String text = '第一题：已知 x+1=3，求 x',
  int splitOrder = 1,
  List<GeneratedExercise>? savedExercises,
}) {
  final now = DateTime(2026);
  return QuestionRecord(
    id: id,
    imagePath: '/tmp/q-batch.jpg',
    subject: Subject.math,
    extractedQuestionText: text,
    normalizedQuestionText: text,
    contentFormat: QuestionContentFormat.plain,
    tags: const [],
    createdAt: now,
    updatedAt: now,
    lastReviewedAt: null,
    reviewCount: 0,
    isFavorite: false,
    contentStatus: ContentStatus.ready,
    masteryLevel: MasteryLevel.newQuestion,
    analysisResult: const AnalysisResult(
      finalAnswer: 'x=2',
      steps: <String>['移项'],
      aiTags: <String>['一次方程'],
      knowledgePoints: <String>['移项法则'],
      mistakeReason: '符号错误',
      studyAdvice: '注意变号',
      subject: Subject.math,
    ),
    savedExercises: savedExercises ??
        <GeneratedExercise>[
          GeneratedExercise(
            id: 'e-1',
            questionId: id,
            generationMode: ExerciseGenerationMode.practice,
            difficulty: '同级',
            question: '练习题1',
            answer: 'A',
            explanation: '解析1',
            createdAt: now,
            order: 0,
          ),
        ],
    aiTags: const <String>['一次方程'],
    aiKnowledgePoints: const <String>['移项法则'],
    customTags: const <String>['课堂'],
    parentQuestionId: 'q-batch-root',
    rootQuestionId: 'q-batch-root',
    splitOrder: splitOrder,
  );
}

void main() {
  testWidgets('notebook screen shows saved split question tags and text',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final question = _buildSavedSplitQuestion();
    await repository.saveDraft(question);

    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: Scaffold(body: NotebookScreen())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('第一题：已知 x+1=3，求 x'), findsOneWidget);
    expect(find.text('来自同一拍照批次 · 第 1 题'), findsOneWidget);
    expect(find.text('一次方程'), findsOneWidget);
    expect(find.text('课堂'), findsOneWidget);
  });

  testWidgets(
      'saved split question navigates from notebook to detail to practice',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final question = _buildSavedSplitQuestion();
    await repository.saveDraft(question);

    final container = ProviderContainer(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/notebook',
      routes: <GoRoute>[
        GoRoute(
          path: '/notebook',
          builder: (_, __) => const NotebookScreen(),
        ),
        GoRoute(
          path: '/notebook/question/:id',
          builder: (_, state) {
            final current = container.read(currentQuestionProvider);
            if (current?.id != state.pathParameters['id']) {
              container.read(currentQuestionProvider.notifier).state = question;
            }
            return const QuestionDetailScreen();
          },
        ),
        GoRoute(
          path: '/exercise/practice',
          builder: (_, __) => const ExercisePracticeScreen(),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    expect(find.text('第一题：已知 x+1=3，求 x'), findsOneWidget);
    await tester.tap(find.text('第一题：已知 x+1=3，求 x'));
    await tester.pumpAndSettle();

    expect(find.text('错题详情'), findsOneWidget);
    expect(find.text('拍照批次 · 第 1 题'), findsOneWidget);
    expect(find.text('一次方程'), findsOneWidget);
    expect(container.read(currentQuestionProvider)?.id, 'q-batch-1');

    await tester.scrollUntilVisible(
      find.text('继续练习'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续练习'));
    await tester.pumpAndSettle();

    expect(find.text('举一反三 1/1'), findsOneWidget);
    expect(find.text('练习题1'), findsOneWidget);
  });

  testWidgets(
      'practice completion updates detail answered count for saved split question',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final question = _buildSavedSplitQuestion().copyWith(
      savedExercises: <GeneratedExercise>[
        GeneratedExercise(
          id: 'e-1',
          questionId: 'q-batch-1',
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '同级',
          question: '练习题1',
          options: const <String>['A. 2', 'B. 3'],
          answer: 'A',
          explanation: '解析1',
          createdAt: DateTime(2026),
          order: 0,
        ),
      ],
    );
    await repository.saveDraft(question);

    final container = ProviderContainer(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(repository),
        settingsRepositoryProvider
            .overrideWithValue(InMemorySettingsRepository()),
        aiAnalysisServiceProvider.overrideWithValue(AiAnalysisService.fake()),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/notebook',
      routes: <GoRoute>[
        GoRoute(
          path: '/notebook',
          builder: (_, __) => const NotebookScreen(),
        ),
        GoRoute(
          path: '/notebook/question/:id',
          builder: (_, state) {
            final current = container.read(currentQuestionProvider);
            if (current?.id != state.pathParameters['id']) {
              container.read(currentQuestionProvider.notifier).state = question;
            }
            return const QuestionDetailScreen();
          },
        ),
        GoRoute(
          path: '/exercise/practice',
          builder: (_, __) => const ExercisePracticeScreen(),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('第一题：已知 x+1=3，求 x'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('0/1 已答'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('0/1 已答'), findsOneWidget);

    await tester.tap(find.text('继续练习'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(find.text('提交答案'), findsOneWidget);
    await tester.tap(find.text('提交答案'));
    await tester.pumpAndSettle();
    expect(find.text('回答正确'), findsOneWidget);
    expect(find.text('完成练习'), findsOneWidget);
    await tester.tap(find.text('完成练习'));
    await tester.pumpAndSettle();

    final updated = (await repository.getById('q-batch-1'))!;
    container.read(currentQuestionProvider.notifier).state = updated;
    container.read(currentPracticeContextProvider.notifier).state = null;

    router.go('/notebook/question/q-batch-1');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('1/1 已答'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('1/1 已答'), findsOneWidget);
    expect(
        container.read(currentQuestionProvider)?.savedExercises.first.isCorrect,
        isTrue);

    final saved = await repository.getById('q-batch-1');
    expect(saved?.savedExercises.first.isCorrect, isTrue);
  });
  testWidgets(
      'question detail screen shows candidate-level analysis and exercise entry',
      (tester) async {
    final question = _buildSavedSplitQuestion();
    final container = ProviderContainer(
      overrides: <Override>[
        currentQuestionProvider.overrideWith((ref) => question),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/notebook/question/${question.id}',
      routes: <GoRoute>[
        GoRoute(
          path: '/notebook',
          builder: (_, __) => const Scaffold(body: Text('NOTEBOOK')),
        ),
        GoRoute(
          path: '/notebook/question/:id',
          builder: (_, __) => const QuestionDetailScreen(),
        ),
        GoRoute(
          path: '/exercise/practice',
          builder: (_, __) => const Scaffold(body: Text('PRACTICE')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('x=2'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('x=2'), findsOneWidget);
    expect(find.text('移项法则'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('继续练习'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('继续练习'), findsOneWidget);

    await tester.tap(find.text('继续练习'));
    await tester.pumpAndSettle();

    expect(find.text('PRACTICE'), findsOneWidget);
    expect(
        container
            .read(currentQuestionProvider)
            ?.savedExercises
            .map((exercise) => exercise.question)
            .toList(),
        <String>['练习题1']);
  });

  testWidgets('question detail generates manual practice and stays on detail',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final service = _ExerciseGeneratingAiService();
    final question = _buildSavedSplitQuestion().copyWith(
      savedExercises: const <GeneratedExercise>[],
    );
    await repository.saveDraft(question);

    final container = ProviderContainer(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(repository),
        aiAnalysisServiceProvider.overrideWithValue(service),
        currentQuestionProvider.overrideWith((ref) => question),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/notebook/question/${question.id}',
      routes: <GoRoute>[
        GoRoute(
          path: '/notebook',
          builder: (_, __) => const Scaffold(body: Text('NOTEBOOK')),
        ),
        GoRoute(
          path: '/notebook/question/:id',
          builder: (_, __) => const QuestionDetailScreen(),
        ),
        GoRoute(
          path: '/exercise/practice',
          builder: (_, __) => const Scaffold(body: Text('PRACTICE')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('AI 答疑'), findsOneWidget);
    expect(find.text('追问这道题'), findsOneWidget);

    expect(find.text('举一反三'), findsOneWidget);
    expect(find.text('生成举一反三'), findsOneWidget);
    expect(find.text('生成练习不会影响原题解析。'), findsOneWidget);
    expect(find.text('根据这道错题的题干、知识点和解析生成练习；宁可少生成，也不展示低质量练习。'), findsOneWidget);
    expect(find.text('暂无练习'), findsNothing);
    expect(find.text('暂无可练习内容'), findsNothing);

    final generatePracticeButton = find.ancestor(
      of: find.text('生成举一反三'),
      matching: find.byType(FilledButton),
    );
    await tester.ensureVisible(generatePracticeButton);
    await tester.pumpAndSettle();
    await tester.tap(generatePracticeButton);
    await tester.pumpAndSettle();

    expect(service.generateCallCount, 1);
    expect(find.text('PRACTICE'), findsNothing);
    expect(find.text('举一反三已生成，可以开始练习'), findsOneWidget);
    expect(find.text('已生成 3 道练习题，可以开始练习。'), findsOneWidget);
    expect(find.text('3 题'), findsOneWidget);
    expect(find.text('0 已答'), findsOneWidget);
    expect(find.text('继续练习'), findsOneWidget);
    expect(
      container
          .read(currentQuestionProvider)
          ?.savedExercises
          .map((exercise) => exercise.question)
          .toList(),
      <String>['已知 x+2=5，求 x', '已知 y+4=9，求 y', '已知 2z+1=7，求 z'],
    );

    final saved = await repository.getById(question.id);
    expect(saved?.savedExercises, hasLength(3));

    await tester.tap(find.text('继续练习'));
    await tester.pumpAndSettle();

    expect(find.text('PRACTICE'), findsOneWidget);
  });

  testWidgets('question detail keeps practice generation retryable when empty',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final question = _buildSavedSplitQuestion(
      savedExercises: const <GeneratedExercise>[],
    );
    await repository.saveDraft(question);
    final service = _ExerciseGeneratingAiService(
      overrideExercises: const <GeneratedExercise>[],
    );

    final container = ProviderContainer(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(repository),
        aiAnalysisServiceProvider.overrideWithValue(service),
        currentQuestionProvider.overrideWith((ref) => question),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/notebook/question/${question.id}',
      routes: <GoRoute>[
        GoRoute(
          path: '/notebook/question/:id',
          builder: (_, __) => const QuestionDetailScreen(),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('生成举一反三'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('生成举一反三'));
    await tester.pumpAndSettle();

    expect(service.generateCallCount, 1);
    expect(find.text('这次没有生成可用练习，可以稍后重试。'), findsOneWidget);
    expect(find.text('生成举一反三'), findsOneWidget);
    expect(find.text('继续练习'), findsNothing);

    final saved = await repository.getById(question.id);
    expect(saved?.savedExercises, isEmpty);
  });

  testWidgets('question detail generates a new round after latest round done',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final service = _ExerciseGeneratingAiService();
    final completedRound = <GeneratedExercise>[
      GeneratedExercise(
        id: 'q-batch-1-round-1-exercise-1',
        questionId: 'q-batch-1',
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '同级',
        question: '已知 a+1=2，求 a',
        options: const <String>['A. 1', 'B. 2'],
        answer: 'A',
        explanation: '解析',
        createdAt: DateTime(2026),
        order: 0,
        isCorrect: true,
        userAnswer: 'A',
        roundIndex: 1,
        roundTotal: 1,
        roundGroupId: 'q-batch-1-round-1',
      ),
    ];
    final question = _buildSavedSplitQuestion(
      savedExercises: completedRound,
    );
    await repository.saveDraft(question);

    final container = ProviderContainer(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(repository),
        aiAnalysisServiceProvider.overrideWithValue(service),
        currentQuestionProvider.overrideWith((ref) => question),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/notebook/question/${question.id}',
      routes: <GoRoute>[
        GoRoute(
          path: '/notebook/question/:id',
          builder: (_, __) => const QuestionDetailScreen(),
        ),
        GoRoute(
          path: '/exercise/practice',
          builder: (_, __) => const ExercisePracticeScreen(),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('再生成一组'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('再生成一组'), findsOneWidget);
    expect(find.text('继续练习'), findsNothing);

    await tester.tap(find.text('再生成一组'));
    await tester.pumpAndSettle();

    expect(service.generateCallCount, 1);
    expect(find.text('已生成 3 道练习题，可以开始练习。'), findsOneWidget);
    expect(find.text('继续练习'), findsOneWidget);

    final saved = await repository.getById(question.id);
    expect(saved?.savedExercises, hasLength(4));
    expect(saved?.savedExercises.last.roundIndex, 2);
    expect(saved?.savedExercises.last.isCorrect, isNull);
    expect(
      saved?.savedExercises.map((exercise) => exercise.question).toList(),
      containsAll(<String>[
        '已知 a+1=2，求 a',
        '已知 x+2=5，求 x',
        '已知 y+4=9，求 y',
        '已知 2z+1=7，求 z',
      ]),
    );
  });

  testWidgets(
      'question detail shows queued practice generation without spinner',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final database = AppDatabase.memory();
    final analysisJobs = DriftAnalysisJobRepository(database);
    addTearDown(database.close);

    final question = _buildSavedSplitQuestion(
      savedExercises: const <GeneratedExercise>[],
    );
    await repository.saveDraft(question);

    final task = AiTaskSpec(
      id: '${question.id}:exercise:test',
      parentQuestionId: question.id,
      type: AiTaskType.exerciseGeneration,
      workloadProfile: AiWorkloadProfile.routine,
      requiredCapabilities: const <AiCapability>{
        AiCapability.structuredOutput,
      },
      qualityPolicy: AiQualityPolicy.reliableRequired,
      queuePriority: AiQueuePriority.background,
    );
    await analysisJobs.enqueue(AnalysisJob.queued(
      id: task.id,
      idempotencyKey: task.id,
      taskSpec: task,
      route: const AiResolvedRoute(
        requestedModelClass: AiModelClass.balanced,
        requestedModelRole: AiModelRole.primary,
        resolvedRouteId: 'test-route',
        providerConfigId: 'test-provider',
        modelName: 'test-model',
        promptVersion: 'exerciseGeneration-v1',
        verifierIsIndependent: false,
      ),
      payloadJson: '{}',
      createdAt: DateTime(2026),
    ));

    final container = ProviderContainer(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(repository),
        analysisJobRepositoryProvider.overrideWithValue(analysisJobs),
        currentQuestionProvider.overrideWith((ref) => question),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/notebook/question/${question.id}',
      routes: <GoRoute>[
        GoRoute(
          path: '/notebook/question/:id',
          builder: (_, __) => const QuestionDetailScreen(),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('排队中...'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('排队中'), findsOneWidget);
    expect(find.text('排队中...'), findsOneWidget);
    expect(find.textContaining('已加入 AI 队列'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('question detail answers follow-up question in place',
      (tester) async {
    final service = _ExerciseGeneratingAiService();
    final conversationRepository = InMemoryAiConversationRepository();
    final question = _buildSavedSplitQuestion();
    final container = ProviderContainer(
      overrides: <Override>[
        aiAnalysisServiceProvider.overrideWithValue(service),
        aiConversationRepositoryProvider.overrideWithValue(
          conversationRepository,
        ),
        currentQuestionProvider.overrideWith((ref) => question),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/notebook/question/${question.id}',
      routes: <GoRoute>[
        GoRoute(
          path: '/notebook',
          builder: (_, __) => const Scaffold(body: Text('NOTEBOOK')),
        ),
        GoRoute(
          path: '/notebook/question/:id',
          builder: (_, __) => const QuestionDetailScreen(),
        ),
        GoRoute(
          path: '/exercise/practice',
          builder: (_, __) => const Scaffold(body: Text('PRACTICE')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('追问这道题'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('追问这道题'));
    await tester.pumpAndSettle();
    expect(find.text('发送追问'), findsOneWidget);
    final followUpField = tester.widget<TextField>(
      find.byType(TextField).last,
    );
    expect(followUpField.minLines, 3);
    expect(followUpField.maxLines, 6);
    expect(followUpField.keyboardType, TextInputType.multiline);
    expect(followUpField.textInputAction, TextInputAction.newline);

    await tester.enterText(find.byType(TextField).last, '为什么要先移项？');
    await tester.tap(find.text('发送追问'));
    await tester.pumpAndSettle();

    expect(service.followUpCallCount, 1);
    expect(service.lastFollowUpQuestion, '为什么要先移项？');
    expect(find.text('为什么要先移项？'), findsOneWidget);
    expect(find.textContaining('等式两边同时减去同一个数'), findsOneWidget);
    expect(find.textContaining('含有 x 的部分'), findsOneWidget);
    expect(find.textContaining('减去 1'), findsOneWidget);

    final savedMessages =
        await conversationRepository.getByQuestionId(question.id);
    expect(savedMessages, hasLength(2));
    expect(savedMessages.first.role, AiConversationRole.user);
    expect(savedMessages.first.content, '为什么要先移项？');
    expect(savedMessages.last.role, AiConversationRole.assistant);
  });

  testWidgets('question detail loads saved follow-up history', (tester) async {
    final repository = InMemoryQuestionRepository();
    final conversationRepository = InMemoryAiConversationRepository();
    final question = _buildSavedSplitQuestion();
    await repository.saveDraft(question);
    await conversationRepository.insertAll(<AiConversationMessage>[
      AiConversationMessage(
        id: 'history-user',
        questionId: question.id,
        role: AiConversationRole.user,
        content: '之前问过的问题',
        createdAt: DateTime(2026, 7, 10, 19),
      ),
      AiConversationMessage(
        id: 'history-assistant',
        questionId: question.id,
        role: AiConversationRole.assistant,
        content: '这是之前保存的回答。',
        createdAt: DateTime(2026, 7, 10, 19, 0, 1),
      ),
    ]);

    final container = ProviderContainer(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(repository),
        aiConversationRepositoryProvider.overrideWithValue(
          conversationRepository,
        ),
        currentQuestionProvider.overrideWith((ref) => question),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/notebook/question/${question.id}',
      routes: <GoRoute>[
        GoRoute(
          path: '/notebook/question/:id',
          builder: (_, __) => const QuestionDetailScreen(),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('追问这道题'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('追问这道题'));
    await tester.pumpAndSettle();

    expect(find.text('之前问过的问题'), findsOneWidget);
    expect(find.textContaining('之前保存的回答'), findsOneWidget);
  });

  testWidgets('question detail screen switches between same batch siblings',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final first = _buildSavedSplitQuestion();
    final second = _buildSavedSplitQuestion(
      id: 'q-batch-2',
      text: '第二题：已知 y-2=0，求 y',
      splitOrder: 2,
    );
    await repository.saveDrafts(<QuestionRecord>[first, second]);

    final container = ProviderContainer(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(repository),
        currentQuestionProvider.overrideWith((ref) => first),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/notebook/question/${first.id}',
      routes: <GoRoute>[
        GoRoute(
          path: '/notebook',
          builder: (_, __) => const NotebookScreen(),
        ),
        GoRoute(
          path: '/notebook/question/:id',
          builder: (_, __) => const QuestionDetailScreen(),
        ),
        GoRoute(
          path: '/exercise/practice',
          builder: (_, __) => const Scaffold(body: Text('PRACTICE')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    expect(find.text('同批题目'), findsOneWidget);
    expect(find.text('第 1 题'), findsOneWidget);
    expect(find.text('第 2 题'), findsOneWidget);
    expect(find.text('第一题：已知 x+1=3，求 x'), findsOneWidget);

    await tester.tap(find.text('第 2 题'));
    await tester.pumpAndSettle();

    expect(container.read(currentQuestionProvider)?.id, 'q-batch-2');
    expect(find.text('第二题：已知 y-2=0，求 y'), findsOneWidget);
  });

  testWidgets('exercise practice screen uses saved split question exercises',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final question = _buildSavedSplitQuestion();
    await repository.saveDraft(question);

    final container = ProviderContainer(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(repository),
        currentQuestionProvider.overrideWith((ref) => question),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/exercise/practice',
      routes: <GoRoute>[
        GoRoute(
          path: '/notebook',
          builder: (_, __) => const Scaffold(body: Text('NOTEBOOK')),
        ),
        GoRoute(
          path: '/notebook/question/:id',
          builder: (_, __) => const Scaffold(body: Text('DETAIL')),
        ),
        GoRoute(
          path: '/exercise/practice',
          builder: (_, __) => const ExercisePracticeScreen(),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    expect(find.text('举一反三 1/1'), findsOneWidget);
    expect(find.text('练习题1'), findsOneWidget);
  });
}
