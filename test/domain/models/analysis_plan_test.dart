import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_plan.dart';

void main() {
  AiTaskSpec task(
    String id, {
    List<String> dependencies = const <String>[],
  }) {
    return AiTaskSpec(
      id: id,
      parentQuestionId: 'question-1',
      type:
          id == 'deep' ? AiTaskType.deepAnalysis : AiTaskType.firstPassAnalysis,
      workloadProfile: id == 'deep'
          ? AiWorkloadProfile.proofHeavy
          : AiWorkloadProfile.routine,
      requiredCapabilities: const <AiCapability>{
        AiCapability.structuredOutput,
      },
      qualityPolicy: id == 'deep'
          ? AiQualityPolicy.draftAllowed
          : AiQualityPolicy.reliableRequired,
      queuePriority: AiQueuePriority.firstPass,
      dependencyJobIds: dependencies,
    );
  }

  test('orders composite-question tasks after their dependencies', () {
    final plan = AnalysisPlan(
      id: 'plan-1',
      parentQuestionId: 'question-1',
      tasks: <AiTaskSpec>[
        task('deep', dependencies: const <String>['core']),
        task('core'),
      ],
    );

    expect(
      plan.executionOrder.map((item) => item.id),
      <String>['core', 'deep'],
    );
  });

  test('rejects a plan with a missing dependency', () {
    final plan = AnalysisPlan(
      id: 'plan-1',
      parentQuestionId: 'question-1',
      tasks: <AiTaskSpec>[
        task('deep', dependencies: const <String>['missing']),
      ],
    );

    expect(() => plan.executionOrder, throwsStateError);
  });

  test('rejects a circular dependency', () {
    final plan = AnalysisPlan(
      id: 'plan-1',
      parentQuestionId: 'question-1',
      tasks: <AiTaskSpec>[
        task('core', dependencies: const <String>['deep']),
        task('deep', dependencies: const <String>['core']),
      ],
    );

    expect(() => plan.executionOrder, throwsStateError);
  });
}
