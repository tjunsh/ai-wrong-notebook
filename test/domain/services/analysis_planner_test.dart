import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/services/analysis_planner.dart';

void main() {
  const planner = AnalysisPlanner();

  test('initial plan extracts first and analyzes the extracted result', () {
    final plan = planner.buildInitialPlan(
      questionId: 'question-1',
      needsExtraction: true,
      requiresImageAnalysis: false,
    );

    expect(
      plan.executionOrder.map((task) => task.type),
      <AiTaskType>[
        AiTaskType.extraction,
        AiTaskType.firstPassAnalysis,
      ],
    );
    expect(
      plan.executionOrder.last.dependencyJobIds,
      <String>['question-1:extraction'],
    );
  });

  test('confirmed text skips extraction but can still require vision', () {
    final plan = planner.buildInitialPlan(
      questionId: 'question-1',
      needsExtraction: false,
      requiresImageAnalysis: true,
    );

    expect(plan.tasks, hasLength(1));
    expect(plan.tasks.single.type, AiTaskType.firstPassAnalysis);
    expect(
      plan.tasks.single.requiredCapabilities,
      contains(AiCapability.vision),
    );
  });

  test('deep proof task depends on the reliable core result', () {
    final task = planner.buildDeepAnalysisTask(
      questionId: 'question-1',
      targetId: '3ii',
      coreJobId: 'question-1:first-pass',
    );

    expect(task.type, AiTaskType.deepAnalysis);
    expect(task.workloadProfile, AiWorkloadProfile.proofHeavy);
    expect(task.requiredCapabilities, contains(AiCapability.deepReasoning));
    expect(task.qualityPolicy, AiQualityPolicy.draftAllowed);
    expect(task.dependencyJobIds, <String>['question-1:first-pass']);
  });

  test('follow-up is interactive while exercise generation is background', () {
    final followUp = planner.buildFollowUpTask(
      questionId: 'question-1',
      requestId: 'follow-up-1',
    );
    final exercises = planner.buildExerciseGenerationTask(
      questionId: 'question-1',
      requestId: 'exercise-1',
    );

    expect(followUp.queuePriority, AiQueuePriority.interactive);
    expect(followUp.type, AiTaskType.followUp);
    expect(exercises.queuePriority, AiQueuePriority.background);
    expect(exercises.type, AiTaskType.exerciseGeneration);
  });
}
