import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/services/ai_route_resolver.dart';

void main() {
  const resolver = SingleProviderAiRouteResolver(
    routeId: 'vbcode-gpt-5.5',
    providerConfigId: 'default',
    modelName: 'gpt-5.5',
  );

  AiTaskSpec task({
    required AiTaskType type,
    required AiWorkloadProfile workload,
    AiQueuePriority priority = AiQueuePriority.background,
    AiModelRole role = AiModelRole.primary,
    Set<AiCapability> capabilities = const <AiCapability>{},
  }) {
    return AiTaskSpec(
      id: '${type.name}-${priority.name}',
      parentQuestionId: 'question-1',
      type: type,
      workloadProfile: workload,
      requiredCapabilities: capabilities,
      qualityPolicy: role == AiModelRole.verifier
          ? AiQualityPolicy.independentVerification
          : AiQualityPolicy.reliableRequired,
      queuePriority: priority,
      modelRole: role,
    );
  }

  test('routes routine first-pass analysis to the balanced model class', () {
    final route = resolver.resolve(
      task(
        type: AiTaskType.firstPassAnalysis,
        workload: AiWorkloadProfile.routine,
        capabilities: const <AiCapability>{
          AiCapability.vision,
          AiCapability.structuredOutput,
        },
      ),
      promptVersion: 'analysis-v1',
    );

    expect(route.requestedModelClass, AiModelClass.balanced);
    expect(route.requestedModelRole, AiModelRole.primary);
    expect(route.modelName, 'gpt-5.5');
  });

  test('routes proof-heavy work to the deep-reasoning model class', () {
    final route = resolver.resolve(
      task(
        type: AiTaskType.deepAnalysis,
        workload: AiWorkloadProfile.proofHeavy,
        capabilities: const <AiCapability>{AiCapability.deepReasoning},
      ),
      promptVersion: 'deep-proof-v1',
    );

    expect(route.requestedModelClass, AiModelClass.deepReasoning);
    expect(route.requestedModelRole, AiModelRole.primary);
    expect(route.modelName, 'gpt-5.5');
  });

  test('keeps verifier as an independent role instead of another tier', () {
    final route = resolver.resolve(
      task(
        type: AiTaskType.verification,
        workload: AiWorkloadProfile.proofHeavy,
        role: AiModelRole.verifier,
      ),
      promptVersion: 'verify-v1',
    );

    expect(route.requestedModelClass, AiModelClass.deepReasoning);
    expect(route.requestedModelRole, AiModelRole.verifier);
    expect(route.verifierIsIndependent, isFalse);
  });

  test('queue priority does not change the requested model class', () {
    final interactive = resolver.resolve(
      task(
        type: AiTaskType.followUp,
        workload: AiWorkloadProfile.routine,
        priority: AiQueuePriority.interactive,
      ),
      promptVersion: 'follow-up-v1',
    );
    final background = resolver.resolve(
      task(
        type: AiTaskType.followUp,
        workload: AiWorkloadProfile.routine,
      ),
      promptVersion: 'follow-up-v1',
    );

    expect(interactive.requestedModelClass, AiModelClass.balanced);
    expect(background.requestedModelClass, AiModelClass.balanced);
  });

  test('persists a route snapshot without provider credentials', () {
    final route = resolver.resolve(
      task(
        type: AiTaskType.answerJudgement,
        workload: AiWorkloadProfile.routine,
      ),
      promptVersion: 'judge-v1',
    );

    expect(route.requestedModelClass, AiModelClass.economical);
    expect(route.toJson(), <String, dynamic>{
      'requestedModelClass': 'economical',
      'requestedModelRole': 'primary',
      'resolvedRouteId': 'vbcode-gpt-5.5',
      'providerConfigId': 'default',
      'modelName': 'gpt-5.5',
      'promptVersion': 'judge-v1',
      'verifierIsIndependent': false,
    });
    expect(route.toJson().keys, isNot(contains('apiKey')));
  });
}
