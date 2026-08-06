import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_plan.dart';

class AnalysisPlanner {
  const AnalysisPlanner();

  AnalysisPlan buildInitialPlan({
    required String questionId,
    required bool needsExtraction,
    required bool requiresImageAnalysis,
    String? runId,
  }) {
    final taskPrefix = runId == null ? questionId : '$questionId:$runId';
    final extractionId = '$taskPrefix:extraction';
    final firstPassId = '$taskPrefix:first-pass';
    final tasks = <AiTaskSpec>[];

    if (needsExtraction) {
      tasks.add(AiTaskSpec(
        id: extractionId,
        parentQuestionId: questionId,
        type: AiTaskType.extraction,
        workloadProfile: AiWorkloadProfile.visionHeavy,
        requiredCapabilities: const <AiCapability>{
          AiCapability.vision,
          AiCapability.structuredOutput,
        },
        qualityPolicy: AiQualityPolicy.reliableRequired,
        queuePriority: AiQueuePriority.firstPass,
      ));
    }

    tasks.add(AiTaskSpec(
      id: firstPassId,
      parentQuestionId: questionId,
      type: AiTaskType.firstPassAnalysis,
      workloadProfile: requiresImageAnalysis
          ? AiWorkloadProfile.visionHeavy
          : AiWorkloadProfile.routine,
      requiredCapabilities: <AiCapability>{
        AiCapability.structuredOutput,
        if (requiresImageAnalysis) AiCapability.vision,
      },
      qualityPolicy: AiQualityPolicy.reliableRequired,
      queuePriority: AiQueuePriority.firstPass,
      dependencyJobIds:
          needsExtraction ? <String>[extractionId] : const <String>[],
    ));

    return AnalysisPlan(
      id: '$taskPrefix:initial-plan',
      parentQuestionId: questionId,
      tasks: tasks,
    );
  }

  AiTaskSpec buildCandidateAnalysisRetryTask({
    required String questionId,
    required String candidateId,
    required String parentFirstPassJobId,
    required String requestId,
    required bool requiresImageAnalysis,
  }) {
    return AiTaskSpec(
      id: '$questionId:candidate-retry:$candidateId:$requestId',
      parentQuestionId: questionId,
      type: AiTaskType.candidateAnalysisRetry,
      workloadProfile: requiresImageAnalysis
          ? AiWorkloadProfile.visionHeavy
          : AiWorkloadProfile.routine,
      requiredCapabilities: <AiCapability>{
        AiCapability.structuredOutput,
        if (requiresImageAnalysis) AiCapability.vision,
      },
      qualityPolicy: AiQualityPolicy.reliableRequired,
      // A manual retry belongs to the original scan flow. It stays serial and
      // does not preempt a request that is already running.
      queuePriority: AiQueuePriority.firstPass,
      dependencyJobIds: <String>[parentFirstPassJobId],
    );
  }

  AiTaskSpec buildDeepAnalysisTask({
    required String questionId,
    required String targetId,
    required String coreJobId,
    bool requiresLongContext = true,
  }) {
    return AiTaskSpec(
      id: '$questionId:deep:$targetId',
      parentQuestionId: questionId,
      type: AiTaskType.deepAnalysis,
      workloadProfile: AiWorkloadProfile.proofHeavy,
      requiredCapabilities: <AiCapability>{
        AiCapability.structuredOutput,
        AiCapability.deepReasoning,
        if (requiresLongContext) AiCapability.longContext,
      },
      qualityPolicy: AiQualityPolicy.draftAllowed,
      queuePriority: AiQueuePriority.background,
      dependencyJobIds: <String>[coreJobId],
    );
  }

  AiTaskSpec buildFollowUpTask({
    required String questionId,
    required String requestId,
  }) {
    return AiTaskSpec(
      id: '$questionId:follow-up:$requestId',
      parentQuestionId: questionId,
      type: AiTaskType.followUp,
      workloadProfile: AiWorkloadProfile.routine,
      requiredCapabilities: const <AiCapability>{
        AiCapability.structuredOutput,
      },
      qualityPolicy: AiQualityPolicy.reliableRequired,
      queuePriority: AiQueuePriority.interactive,
    );
  }

  AiTaskSpec buildExerciseGenerationTask({
    required String questionId,
    required String requestId,
  }) {
    return AiTaskSpec(
      id: '$questionId:exercise:$requestId',
      parentQuestionId: questionId,
      type: AiTaskType.exerciseGeneration,
      workloadProfile: AiWorkloadProfile.routine,
      requiredCapabilities: const <AiCapability>{
        AiCapability.structuredOutput,
      },
      qualityPolicy: AiQualityPolicy.reliableRequired,
      queuePriority: AiQueuePriority.background,
    );
  }

  AiTaskSpec buildAnswerJudgementTask({
    required String questionId,
    required String requestId,
  }) {
    return AiTaskSpec(
      id: '$questionId:judgement:$requestId',
      parentQuestionId: questionId,
      type: AiTaskType.answerJudgement,
      workloadProfile: AiWorkloadProfile.routine,
      requiredCapabilities: const <AiCapability>{
        AiCapability.structuredOutput,
      },
      qualityPolicy: AiQualityPolicy.reliableRequired,
      queuePriority: AiQueuePriority.interactive,
    );
  }
}
