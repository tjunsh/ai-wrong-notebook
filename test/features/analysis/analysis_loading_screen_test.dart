import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/data/services/question_analysis_coordinator.dart';
import 'package:smart_wrong_notebook/src/data/services/question_analysis_pipeline.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/analysis_loading_screen.dart';

class _TestSettingsRepository implements SettingsRepository {
  @override
  Future<AiProviderConfig?> getAiProviderConfig() async =>
      const AiProviderConfig(
        id: 'test',
        displayName: 'Test',
        baseUrl: 'https://api.test.com',
        model: 'test-model',
        apiKey: 'test-key',
      );

  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<void> saveAiProviderConfig(AiProviderConfig config) async {}

  @override
  Future<void> setString(String key, String value) async {}
}

class _FailingCandidateAiAnalysisService extends TestAiAnalysisService {
  _FailingCandidateAiAnalysisService({
    required super.settingsRepository,
    required super.extractionResult,
    required super.analysisResultValue,
    required this.failedText,
  });

  final String failedText;
  final Map<String, int> attempts = <String, int>{};

  @override
  Future<AnalysisResult> analyzeExtractedQuestion({
    required String correctedText,
    required String subjectName,
    String? imagePath,
  }) async {
    attempts[correctedText] = (attempts[correctedText] ?? 0) + 1;
    if (correctedText.contains(failedText)) {
      throw AiAnalysisException('模拟子题解析失败');
    }
    return super.analyzeExtractedQuestion(
      correctedText: correctedText,
      subjectName: subjectName,
      imagePath: imagePath,
    );
  }
}

class _DeferredQuestionAnalysisCoordinator
    implements QuestionAnalysisCoordinator {
  final Completer<QuestionRecord> completer = Completer<QuestionRecord>();

  @override
  Future<QuestionRecord> analyze(
    QuestionRecord question, {
    CandidateAnalysisProgress? onProgress,
  }) {
    return completer.future;
  }
}

class _DeferredBackgroundQuestionAnalysisCoordinator
    implements BackgroundQuestionAnalysisCoordinator {
  final Completer<QuestionRecord> completer = Completer<QuestionRecord>();

  @override
  Future<QuestionAnalysisHandle> enqueue(QuestionRecord question) async {
    return QuestionAnalysisHandle(
      parentQuestionId: question.id,
      firstPassJobId: '${question.id}:first-pass',
    );
  }

  @override
  Future<QuestionRecord> waitForResult(QuestionAnalysisHandle handle) {
    return completer.future;
  }

  @override
  Future<QuestionRecord> analyze(
    QuestionRecord question, {
    CandidateAnalysisProgress? onProgress,
  }) async {
    final handle = await enqueue(question);
    return waitForResult(handle);
  }

  @override
  QuestionAnalysisTaskSnapshot snapshotFromJob(
    AnalysisJob job, {
    Iterable<AnalysisJob> dependencyJobs = const <AnalysisJob>[],
    Iterable<AnalysisJob> relatedJobs = const <AnalysisJob>[],
  }) {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets(
      'background queue exposes continue-recording action after enqueue',
      (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final coordinator = _DeferredBackgroundQuestionAnalysisCoordinator();
    final container = ProviderContainer(
      overrides: <Override>[
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        questionAnalysisCoordinatorProvider.overrideWithValue(coordinator),
      ],
    );
    addTearDown(container.dispose);
    final question = QuestionRecord.draft(
      id: 'question-background',
      imagePath: '/tmp/question.jpg',
      subject: Subject.math,
      recognizedText: '后台题目',
    );
    container.read(currentQuestionProvider.notifier).state = question;
    final router = GoRouter(
      initialLocation: '/analysis/loading',
      routes: <GoRoute>[
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('HOME_SCREEN')),
        ),
        GoRoute(
          path: '/analysis/loading',
          builder: (_, __) => const AnalysisLoadingScreen(),
        ),
        GoRoute(
          path: '/analysis/result',
          builder: (_, __) => const Scaffold(body: Text('RESULT_SCREEN')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();

    expect(find.text('继续录题'), findsOneWidget);
    await tester.tap(find.text('继续录题'));
    await tester.pumpAndSettle();
    expect(find.text('HOME_SCREEN'), findsOneWidget);

    coordinator.completer.complete(question.copyWith(
      contentStatus: ContentStatus.ready,
    ));
  });

  testWidgets('completed stale analysis does not replace a newer question',
      (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final coordinator = _DeferredQuestionAnalysisCoordinator();
    final container = ProviderContainer(
      overrides: <Override>[
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        questionAnalysisCoordinatorProvider.overrideWithValue(coordinator),
      ],
    );
    addTearDown(container.dispose);
    final first = QuestionRecord.draft(
      id: 'question-1',
      imagePath: '/tmp/first.jpg',
      subject: Subject.math,
      recognizedText: '第一题',
    );
    final second = QuestionRecord.draft(
      id: 'question-2',
      imagePath: '/tmp/second.jpg',
      subject: Subject.math,
      recognizedText: '第二题',
    );
    container.read(currentQuestionProvider.notifier).state = first;

    final router = GoRouter(
      initialLocation: '/analysis/loading',
      routes: <GoRoute>[
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('HOME_SCREEN')),
        ),
        GoRoute(
          path: '/analysis/loading',
          builder: (_, __) => const AnalysisLoadingScreen(),
        ),
        GoRoute(
          path: '/analysis/result',
          builder: (_, __) => const Scaffold(body: Text('RESULT_SCREEN')),
        ),
      ],
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();

    container.read(currentQuestionProvider.notifier).state = second;
    router.go('/');
    await tester.pumpAndSettle();
    coordinator.completer.complete(first.copyWith(
      contentStatus: ContentStatus.ready,
    ));
    await tester.pumpAndSettle();

    expect(find.text('HOME_SCREEN'), findsOneWidget);
    expect(container.read(currentQuestionProvider)?.id, 'question-2');
  });

  testWidgets('loading screen extracts before analysis when text is empty',
      (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settingsRepo,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '原始题目文本',
        normalizedQuestionText: '整理后的题目文本',
        subject: Subject.physics,
        splitResult: QuestionSplitResult(
          sourceText: '整理后的题目文本',
          strategy: QuestionSplitStrategy.fallback,
          candidates: <QuestionSplitCandidate>[
            QuestionSplitCandidate(
              id: 'candidate-0',
              order: 1,
              text: '整理后的题目文本',
              strategy: QuestionSplitStrategy.fallback,
            ),
          ],
        ),
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.physics,
        finalAnswer: '答案',
        steps: <String>['步骤1'],
        aiTags: <String>['电学'],
        knowledgePoints: <String>['欧姆定律'],
        mistakeReason: '审题不清',
        studyAdvice: '复习公式',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state =
        QuestionRecord.draft(
      id: 'q-1',
      imagePath: '/tmp/fake.jpg',
      subject: Subject.math,
      recognizedText: '',
    );

    final router = GoRouter(
      initialLocation: '/analysis/loading',
      routes: <GoRoute>[
        GoRoute(
          path: '/analysis/loading',
          builder: (_, __) => const AnalysisLoadingScreen(),
        ),
        GoRoute(
          path: '/analysis/result',
          builder: (_, __) => const Scaffold(body: Text('RESULT_SCREEN')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('RESULT_SCREEN'), findsOneWidget);
    expect(service.extractionCallCount, 1);
    expect(service.analysisCallCount, 1);

    final updated = container.read(currentQuestionProvider);
    expect(updated, isNotNull);
    expect(updated!.subject, Subject.physics);
    expect(updated.extractedQuestionText, '原始题目文本');
    expect(updated.normalizedQuestionText, '整理后的题目文本');
    expect(updated.splitResult, isNotNull);
    expect(updated.splitResult?.strategy, QuestionSplitStrategy.fallback);
    expect(updated.contentStatus, ContentStatus.ready);
    expect(updated.analysisResult?.finalAnswer, '答案');
    expect(updated.extractedQuestionText,
        service.extractionResult.extractedQuestionText);
  });

  testWidgets(
      'loading screen skips extraction when normalized text already exists',
      (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settingsRepo,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '不会被用到',
        normalizedQuestionText: '不会被用到',
        subject: Subject.physics,
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: 'x = 3',
        steps: <String>['移项'],
        aiTags: <String>['方程'],
        knowledgePoints: <String>['一元一次方程'],
        mistakeReason: '粗心',
        studyAdvice: '多练习',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state =
        QuestionRecord.draft(
      id: 'q-2',
      imagePath: '/tmp/fake.jpg',
      subject: Subject.math,
      recognizedText: '已确认文本',
    );

    final router = GoRouter(
      initialLocation: '/analysis/loading',
      routes: <GoRoute>[
        GoRoute(
          path: '/analysis/loading',
          builder: (_, __) => const AnalysisLoadingScreen(),
        ),
        GoRoute(
          path: '/analysis/result',
          builder: (_, __) => const Scaffold(body: Text('RESULT_SCREEN')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('RESULT_SCREEN'), findsOneWidget);
    expect(service.extractionCallCount, 0);
    expect(service.analysisCallCount, 1);

    final updated = container.read(currentQuestionProvider);
    expect(updated, isNotNull);
    expect(updated!.normalizedQuestionText, '已确认文本');
    expect(updated.contentStatus, ContentStatus.ready);
    expect(updated.analysisResult?.finalAnswer, 'x = 3');
  });

  testWidgets(
      'loading screen splits existing numbered text before analysis when split result is missing',
      (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settingsRepo,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '不会被用到',
        normalizedQuestionText: '不会被用到',
        subject: Subject.physics,
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: '默认答案',
        steps: <String>['默认步骤'],
        aiTags: <String>['默认标签'],
        knowledgePoints: <String>['默认知识点'],
        mistakeReason: '默认错因',
        studyAdvice: '默认建议',
      ),
      candidateAnalysisResults: const <AnalysisResult>[
        AnalysisResult(
          subject: Subject.math,
          finalAnswer: '第一题答案',
          steps: <String>['第一题步骤'],
          aiTags: <String>['第一题标签'],
          knowledgePoints: <String>['第一题知识点'],
          mistakeReason: '第一题错因',
          studyAdvice: '第一题建议',
        ),
        AnalysisResult(
          subject: Subject.math,
          finalAnswer: '第二题答案',
          steps: <String>['第二题步骤'],
          aiTags: <String>['第二题标签'],
          knowledgePoints: <String>['第二题知识点'],
          mistakeReason: '第二题错因',
          studyAdvice: '第二题建议',
        ),
        AnalysisResult(
          subject: Subject.math,
          finalAnswer: '第三题答案',
          steps: <String>['第三题步骤'],
          aiTags: <String>['第三题标签'],
          knowledgePoints: <String>['第三题知识点'],
          mistakeReason: '第三题错因',
          studyAdvice: '第三题建议',
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state =
        QuestionRecord.draft(
      id: 'q-existing-numbered',
      imagePath: '/tmp/fake.jpg',
      subject: Subject.math,
      recognizedText: '1. 第一题\n2. 第二题\n3. 第三题',
    );

    final router = GoRouter(
      initialLocation: '/analysis/loading',
      routes: <GoRoute>[
        GoRoute(
          path: '/analysis/loading',
          builder: (_, __) => const AnalysisLoadingScreen(),
        ),
        GoRoute(
          path: '/analysis/result',
          builder: (_, __) => const Scaffold(body: Text('RESULT_SCREEN')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('RESULT_SCREEN'), findsOneWidget);
    expect(service.extractionCallCount, 0);
    expect(service.analysisCallCount, 3);

    final updated = container.read(currentQuestionProvider);
    expect(updated, isNotNull);
    expect(updated!.splitResult?.strategy, QuestionSplitStrategy.numbered);
    expect(updated.splitResult?.candidates, hasLength(3));
    expect(updated.candidateAnalyses, hasLength(3));
    expect(updated.analysisResult?.finalAnswer, '第一题答案');
    expect(
      updated.candidateAnalyses.map((candidate) => candidate.questionText),
      <String>['1. 第一题', '2. 第二题', '3. 第三题'],
    );
  });

  testWidgets(
      'loading screen stores independent candidate analyses when split result has multiple candidates',
      (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settingsRepo,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '1. 第一题\n2. 第二题',
        normalizedQuestionText: '1. 第一题\n2. 第二题',
        subject: Subject.math,
        splitResult: QuestionSplitResult(
          sourceText: '1. 第一题\n2. 第二题',
          strategy: QuestionSplitStrategy.numbered,
          candidates: <QuestionSplitCandidate>[
            QuestionSplitCandidate(
              id: 'candidate-0',
              order: 1,
              text: '1. 第一题',
              strategy: QuestionSplitStrategy.numbered,
            ),
            QuestionSplitCandidate(
              id: 'candidate-1',
              order: 2,
              text: '2. 第二题',
              strategy: QuestionSplitStrategy.numbered,
            ),
          ],
        ),
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: '默认答案',
        steps: <String>['默认步骤'],
        aiTags: <String>['默认标签'],
        knowledgePoints: <String>['默认知识点'],
        mistakeReason: '默认错因',
        studyAdvice: '默认建议',
      ),
      candidateAnalysisResults: const <AnalysisResult>[
        AnalysisResult(
          subject: Subject.math,
          finalAnswer: '第一题答案',
          steps: <String>['第一题步骤'],
          aiTags: <String>['第一题标签'],
          knowledgePoints: <String>['第一题知识点'],
          mistakeReason: '第一题错因',
          studyAdvice: '第一题建议',
        ),
        AnalysisResult(
          subject: Subject.math,
          finalAnswer: '第二题答案',
          steps: <String>['第二题步骤'],
          aiTags: <String>['第二题标签'],
          knowledgePoints: <String>['第二题知识点'],
          mistakeReason: '第二题错因',
          studyAdvice: '第二题建议',
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state =
        QuestionRecord.draft(
      id: 'q-multi',
      imagePath: '/tmp/fake.jpg',
      subject: Subject.math,
      recognizedText: '',
    );

    final router = GoRouter(
      initialLocation: '/analysis/loading',
      routes: <GoRoute>[
        GoRoute(
          path: '/analysis/loading',
          builder: (_, __) => const AnalysisLoadingScreen(),
        ),
        GoRoute(
          path: '/analysis/result',
          builder: (_, __) => const Scaffold(body: Text('RESULT_SCREEN')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    final updated = container.read(currentQuestionProvider);
    expect(updated, isNotNull);
    expect(service.analysisCallCount, 2);
    expect(service.analysisImageCallCount, 0);
    expect(updated!.candidateAnalyses, hasLength(2));
    expect(
        updated.candidateAnalyses.first.analysisResult!.finalAnswer, '第一题答案');
    expect(updated.candidateAnalyses.last.analysisResult!.finalAnswer, '第二题答案');
    expect(updated.savedExercises, isEmpty);
    expect(updated.candidateAnalyses.first.savedExercises, isEmpty);
    expect(updated.analysisResult?.finalAnswer, '第一题答案');
  });

  testWidgets('loading screen passes image to graphical split candidates',
      (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settingsRepo,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '1. 如图，求阴影部分面积。\n2. 解方程 x+2=5。',
        normalizedQuestionText: '1. 如图，求阴影部分面积。\n2. 解方程 x+2=5。',
        subject: Subject.math,
        splitResult: QuestionSplitResult(
          sourceText: '1. 如图，求阴影部分面积。\n2. 解方程 x+2=5。',
          strategy: QuestionSplitStrategy.numbered,
          candidates: <QuestionSplitCandidate>[
            QuestionSplitCandidate(
              id: 'candidate-0',
              order: 1,
              text: '1. 如图，求阴影部分面积。',
              strategy: QuestionSplitStrategy.numbered,
            ),
            QuestionSplitCandidate(
              id: 'candidate-1',
              order: 2,
              text: '2. 解方程 x+2=5。',
              strategy: QuestionSplitStrategy.numbered,
            ),
          ],
        ),
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: '默认答案',
        steps: <String>['默认步骤'],
        aiTags: <String>['默认标签'],
        knowledgePoints: <String>['默认知识点'],
        mistakeReason: '默认错因',
        studyAdvice: '默认建议',
      ),
      candidateAnalysisResults: const <AnalysisResult>[
        AnalysisResult(
          subject: Subject.math,
          finalAnswer: '图形题答案',
          steps: <String>['先读图'],
          aiTags: <String>['面积'],
          knowledgePoints: <String>['图形面积'],
          mistakeReason: '漏看图形',
          studyAdvice: '先标注条件',
        ),
        AnalysisResult(
          subject: Subject.math,
          finalAnswer: 'x = 3',
          steps: <String>['移项'],
          aiTags: <String>['方程'],
          knowledgePoints: <String>['一元一次方程'],
          mistakeReason: '移项错误',
          studyAdvice: '注意变号',
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state =
        QuestionRecord.draft(
      id: 'q-mixed-graphical',
      imagePath: '/tmp/fake.jpg',
      subject: Subject.math,
      recognizedText: '',
    );

    final router = GoRouter(
      initialLocation: '/analysis/loading',
      routes: <GoRoute>[
        GoRoute(
          path: '/analysis/loading',
          builder: (_, __) => const AnalysisLoadingScreen(),
        ),
        GoRoute(
          path: '/analysis/result',
          builder: (_, __) => const Scaffold(body: Text('RESULT_SCREEN')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(service.analysisCallCount, 2);
    expect(service.analysisImageCallCount, 1);
  });

  testWidgets('loading screen stops when any split candidate analysis fails',
      (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final service = _FailingCandidateAiAnalysisService(
      settingsRepository: settingsRepo,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '1. 第一题\n2. 第二题',
        normalizedQuestionText: '1. 第一题\n2. 第二题',
        subject: Subject.math,
        splitResult: QuestionSplitResult(
          sourceText: '1. 第一题\n2. 第二题',
          strategy: QuestionSplitStrategy.numbered,
          candidates: <QuestionSplitCandidate>[
            QuestionSplitCandidate(
              id: 'candidate-0',
              order: 1,
              text: '1. 第一题',
              strategy: QuestionSplitStrategy.numbered,
            ),
            QuestionSplitCandidate(
              id: 'candidate-1',
              order: 2,
              text: '2. 第二题',
              strategy: QuestionSplitStrategy.numbered,
            ),
          ],
        ),
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: '第一题答案',
        steps: <String>['第一题步骤'],
        aiTags: <String>['第一题标签'],
        knowledgePoints: <String>['第一题知识点'],
        mistakeReason: '第一题错因',
        studyAdvice: '第一题建议',
      ),
      failedText: '第二题',
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state =
        QuestionRecord.draft(
      id: 'q-partial-failure',
      imagePath: '/tmp/fake.jpg',
      subject: Subject.math,
      recognizedText: '',
    );

    final router = GoRouter(
      initialLocation: '/analysis/loading',
      routes: <GoRoute>[
        GoRoute(
          path: '/analysis/loading',
          builder: (_, __) => const AnalysisLoadingScreen(),
        ),
        GoRoute(
          path: '/analysis/result',
          builder: (_, __) => const Scaffold(body: Text('RESULT_SCREEN')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('RESULT_SCREEN'), findsOneWidget);
    expect(find.textContaining('多题解析未全部完成'), findsNothing);
    expect(service.attempts['2. 第二题'], 2);
    final updated = container.read(currentQuestionProvider);
    expect(updated?.contentStatus, ContentStatus.ready);
    expect(updated?.candidateAnalyses, hasLength(2));
    expect(updated?.candidateAnalyses.first.isSuccessful, isTrue);
    expect(
        updated?.candidateAnalyses.last.status, CandidateAnalysisStatus.failed);
    expect(updated?.candidateAnalyses.last.analysisResult, isNull);
    expect(updated?.candidateAnalyses.last.errorMessage, isNotEmpty);
    expect(updated?.analysisResult?.finalAnswer, '第一题答案');
  });

  testWidgets('loading screen analyzes extracted text without resending image',
      (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settingsRepo,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '解方程 x^2 - 5x + 6 = 0，求 x 的值。',
        normalizedQuestionText: '解方程 x^2 - 5x + 6 = 0，求 x 的值。',
        subject: Subject.math,
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: 'x = 2 或 x = 3',
        steps: <String>['因式分解'],
        aiTags: <String>['一元二次方程'],
        knowledgePoints: <String>['因式分解'],
        mistakeReason: '计算错误',
        studyAdvice: '复习因式分解',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state =
        QuestionRecord.draft(
      id: 'q-text-only',
      imagePath: '/tmp/fake.jpg',
      subject: Subject.math,
      recognizedText: '',
    );

    final router = GoRouter(
      initialLocation: '/analysis/loading',
      routes: <GoRoute>[
        GoRoute(
          path: '/analysis/loading',
          builder: (_, __) => const AnalysisLoadingScreen(),
        ),
        GoRoute(
          path: '/analysis/result',
          builder: (_, __) => const Scaffold(body: Text('RESULT_SCREEN')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(service.extractionCallCount, 1);
    expect(service.analysisCallCount, 1);
    expect(service.analysisImageCallCount, 0);
  });

  testWidgets('loading screen uses image fallback for visual questions',
      (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settingsRepo,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '如图，在三角形 ABC 中，求角 A 的度数。',
        normalizedQuestionText: '如图，在三角形 ABC 中，求角 A 的度数。',
        subject: Subject.math,
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: '角 A = 40°',
        steps: <String>['根据图形条件计算'],
        aiTags: <String>['三角形'],
        knowledgePoints: <String>['内角和'],
        mistakeReason: '漏看图形条件',
        studyAdvice: '标注图中条件',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state =
        QuestionRecord.draft(
      id: 'q-image-fallback',
      imagePath: '/tmp/fake.jpg',
      subject: Subject.math,
      recognizedText: '',
    );

    final router = GoRouter(
      initialLocation: '/analysis/loading',
      routes: <GoRoute>[
        GoRoute(
          path: '/analysis/loading',
          builder: (_, __) => const AnalysisLoadingScreen(),
        ),
        GoRoute(
          path: '/analysis/result',
          builder: (_, __) => const Scaffold(body: Text('RESULT_SCREEN')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(service.extractionCallCount, 1);
    expect(service.analysisCallCount, 1);
    expect(service.analysisImageCallCount, 1);
  });

  testWidgets('loading screen keeps complete geometry text analysis text-only',
      (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settingsRepo,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '在 △ABC 中，若 AB=AC，且 ∠A=40°，求 ∠B。',
        normalizedQuestionText: '在 △ABC 中，若 AB=AC，且 ∠A=40°，求 ∠B。',
        subject: Subject.math,
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: '∠B = 70°',
        steps: <String>['等腰三角形底角相等'],
        aiTags: <String>['等腰三角形'],
        knowledgePoints: <String>['三角形内角和'],
        mistakeReason: '角度关系不清',
        studyAdvice: '画图辅助理解',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state =
        QuestionRecord.draft(
      id: 'q-geometry-text-only',
      imagePath: '/tmp/fake.jpg',
      subject: Subject.math,
      recognizedText: '',
    );

    final router = GoRouter(
      initialLocation: '/analysis/loading',
      routes: <GoRoute>[
        GoRoute(
          path: '/analysis/loading',
          builder: (_, __) => const AnalysisLoadingScreen(),
        ),
        GoRoute(
          path: '/analysis/result',
          builder: (_, __) => const Scaffold(body: Text('RESULT_SCREEN')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(service.extractionCallCount, 1);
    expect(service.analysisCallCount, 1);
    expect(service.analysisImageCallCount, 0);
  });

  testWidgets('loading screen analyzes language worksheet images directly',
      (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settingsRepo,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '不会被用到',
        normalizedQuestionText: '不会被用到',
        subject: Subject.english,
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.english,
        finalAnswer: '按空号逐项解析',
        steps: <String>['分析全文语境'],
        aiTags: <String>['完形填空'],
        knowledgePoints: <String>['语境理解'],
        mistakeReason: '忽略上下文',
        studyAdvice: '通读全文',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state =
        QuestionRecord.draft(
      id: 'q-language-image',
      imagePath: '/tmp/fake.jpg',
      subject: Subject.english,
      recognizedText: '',
    );

    final router = GoRouter(
      initialLocation: '/analysis/loading',
      routes: <GoRoute>[
        GoRoute(
          path: '/analysis/loading',
          builder: (_, __) => const AnalysisLoadingScreen(),
        ),
        GoRoute(
          path: '/analysis/result',
          builder: (_, __) => const Scaffold(body: Text('RESULT_SCREEN')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('RESULT_SCREEN'), findsOneWidget);
    expect(service.extractionCallCount, 0);
    expect(service.analysisCallCount, 1);
    expect(service.analysisImageCallCount, 1);
  });

  test('parseExtractionResultForTest attaches fallback split result', () {
    final service = AiAnalysisService.fake();

    final result = service.parseExtractionResultForTest(
        '{"subject":"math","extractedQuestionText":"1. 第一题\\n2. 第二题","normalizedQuestionText":"1. 第一题\\n2. 第二题"}');

    expect(result.splitResult, isNotNull);
    expect(result.splitResult?.strategy, QuestionSplitStrategy.numbered);
    expect(
        result.splitResult?.candidates
            .map((candidate) => candidate.text)
            .toList(),
        <String>['1. 第一题', '2. 第二题']);
  });

  test('parseExtractionResultForTest normalizes malformed latex commands', () {
    final service = AiAnalysisService.fake();

    final result = service.parseExtractionResultForTest(
        '{"subject":"math","extractedQuestionText":"4. 解方程组：begin{cases}x + y = 5 x - y = 1end{cases}\\n6. 在 tri\\angle ABC 中，若 AB=AC，且 angle A=40circ，求 angle B。","normalizedQuestionText":"4. 解方程组：begin{cases}x + y = 5 x - y = 1end{cases}\\n6. 在 tri\\angle ABC 中，若 AB=AC，且 angle A=40circ，求 angle B。"}');

    expect(result.normalizedQuestionText, contains(r'\begin{cases}'));
    expect(result.normalizedQuestionText, contains(r'\end{cases}'));
    expect(result.normalizedQuestionText, contains(r'\triangle'));
    expect(result.normalizedQuestionText, contains(r'\angle A'));
    expect(result.normalizedQuestionText, contains(r'40\circ'));
    expect(result.normalizedQuestionText, isNot(contains('begincases')));
    expect(result.normalizedQuestionText, isNot(contains('tri\\angle')));
  });

  test('fake extraction attaches split result', () async {
    final service = AiAnalysisService.fake();

    final result = await service.extractQuestionStructure(
      subjectName: 'math',
      imagePath: '/tmp/fake.jpg',
      textHint: '1. 第一题\n2. 第二题',
    );

    expect(result.splitResult, isNotNull);
    expect(result.splitResult?.strategy, QuestionSplitStrategy.numbered);
  });
}
