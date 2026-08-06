enum AiTaskType {
  extraction,
  independentQuestionSplit,
  firstPassAnalysis,
  candidateAnalysisRetry,
  deepAnalysis,
  verification,
  followUp,
  exerciseGeneration,
  answerJudgement,
}

enum AiWorkloadProfile {
  routine,
  visionHeavy,
  composite,
  longContext,
  proofHeavy,
}

enum AiCapability {
  vision,
  structuredOutput,
  longContext,
  deepReasoning,
}

enum AiQualityPolicy {
  reliableRequired,
  independentVerification,
  draftAllowed,
}

enum AiQueuePriority {
  interactive,
  firstPass,
  background,
}

enum AiModelClass {
  economical,
  balanced,
  deepReasoning,
}

enum AiModelRole {
  primary,
  verifier,
}

class AiTaskSpec {
  const AiTaskSpec({
    required this.id,
    required this.parentQuestionId,
    required this.type,
    required this.workloadProfile,
    required this.requiredCapabilities,
    required this.qualityPolicy,
    required this.queuePriority,
    this.dependencyJobIds = const <String>[],
    this.modelRole = AiModelRole.primary,
  });

  final String id;
  final String parentQuestionId;
  final AiTaskType type;
  final AiWorkloadProfile workloadProfile;
  final Set<AiCapability> requiredCapabilities;
  final AiQualityPolicy qualityPolicy;
  final AiQueuePriority queuePriority;
  final List<String> dependencyJobIds;
  final AiModelRole modelRole;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'parentQuestionId': parentQuestionId,
      'type': type.name,
      'workloadProfile': workloadProfile.name,
      'requiredCapabilities':
          requiredCapabilities.map((item) => item.name).toList(),
      'qualityPolicy': qualityPolicy.name,
      'queuePriority': queuePriority.name,
      'dependencyJobIds': dependencyJobIds,
      'modelRole': modelRole.name,
    };
  }

  factory AiTaskSpec.fromJson(Map<String, dynamic> json) {
    return AiTaskSpec(
      id: json['id'] as String? ?? '',
      parentQuestionId: json['parentQuestionId'] as String? ?? '',
      type: _enumByName(
        AiTaskType.values,
        json['type'],
        AiTaskType.firstPassAnalysis,
      ),
      workloadProfile: _enumByName(
        AiWorkloadProfile.values,
        json['workloadProfile'],
        AiWorkloadProfile.routine,
      ),
      requiredCapabilities: (json['requiredCapabilities'] as List? ?? const [])
          .map((value) => _enumByName(
                AiCapability.values,
                value,
                AiCapability.structuredOutput,
              ))
          .toSet(),
      qualityPolicy: _enumByName(
        AiQualityPolicy.values,
        json['qualityPolicy'],
        AiQualityPolicy.reliableRequired,
      ),
      queuePriority: _enumByName(
        AiQueuePriority.values,
        json['queuePriority'],
        AiQueuePriority.background,
      ),
      dependencyJobIds:
          List<String>.from(json['dependencyJobIds'] as List? ?? const []),
      modelRole: _enumByName(
        AiModelRole.values,
        json['modelRole'],
        AiModelRole.primary,
      ),
    );
  }
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
