import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart'
    hide AnalysisJob;
import 'package:smart_wrong_notebook/src/data/repositories/drift_analysis_job_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/services/ai_route_resolver.dart';

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

  AnalysisJob job(
    String id, {
    String parentQuestionId = 'question-1',
    AiQueuePriority priority = AiQueuePriority.background,
    List<String> dependencies = const <String>[],
    int maxAttempts = 2,
    DateTime? createdAt,
  }) {
    final timestamp = createdAt ?? DateTime(2026, 7, 13, 16);
    final spec = AiTaskSpec(
      id: id,
      parentQuestionId: parentQuestionId,
      type: id.startsWith('deep')
          ? AiTaskType.deepAnalysis
          : AiTaskType.firstPassAnalysis,
      workloadProfile: id.startsWith('deep')
          ? AiWorkloadProfile.proofHeavy
          : AiWorkloadProfile.routine,
      requiredCapabilities: const <AiCapability>{
        AiCapability.structuredOutput,
      },
      qualityPolicy: AiQualityPolicy.reliableRequired,
      queuePriority: priority,
      dependencyJobIds: dependencies,
    );
    const resolver = SingleProviderAiRouteResolver(
      routeId: 'vbcode-gpt-5.5',
      providerConfigId: 'default',
      modelName: 'gpt-5.5',
    );
    return AnalysisJob.queued(
      id: id,
      idempotencyKey: 'idempotency-$id',
      taskSpec: spec,
      route: resolver.resolve(spec, promptVersion: 'analysis-v1'),
      payloadJson: '{"questionText":"题目"}',
      maxAttempts: maxAttempts,
      createdAt: timestamp,
    );
  }

  test('enqueue is idempotent for the same idempotency key', () async {
    final original = job('core');
    final first = await repository.enqueue(original);
    final duplicate =
        await repository.enqueue(original.copyWith(id: 'other-id'));

    expect(first.id, 'core');
    expect(duplicate.id, 'core');
    expect(await repository.listAll(), hasLength(1));
  });

  test('watchAll emits queue changes for task-center UI', () async {
    final emissions = <List<AnalysisJob>>[];
    final subscription = repository.watchAll().listen(emissions.add);
    addTearDown(subscription.cancel);

    await repository.enqueue(job('core'));
    await Future<void>.delayed(Duration.zero);

    expect(emissions, isNotEmpty);
    expect(emissions.last.single.id, 'core');
  });

  test('deletes the complete job graph for one scan only', () async {
    await repository.enqueue(job('scan-1-extraction'));
    await repository.enqueue(job(
      'scan-1-core',
      dependencies: const <String>['scan-1-extraction'],
    ));
    await repository.enqueue(job(
      'scan-2-core',
      parentQuestionId: 'question-2',
    ));

    await repository.deleteByParentQuestionId('question-1');

    expect(
      (await repository.listAll()).map((item) => item.id),
      <String>['scan-2-core'],
    );
  });

  test('clears all scan jobs even when no questions are saved', () async {
    await repository.enqueue(job('scan-1-core'));
    await repository.enqueue(job(
      'scan-2-core',
      parentQuestionId: 'question-2',
    ));

    await repository.clearAll();

    expect(await repository.listAll(), isEmpty);
  });

  test('cleans old terminal jobs but preserves active dependencies', () async {
    final old = DateTime(2026, 6, 1);
    final completed = job('old-completed').copyWith(
      status: AnalysisJobStatus.completed,
      resultJson: '{"done":true}',
      updatedAt: old,
      completedAt: old,
    );
    final failed = job('old-failed').copyWith(
      status: AnalysisJobStatus.failed,
      errorMessage: 'old failure',
      updatedAt: old,
      completedAt: old,
    );
    final protectedResult = job('old-dependency').copyWith(
      status: AnalysisJobStatus.completed,
      resultJson: '{"dependency":true}',
      updatedAt: old,
      completedAt: old,
    );
    final active = job(
      'active-deep',
      dependencies: const <String>['old-dependency'],
    );
    await repository.enqueue(completed);
    await repository.enqueue(failed);
    await repository.enqueue(protectedResult);
    await repository.enqueue(active);

    final deleted = await repository.deleteTerminalJobsBefore(
      DateTime(2026, 7, 1),
    );

    expect(deleted, 2);
    expect(await repository.getById('old-completed'), isNull);
    expect(await repository.getById('old-failed'), isNull);
    expect(await repository.getById('old-dependency'), isNotNull);
    expect(await repository.getById('active-deep'), isNotNull);
  });

  test('ignores a late failure after a running scan was deleted', () async {
    await repository.enqueue(job('scan-1-core'));
    await repository.claimNextRunnable();
    await repository.deleteByParentQuestionId('question-1');

    final status = await repository.recordFailure(
      'scan-1-core',
      errorMessage: 'late network failure',
      retryable: false,
    );

    expect(status, AnalysisJobStatus.cancelled);
    expect(await repository.listAll(), isEmpty);
  });

  test('claims runnable jobs by priority and then creation time', () async {
    final now = DateTime(2026, 7, 13, 16);
    await repository.enqueue(job(
      'background',
      createdAt: now,
    ));
    await repository.enqueue(job(
      'interactive-later',
      priority: AiQueuePriority.interactive,
      createdAt: now.add(const Duration(seconds: 2)),
    ));
    await repository.enqueue(job(
      'interactive-earlier',
      priority: AiQueuePriority.interactive,
      createdAt: now.add(const Duration(seconds: 1)),
    ));

    final claimed = await repository.claimNextRunnable();

    expect(claimed?.id, 'interactive-earlier');
    expect(claimed?.status, AnalysisJobStatus.running);
    expect(claimed?.attemptCount, 1);
  });

  test('does not claim another job while any job is running', () async {
    await repository.enqueue(job('job-1'));
    await repository.enqueue(job('job-2'));

    final first = await repository.claimNextRunnable();
    final blocked = await repository.claimNextRunnable();

    expect(first?.id, 'job-1');
    expect(blocked, isNull);
  });

  test('waits for dependency results before claiming a deep task', () async {
    await repository.enqueue(job(
      'deep-proof',
      priority: AiQueuePriority.interactive,
      dependencies: const <String>['core'],
    ));
    await repository.enqueue(job('core'));

    final core = await repository.claimNextRunnable();
    expect(core?.id, 'core');
    await repository.markCompleted(
      'core',
      resultJson: '{"verified":true}',
    );

    final deep = await repository.claimNextRunnable();
    expect(deep?.id, 'deep-proof');
  });

  test('does not retry a non-retryable gateway failure', () async {
    await repository.enqueue(job('core'));
    await repository.claimNextRunnable();

    final status = await repository.recordFailure(
      'core',
      errorMessage: 'HTTP 524',
      retryable: false,
    );

    expect(status, AnalysisJobStatus.failed);
    expect((await repository.getById('core'))?.attemptCount, 1);
  });

  test('recovers interrupted jobs without exceeding max attempts', () async {
    await repository.enqueue(job('core', maxAttempts: 2));

    await repository.claimNextRunnable();
    await repository.recoverInterruptedJobs();
    expect(
        (await repository.getById('core'))?.status, AnalysisJobStatus.queued);

    await repository.claimNextRunnable();
    await repository.recoverInterruptedJobs();
    expect(
        (await repository.getById('core'))?.status, AnalysisJobStatus.failed);
  });

  test('completed result is write-protected', () async {
    await repository.enqueue(job('core'));
    await repository.claimNextRunnable();

    final firstWrite = await repository.markCompleted(
      'core',
      resultJson: '{"answer":"first"}',
    );
    final secondWrite = await repository.markCompleted(
      'core',
      resultJson: '{"answer":"replacement"}',
    );

    expect(firstWrite, isTrue);
    expect(secondWrite, isFalse);
    expect(
      (await repository.getById('core'))?.resultJson,
      '{"answer":"first"}',
    );
  });

  test('persists progress only for the active running attempt', () async {
    await repository.enqueue(job('core'));
    final running = await repository.claimNextRunnable();
    const progress = AnalysisJobProgress(
      stage: AnalysisJobProgressStage.analyzingCandidates,
      completedUnits: 2,
      totalUnits: 6,
      failedUnits: 0,
    );

    final updated = await repository.updateProgress(
      'core',
      attemptCount: running!.attemptCount,
      progress: progress,
    );
    final staleAttempt = await repository.updateProgress(
      'core',
      attemptCount: running.attemptCount - 1,
      progress: const AnalysisJobProgress(
        stage: AnalysisJobProgressStage.finalizing,
      ),
    );

    expect(updated, isTrue);
    expect(staleAttempt, isFalse);
    expect((await repository.getById('core'))?.progress, progress);

    await repository.markCompleted('core', resultJson: '{}');
    expect(
      await repository.updateProgress(
        'core',
        attemptCount: running.attemptCount,
        progress: const AnalysisJobProgress(
          stage: AnalysisJobProgressStage.finalizing,
        ),
      ),
      isFalse,
    );
  });
}
