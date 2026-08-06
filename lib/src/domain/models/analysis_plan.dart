import 'ai_task_spec.dart';

class AnalysisPlan {
  const AnalysisPlan({
    required this.id,
    required this.parentQuestionId,
    required this.tasks,
  });

  final String id;
  final String parentQuestionId;
  final List<AiTaskSpec> tasks;

  List<AiTaskSpec> get executionOrder {
    final tasksById = <String, AiTaskSpec>{};
    for (final task in tasks) {
      if (task.parentQuestionId != parentQuestionId) {
        throw StateError(
          'Task ${task.id} belongs to a different parent question.',
        );
      }
      if (tasksById.containsKey(task.id)) {
        throw StateError('Duplicate task id: ${task.id}.');
      }
      tasksById[task.id] = task;
    }

    final states = <String, int>{};
    final ordered = <AiTaskSpec>[];

    void visit(AiTaskSpec task) {
      final state = states[task.id] ?? 0;
      if (state == 2) return;
      if (state == 1) {
        throw StateError('Circular task dependency involving ${task.id}.');
      }

      states[task.id] = 1;
      for (final dependencyId in task.dependencyJobIds) {
        final dependency = tasksById[dependencyId];
        if (dependency == null) {
          throw StateError(
            'Task ${task.id} depends on missing task $dependencyId.',
          );
        }
        visit(dependency);
      }
      states[task.id] = 2;
      ordered.add(task);
    }

    for (final task in tasks) {
      visit(task);
    }
    return List<AiTaskSpec>.unmodifiable(ordered);
  }
}
