import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart'
    hide AnalysisJob, QuestionRecord;
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/drift_analysis_job_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/data/services/app_analysis_job_runner.dart';
import 'package:smart_wrong_notebook/src/data/services/question_analysis_coordinator.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/domain/services/ai_route_resolver.dart';
import 'package:smart_wrong_notebook/src/domain/services/analysis_job_queue_executor.dart';

class _BlockingRunner implements AnalysisJobRunner {
  final Completer<void> release = Completer<void>();

  @override
  Future<String> run(AnalysisJobExecutionContext context) async {
    await release.future;
    final payload = jsonDecode(context.job.payloadJson) as Map<String, dynamic>;
    final question = QuestionRecord.fromJson(
      payload['question'] as Map<String, dynamic>,
    );
    return jsonEncode(question
        .copyWith(
          contentStatus: ContentStatus.ready,
          analysisResult: const AnalysisResult(
            subject: Subject.math,
            finalAnswer: '后台答案',
            steps: <String>['后台步骤'],
            aiTags: <String>[],
            knowledgePoints: <String>[],
            mistakeReason: '',
            studyAdvice: '',
          ),
        )
        .toJson());
  }
}

void main() {
  late AppDatabase database;
  late DriftAnalysisJobRepository repository;

  setUp(() {
    database = AppDatabase.memory();
    repository = DriftAnalysisJobRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('queues extraction and first pass and returns the completed record',
      () async {
    final settings = InMemorySettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settings,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '识别题干',
        normalizedQuestionText: '规范题干',
        subject: Subject.math,
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: 'x=2',
        steps: <String>['移项'],
        aiTags: <String>['方程'],
        knowledgePoints: <String>['等式性质'],
        mistakeReason: '符号错误',
        studyAdvice: '检查移项',
      ),
    );
    final executor = AnalysisJobQueueExecutor(
      repository: repository,
      runner: AppAnalysisJobRunner(service),
    );
    final coordinator = QueuedQuestionAnalysisCoordinator(
      service: service,
      settingsRepository: settings,
      repository: repository,
      executor: executor,
      runIdFactory: () => 'run-1',
    );
    final question = QuestionRecord.draft(
      id: 'question-1',
      imagePath: '/tmp/question.jpg',
      subject: Subject.math,
      recognizedText: '',
    );

    final updated = await coordinator.analyze(question);
    final jobs = await repository.listAll();

    expect(service.extractionCallCount, 1);
    expect(service.analysisCallCount, 1);
    expect(updated.analysisResult?.finalAnswer, 'x=2');
    expect(jobs, hasLength(2));
    expect(
        jobs.every((job) => job.status == AnalysisJobStatus.completed), isTrue);
    expect(jobs.last.route.modelName, 'test-model');
    final snapshot = coordinator.snapshotFromJob(
      jobs.last,
      dependencyJobs: <AnalysisJob>[jobs.first],
    );
    expect(snapshot.displaySubject, Subject.math);
    expect(snapshot.displayQuestionText, '规范题干');
  });

  test('retries one failed candidate without rerunning completed candidates',
      () async {
    const firstResult = AnalysisResult(
      subject: Subject.math,
      finalAnswer: '第一题答案',
      steps: <String>['第一题步骤'],
      aiTags: <String>['方程'],
      knowledgePoints: <String>['一次方程'],
      mistakeReason: '',
      studyAdvice: '',
    );
    const retriedResult = AnalysisResult(
      subject: Subject.math,
      finalAnswer: '第二题重试答案',
      steps: <String>['第二题重试步骤'],
      aiTags: <String>['函数'],
      knowledgePoints: <String>['函数值'],
      mistakeReason: '',
      studyAdvice: '',
    );
    final source = QuestionRecord.draft(
      id: 'question-partial',
      imagePath: '',
      subject: Subject.math,
      recognizedText: '1. 第一题\n2. 第二题',
    ).copyWith(
      contentStatus: ContentStatus.ready,
      splitResult: QuestionSplitResult(
        sourceText: '1. 第一题\n2. 第二题',
        strategy: QuestionSplitStrategy.numbered,
        candidates: const <QuestionSplitCandidate>[
          QuestionSplitCandidate(
            id: 'candidate-1',
            order: 1,
            text: '第一题',
            strategy: QuestionSplitStrategy.numbered,
          ),
          QuestionSplitCandidate(
            id: 'candidate-2',
            order: 2,
            text: '第二题',
            strategy: QuestionSplitStrategy.numbered,
          ),
        ],
      ),
      candidateAnalyses: const <CandidateAnalysisSnapshot>[
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-1',
          order: 1,
          questionText: '第一题',
          analysisResult: firstResult,
          subject: Subject.math,
          aiTags: <String>['方程'],
          aiKnowledgePoints: <String>['一次方程'],
        ),
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-2',
          order: 2,
          questionText: '第二题',
          status: CandidateAnalysisStatus.failed,
          errorMessage: 'HTTP 503',
        ),
      ],
    );
    final rootTask = AiTaskSpec(
      id: 'question-partial:first-pass',
      parentQuestionId: source.id,
      type: AiTaskType.firstPassAnalysis,
      workloadProfile: AiWorkloadProfile.routine,
      requiredCapabilities: const <AiCapability>{
        AiCapability.structuredOutput,
      },
      qualityPolicy: AiQualityPolicy.reliableRequired,
      queuePriority: AiQueuePriority.firstPass,
    );
    const route = SingleProviderAiRouteResolver(
      routeId: 'test:test-model',
      providerConfigId: 'test',
      modelName: 'test-model',
    );
    final rootJob = AnalysisJob.queued(
      id: rootTask.id,
      idempotencyKey: rootTask.id,
      taskSpec: rootTask,
      route: route.resolve(rootTask, promptVersion: 'analysis-v1'),
      payloadJson: jsonEncode(<String, dynamic>{'question': source.toJson()}),
      createdAt: DateTime(2026, 8, 5),
    ).copyWith(
      status: AnalysisJobStatus.completed,
      attemptCount: 1,
      resultJson: jsonEncode(source.toJson()),
      completedAt: DateTime(2026, 8, 5),
    );
    await repository.enqueue(rootJob);

    final settings = InMemorySettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settings,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '',
        normalizedQuestionText: '',
      ),
      analysisResultValue: retriedResult,
    );
    final executor = AnalysisJobQueueExecutor(
      repository: repository,
      runner: AppAnalysisJobRunner(
        service,
        analysisJobRepository: repository,
      ),
    );
    final coordinator = QueuedQuestionAnalysisCoordinator(
      service: service,
      settingsRepository: settings,
      repository: repository,
      executor: executor,
      runIdFactory: () => 'retry-1',
    );

    final queued = await coordinator.retryCandidate(
      source,
      source.candidateAnalyses.last,
    );
    await executor.processUntilIdle();

    expect(queued, isTrue);
    expect(service.extractionCallCount, 0);
    expect(service.analysisCallCount, 1);
    final completedRoot = await repository.getById(rootJob.id);
    final updated = QuestionRecord.fromJson(
      jsonDecode(completedRoot!.resultJson!) as Map<String, dynamic>,
    );
    expect(
        updated.candidateAnalyses.first.analysisResult?.finalAnswer, '第一题答案');
    expect(
        updated.candidateAnalyses.last.status, CandidateAnalysisStatus.success);
    expect(
        updated.candidateAnalyses.last.analysisResult?.finalAnswer, '第二题重试答案');
    expect(
      (await repository.listAll())
          .where(
              (job) => job.taskSpec.type == AiTaskType.candidateAnalysisRetry)
          .single
          .status,
      AnalysisJobStatus.completed,
    );
  });

  test('does not enqueue a duplicate retry for the same failed candidate',
      () async {
    final source = QuestionRecord.draft(
      id: 'question-duplicate-retry',
      imagePath: '',
      subject: Subject.math,
      recognizedText: '第二题',
    ).copyWith(
      candidateAnalyses: const <CandidateAnalysisSnapshot>[
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-2',
          order: 2,
          questionText: '第二题',
          status: CandidateAnalysisStatus.failed,
        ),
      ],
    );
    final activeSpec = AiTaskSpec(
      id: 'question-duplicate-retry:candidate-retry:candidate-2:active',
      parentQuestionId: source.id,
      type: AiTaskType.candidateAnalysisRetry,
      workloadProfile: AiWorkloadProfile.routine,
      requiredCapabilities: const <AiCapability>{
        AiCapability.structuredOutput,
      },
      qualityPolicy: AiQualityPolicy.reliableRequired,
      queuePriority: AiQueuePriority.firstPass,
    );
    const route = SingleProviderAiRouteResolver(
      routeId: 'test:test-model',
      providerConfigId: 'test',
      modelName: 'test-model',
    );
    await repository.enqueue(AnalysisJob.queued(
      id: activeSpec.id,
      idempotencyKey: activeSpec.id,
      taskSpec: activeSpec,
      route: route.resolve(activeSpec, promptVersion: 'candidate-retry-v1'),
      payloadJson: jsonEncode(<String, dynamic>{
        'candidateId': 'candidate-2',
      }),
      createdAt: DateTime(2026, 8, 5),
    ));
    final settings = InMemorySettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settings,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '',
        normalizedQuestionText: '',
      ),
      analysisResultValue: const AnalysisResult(
        finalAnswer: 'unused',
        steps: <String>[],
        aiTags: <String>[],
        knowledgePoints: <String>[],
        mistakeReason: '',
        studyAdvice: '',
      ),
    );
    final coordinator = QueuedQuestionAnalysisCoordinator(
      service: service,
      settingsRepository: settings,
      repository: repository,
      executor: AnalysisJobQueueExecutor(
        repository: repository,
        runner: AppAnalysisJobRunner(service),
      ),
      runIdFactory: () => 'duplicate',
    );

    final queued = await coordinator.retryCandidate(
      source,
      source.candidateAnalyses.single,
    );

    expect(queued, isFalse);
    expect(service.analysisCallCount, 0);
    expect(await repository.listAll(), hasLength(1));
  });

  test('unknown queued draft adopts English extraction throughout the queue',
      () async {
    final settings = InMemorySettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settings,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: 'Read the passage.',
        normalizedQuestionText: 'Read the passage.',
        subject: Subject.english,
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.english,
        finalAnswer: 'B',
        steps: <String>['Find the supporting detail.'],
        aiTags: <String>[],
        knowledgePoints: <String>[],
        mistakeReason: '',
        studyAdvice: '',
      ),
    );
    final coordinator = QueuedQuestionAnalysisCoordinator(
      service: service,
      settingsRepository: settings,
      repository: repository,
      executor: AnalysisJobQueueExecutor(
        repository: repository,
        runner: AppAnalysisJobRunner(service),
      ),
      runIdFactory: () => 'unknown-run',
    );
    final source = QuestionRecord.draft(
      id: 'unknown-question',
      imagePath: '/tmp/english.jpg',
      subject: Subject.unknown,
      recognizedText: '',
    );

    final result = await coordinator.analyze(source);
    final jobs = await repository.listAll();
    final extraction = jobs.firstWhere(
      (job) => job.taskSpec.type == AiTaskType.extraction,
    );
    final firstPass = jobs.firstWhere(
      (job) => job.taskSpec.type == AiTaskType.firstPassAnalysis,
    );
    final extractionPayload =
        jsonDecode(extraction.payloadJson) as Map<String, dynamic>;
    final snapshot = coordinator.snapshotFromJob(
      firstPass,
      dependencyJobs: <AnalysisJob>[extraction],
    );

    expect(extractionPayload['subjectName'], Subject.unknown.name);
    expect(result.subject, Subject.english);
    expect(snapshot.displaySubject, Subject.english);
    expect(snapshot.displayQuestionText, 'Read the passage.');
  });

  test('snapshot treats only running extraction as active recognition',
      () async {
    final settings = InMemorySettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settings,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '',
        normalizedQuestionText: '',
      ),
      analysisResultValue: const AnalysisResult(
        finalAnswer: '',
        steps: <String>[],
        aiTags: <String>[],
        knowledgePoints: <String>[],
        mistakeReason: '',
        studyAdvice: '',
      ),
    );
    final coordinator = QueuedQuestionAnalysisCoordinator(
      service: service,
      settingsRepository: settings,
      repository: repository,
      executor: AnalysisJobQueueExecutor(
        repository: repository,
        runner: AppAnalysisJobRunner(service),
      ),
    );
    final source = QuestionRecord.draft(
      id: 'queued-question',
      imagePath: '/tmp/queued.jpg',
      subject: Subject.unknown,
      recognizedText: '待识别题目',
    );
    final extractionSpec = AiTaskSpec(
      id: 'queued-question:extraction',
      parentQuestionId: source.id,
      type: AiTaskType.extraction,
      workloadProfile: AiWorkloadProfile.visionHeavy,
      requiredCapabilities: const <AiCapability>{
        AiCapability.vision,
        AiCapability.structuredOutput,
      },
      qualityPolicy: AiQualityPolicy.reliableRequired,
      queuePriority: AiQueuePriority.firstPass,
    );
    final firstPassSpec = AiTaskSpec(
      id: 'queued-question:first-pass',
      parentQuestionId: source.id,
      type: AiTaskType.firstPassAnalysis,
      workloadProfile: AiWorkloadProfile.routine,
      requiredCapabilities: const <AiCapability>{
        AiCapability.structuredOutput,
      },
      qualityPolicy: AiQualityPolicy.reliableRequired,
      queuePriority: AiQueuePriority.firstPass,
      dependencyJobIds: const <String>['queued-question:extraction'],
    );
    const resolver = SingleProviderAiRouteResolver(
      routeId: 'test-route',
      providerConfigId: 'default',
      modelName: 'test-model',
    );
    AnalysisJob buildJob(
      AiTaskSpec spec,
      AnalysisJobStatus status, {
      String payloadJson = '{}',
    }) {
      final createdAt = DateTime(2026, 7, 15, 10);
      return AnalysisJob(
        id: spec.id,
        idempotencyKey: spec.id,
        taskSpec: spec,
        route: resolver.resolve(spec, promptVersion: '${spec.type.name}-v1'),
        payloadJson: payloadJson,
        status: status,
        attemptCount: status == AnalysisJobStatus.queued ? 0 : 1,
        maxAttempts: 2,
        createdAt: createdAt,
        updatedAt: createdAt,
        startedAt: status == AnalysisJobStatus.running ? createdAt : null,
      );
    }

    final firstPass = buildJob(
      firstPassSpec,
      AnalysisJobStatus.queued,
      payloadJson: jsonEncode(<String, dynamic>{
        'question': source.toJson(),
      }),
    );
    final queuedExtraction = buildJob(extractionSpec, AnalysisJobStatus.queued);
    final runningExtraction =
        buildJob(extractionSpec, AnalysisJobStatus.running);

    expect(
      coordinator.snapshotFromJob(firstPass,
          dependencyJobs: <AnalysisJob>[queuedExtraction]).isRecognizing,
      isFalse,
    );
    expect(
      coordinator.snapshotFromJob(firstPass,
          dependencyJobs: <AnalysisJob>[runningExtraction]).isRecognizing,
      isTrue,
    );
  });

  test('confirmed text queues only first-pass analysis', () async {
    final settings = InMemorySettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settings,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '',
        normalizedQuestionText: '',
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: '4',
        steps: <String>['代入'],
        aiTags: <String>[],
        knowledgePoints: <String>[],
        mistakeReason: '',
        studyAdvice: '',
      ),
    );
    final coordinator = QueuedQuestionAnalysisCoordinator(
      service: service,
      settingsRepository: settings,
      repository: repository,
      executor: AnalysisJobQueueExecutor(
        repository: repository,
        runner: AppAnalysisJobRunner(service),
      ),
      runIdFactory: () => 'run-1',
    );
    final question = QuestionRecord.draft(
      id: 'question-1',
      imagePath: '/tmp/question.jpg',
      subject: Subject.math,
      recognizedText: 'f(3)=?',
    );

    await coordinator.analyze(question);

    expect(service.extractionCallCount, 0);
    expect(await repository.listAll(), hasLength(1));
  });

  test('persists real candidate counts for a multi-question analysis',
      () async {
    final settings = InMemorySettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settings,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '1. 第一题\n2. 第二题',
        normalizedQuestionText: '1. 第一题\n2. 第二题',
        subject: Subject.math,
        splitResult: QuestionSplitResult(
          sourceText: '1. 第一题\n2. 第二题',
          candidates: <QuestionSplitCandidate>[
            QuestionSplitCandidate(
              id: 'candidate-1',
              order: 1,
              text: '第一题',
              strategy: QuestionSplitStrategy.numbered,
            ),
            QuestionSplitCandidate(
              id: 'candidate-2',
              order: 2,
              text: '第二题',
              strategy: QuestionSplitStrategy.numbered,
            ),
          ],
          strategy: QuestionSplitStrategy.numbered,
        ),
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: '答案',
        steps: <String>['步骤'],
        aiTags: <String>[],
        knowledgePoints: <String>[],
        mistakeReason: '',
        studyAdvice: '',
      ),
      candidateAnalysisResults: const <AnalysisResult>[
        AnalysisResult(
          subject: Subject.math,
          finalAnswer: '第一题答案',
          reconstructedQuestionText: '第一题',
          steps: <String>['第一题步骤'],
          aiTags: <String>[],
          knowledgePoints: <String>[],
          mistakeReason: '',
          studyAdvice: '',
        ),
        AnalysisResult(
          subject: Subject.math,
          finalAnswer: '第二题答案',
          steps: <String>['第二题步骤'],
          aiTags: <String>[],
          knowledgePoints: <String>[],
          mistakeReason: '',
          studyAdvice: '',
        ),
      ],
    );
    final coordinator = QueuedQuestionAnalysisCoordinator(
      service: service,
      settingsRepository: settings,
      repository: repository,
      executor: AnalysisJobQueueExecutor(
        repository: repository,
        runner: AppAnalysisJobRunner(service),
      ),
      runIdFactory: () => 'multi-run',
    );
    final question = QuestionRecord.draft(
      id: 'question-multi',
      imagePath: '/tmp/question.jpg',
      subject: Subject.math,
      recognizedText: '',
    );

    await coordinator.analyze(question);

    final jobs = await repository.listAll();
    final firstPass = jobs.firstWhere(
      (job) => job.taskSpec.type == AiTaskType.firstPassAnalysis,
    );
    expect(firstPass.progress?.stage, AnalysisJobProgressStage.finalizing);
    expect(firstPass.progress?.completedUnits, 2);
    expect(firstPass.progress?.totalUnits, 2);
    expect(firstPass.progress?.failedUnits, 0);
    final extraction = jobs.firstWhere(
      (job) => job.taskSpec.type == AiTaskType.extraction,
    );
    final snapshot = coordinator.snapshotFromJob(
      firstPass,
      dependencyJobs: <AnalysisJob>[extraction],
    );
    expect(snapshot.displayQuestionText, '1. 第一题\n2. 第二题');
  });

  test('enqueue returns a handle before background analysis completes',
      () async {
    final settings = InMemorySettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settings,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '',
        normalizedQuestionText: '',
      ),
      analysisResultValue: const AnalysisResult(
        finalAnswer: '',
        steps: <String>[],
        aiTags: <String>[],
        knowledgePoints: <String>[],
        mistakeReason: '',
        studyAdvice: '',
      ),
    );
    final runner = _BlockingRunner();
    final coordinator = QueuedQuestionAnalysisCoordinator(
      service: service,
      settingsRepository: settings,
      repository: repository,
      executor: AnalysisJobQueueExecutor(
        repository: repository,
        runner: runner,
      ),
      runIdFactory: () => 'background-run',
    );
    final question = QuestionRecord.draft(
      id: 'question-background',
      imagePath: '/tmp/question.jpg',
      subject: Subject.math,
      recognizedText: '已确认题干',
    );

    final handle = await coordinator.enqueue(question);

    expect(handle.parentQuestionId, question.id);
    expect(handle.firstPassJobId, contains('background-run'));
    expect(
        (await repository.getById(handle.firstPassJobId))?.isTerminal, isFalse);

    runner.release.complete();
    final result = await coordinator.waitForResult(handle);
    expect(result.analysisResult?.finalAnswer, '后台答案');
  });
}
