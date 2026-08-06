import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';

abstract interface class AiRouteResolver {
  AiResolvedRoute resolve(
    AiTaskSpec task, {
    required String promptVersion,
  });
}

class AiResolvedRoute {
  const AiResolvedRoute({
    required this.requestedModelClass,
    required this.requestedModelRole,
    required this.resolvedRouteId,
    required this.providerConfigId,
    required this.modelName,
    required this.promptVersion,
    required this.verifierIsIndependent,
  });

  final AiModelClass requestedModelClass;
  final AiModelRole requestedModelRole;
  final String resolvedRouteId;
  final String providerConfigId;
  final String modelName;
  final String promptVersion;
  final bool verifierIsIndependent;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'requestedModelClass': requestedModelClass.name,
      'requestedModelRole': requestedModelRole.name,
      'resolvedRouteId': resolvedRouteId,
      'providerConfigId': providerConfigId,
      'modelName': modelName,
      'promptVersion': promptVersion,
      'verifierIsIndependent': verifierIsIndependent,
    };
  }
}

class SingleProviderAiRouteResolver implements AiRouteResolver {
  const SingleProviderAiRouteResolver({
    required this.routeId,
    required this.providerConfigId,
    required this.modelName,
  });

  final String routeId;
  final String providerConfigId;
  final String modelName;

  @override
  AiResolvedRoute resolve(
    AiTaskSpec task, {
    required String promptVersion,
  }) {
    final role = task.type == AiTaskType.verification ||
            task.qualityPolicy == AiQualityPolicy.independentVerification
        ? AiModelRole.verifier
        : task.modelRole;

    return AiResolvedRoute(
      requestedModelClass: _modelClassFor(task, role),
      requestedModelRole: role,
      resolvedRouteId: routeId,
      providerConfigId: providerConfigId,
      modelName: modelName,
      promptVersion: promptVersion,
      verifierIsIndependent: false,
    );
  }

  AiModelClass _modelClassFor(AiTaskSpec task, AiModelRole role) {
    if (role == AiModelRole.verifier ||
        task.type == AiTaskType.deepAnalysis ||
        task.workloadProfile == AiWorkloadProfile.proofHeavy ||
        task.requiredCapabilities.contains(AiCapability.deepReasoning)) {
      return AiModelClass.deepReasoning;
    }

    if (task.type == AiTaskType.answerJudgement ||
        task.type == AiTaskType.independentQuestionSplit) {
      return AiModelClass.economical;
    }

    return AiModelClass.balanced;
  }
}
