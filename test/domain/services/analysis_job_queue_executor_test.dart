import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart'
    hide AnalysisJob;
import 'package:smart_wrong_notebook/src/data/repositories/drift_analysis_job_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/services/ai_route_resolver.dart';
import 'package:smart_wrong_notebook/src/domain/services/analysis_job_queue_executor.dart';

class _TrackingRunner implements AnalysisJobRunner {
  int activeCalls = 0;
  int maxActiveCalls = 0;
  final List<String> startedJobIds = <String>[];
  final Map<String, Map<String, String>> dependencyResultsByJob =
      <String, Map<String, String>>{};
  final Set<String> gatewayFailures = <String>{};

  @override
  Future<String> run(AnalysisJobExecutionContext context) async {
    activeCalls++;
    if (activeCalls > maxActiveCalls) maxActiveCalls = activeCalls;
    startedJobIds.add(context.job.id);
    dependencyResultsByJob[context.job.id] = context.dependencyResults;
    await context.reportProgress(const AnalysisJobProgress(
      stage: AnalysisJobProgressStage.analyzing,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    activeCalls--;
    if (gatewayFailures.contains(context.job.id)) {
      throw const AnalysisJobExecutionException(
        'HTTP 524',
        retryable: false,
      );
    }
    return '{"jobId":"${context.job.id}"}';
  }
}

void main() {
  late AppDatabase database;
  late DriftAnalysisJobRepository repository;
  late _TrackingRunner runner;
  late AnalysisJobQueueExecutor executor;

  setUp(() {
    database = AppDatabase.memory();
    repository = DriftAnalysisJobRepository(database);
    runner = _TrackingRunner();
    executor = AnalysisJobQueueExecutor(
      repository: repository,
      runner: runner,
    );
  });

  tearDown(() async {
    await database.close();
  });

  AnalysisJob job(
    String id, {
    List<String> dependencies = const <String>[],
  }) {
    final spec = AiTaskSpec(
      id: id,
      parentQuestionId: 'question-1',
      type: dependencies.isEmpty
          ? AiTaskType.firstPassAnalysis
          : AiTaskType.deepAnalysis,
      workloadProfile: dependencies.isEmpty
          ? AiWorkloadProfile.routine
          : AiWorkloadProfile.proofHeavy,
      requiredCapabilities: const <AiCapability>{
        AiCapability.structuredOutput,
      },
      qualityPolicy: AiQualityPolicy.reliableRequired,
      queuePriority: AiQueuePriority.firstPass,
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
      payloadJson: '{}',
      createdAt: DateTime(2026, 7, 13, 17),
    );
  }

  test('multiple drain triggers still use one global execution slot', () async {
    await repository.enqueue(job('job-1'));
    await repository.enqueue(job('job-2'));
    await repository.enqueue(job('job-3'));

    await Future.wait(<Future<void>>[
      executor.processUntilIdle(),
      executor.processUntilIdle(),
      executor.processUntilIdle(),
    ]);

    expect(runner.maxActiveCalls, 1);
    expect(runner.startedJobIds, <String>['job-1', 'job-2', 'job-3']);
  });

  test('passes completed dependency results into the deep task', () async {
    await repository.enqueue(job('core'));
    await repository.enqueue(job(
      'deep-proof',
      dependencies: const <String>['core'],
    ));

    await executor.processUntilIdle();

    expect(
      runner.dependencyResultsByJob['deep-proof'],
      <String, String>{'core': '{"jobId":"core"}'},
    );
  });

  test('stops a 524 job without retrying and continues the queue', () async {
    runner.gatewayFailures.add('job-1');
    await repository.enqueue(job('job-1'));
    await repository.enqueue(job('job-2'));

    await executor.processUntilIdle();

    expect(runner.startedJobIds, <String>['job-1', 'job-2']);
    expect(
      (await repository.getById('job-1'))?.status,
      AnalysisJobStatus.failed,
    );
    expect(
      (await repository.getById('job-2'))?.status,
      AnalysisJobStatus.completed,
    );
  });

  test('persists progress reported by the active runner', () async {
    await repository.enqueue(job('job-1'));

    await executor.processUntilIdle();

    expect(
      (await repository.getById('job-1'))?.progress,
      const AnalysisJobProgress(
        stage: AnalysisJobProgressStage.analyzing,
      ),
    );
  });

  test('initialization cleans old terminal jobs before draining', () async {
    final old = DateTime(2026, 1, 1);
    await repository.enqueue(job('old-completed').copyWith(
      status: AnalysisJobStatus.completed,
      resultJson: '{"done":true}',
      updatedAt: old,
      completedAt: old,
    ));
    final initializedExecutor = AnalysisJobQueueExecutor(
      repository: repository,
      runner: runner,
      terminalJobRetention: Duration.zero,
    );

    await initializedExecutor.initialize();

    expect(await repository.getById('old-completed'), isNull);
  });

  test('rechecks terminal cleanup when an active app is used on a later day',
      () async {
    var now = DateTime(2026, 7, 1);
    final cleanupExecutor = AnalysisJobQueueExecutor(
      repository: repository,
      runner: runner,
      terminalJobRetention: const Duration(days: 30),
      maintenanceInterval: const Duration(days: 1),
      now: () => now,
    );

    final old = job('old-failed').copyWith(
      status: AnalysisJobStatus.failed,
      errorMessage: 'old failure',
      updatedAt: DateTime(2026, 6, 15),
      completedAt: DateTime(2026, 6, 15),
    );
    await repository.enqueue(old);
    await cleanupExecutor.initialize();
    expect(await repository.getById('old-failed'), isNotNull);

    now = DateTime(2026, 8, 1);
    await cleanupExecutor.enqueue(job('new-job'));

    expect(await repository.getById('old-failed'), isNull);
  });
}
