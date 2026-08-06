import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/services/analysis_failure_log_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/services/ai_route_resolver.dart';

void main() {
  AnalysisJob failedJob({
    required String id,
    required DateTime updatedAt,
    String errorMessage = 'request failed',
  }) {
    final spec = AiTaskSpec(
      id: id,
      parentQuestionId: 'question-1',
      type: AiTaskType.firstPassAnalysis,
      workloadProfile: AiWorkloadProfile.routine,
      requiredCapabilities: const <AiCapability>{AiCapability.vision},
      qualityPolicy: AiQualityPolicy.reliableRequired,
      queuePriority: AiQueuePriority.firstPass,
    );
    const resolver = SingleProviderAiRouteResolver(
      routeId: 'vbcode-gpt-5.5',
      providerConfigId: 'vbcode',
      modelName: 'gpt-5.5',
    );
    return AnalysisJob(
      id: id,
      idempotencyKey: id,
      taskSpec: spec,
      route: resolver.resolve(spec, promptVersion: 'analysis-v1'),
      payloadJson: '{"question":"private question"}',
      status: AnalysisJobStatus.failed,
      attemptCount: 2,
      maxAttempts: 2,
      resultJson: null,
      errorMessage: errorMessage,
      createdAt: updatedAt.subtract(const Duration(minutes: 1)),
      updatedAt: updatedAt,
      startedAt: updatedAt,
      completedAt: updatedAt,
    );
  }

  test('exports failed jobs without payload and redacts credentials', () {
    const service = AnalysisFailureLogService();
    final payload = service.buildExportPayload(
      <AnalysisJob>[
        failedJob(
          id: 'old',
          updatedAt: DateTime(2026, 7, 1),
          errorMessage: 'authorization: Bearer secret-token',
        ),
        failedJob(
          id: 'new',
          updatedAt: DateTime(2026, 7, 2),
          errorMessage: 'api_key=secret-key',
        ),
      ],
      exportedAt: DateTime(2026, 7, 3),
    );

    expect(payload['failureCount'], 2);
    final failures = payload['failures'] as List<dynamic>;
    expect(failures.map((item) => item['jobId']), <String>['new', 'old']);
    final encoded = failures.toString();
    expect(encoded, isNot(contains('private question')));
    expect(encoded, isNot(contains('secret-token')));
    expect(encoded, isNot(contains('secret-key')));
    expect(encoded, contains('[REDACTED]'));
  });

  test('ignores completed, queued, and running jobs', () {
    const service = AnalysisFailureLogService();
    final failed = failedJob(
      id: 'failed',
      updatedAt: DateTime(2026, 7, 1),
    );
    final payload = service.buildExportPayload(
      <AnalysisJob>[
        failed,
        failed.copyWith(id: 'completed', status: AnalysisJobStatus.completed),
        failed.copyWith(id: 'queued', status: AnalysisJobStatus.queued),
        failed.copyWith(id: 'running', status: AnalysisJobStatus.running),
      ],
      exportedAt: DateTime(2026, 7, 3),
    );

    expect(payload['failureCount'], 1);
  });

  test('redacts quoted credentials and URL token parameters', () {
    const service = AnalysisFailureLogService();
    final payload = service.buildExportPayload(
      <AnalysisJob>[
        failedJob(
          id: 'sensitive',
          updatedAt: DateTime(2026, 7, 4),
          errorMessage:
              '{"api_key":"secret-json", "authorization":"Bearer secret-auth"} '
              'https://example.test/v1?access_token=secret-query&keep=1',
        ),
      ],
      exportedAt: DateTime(2026, 7, 5),
    );

    final encoded = payload['failures'].toString();
    expect(encoded, isNot(contains('secret-json')));
    expect(encoded, isNot(contains('secret-auth')));
    expect(encoded, isNot(contains('secret-query')));
    expect(encoded, contains('keep=1'));
    expect(encoded, contains('[REDACTED]'));
  });
}
