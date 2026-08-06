import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';

int latestExerciseRoundIndex(List<GeneratedExercise> exercises) {
  if (exercises.isEmpty) return 0;
  final explicitRounds = exercises
      .map((exercise) => exercise.roundIndex)
      .whereType<int>()
      .where((round) => round > 0);
  if (explicitRounds.isEmpty) return 1;
  return explicitRounds.reduce((a, b) => a > b ? a : b);
}

List<GeneratedExercise> latestExerciseRound(
  List<GeneratedExercise> exercises,
) {
  if (exercises.isEmpty) return const <GeneratedExercise>[];
  final latestRound = latestExerciseRoundIndex(exercises);
  final roundExercises = exercises
      .where((exercise) => (exercise.roundIndex ?? 1) == latestRound)
      .toList(growable: false);
  return roundExercises.isEmpty ? exercises : roundExercises;
}

bool isLatestExerciseRoundCompleted(List<GeneratedExercise> exercises) {
  final latestRound = latestExerciseRound(exercises);
  return latestRound.isNotEmpty &&
      latestRound.every((exercise) => exercise.isCorrect != null);
}

List<GeneratedExercise> appendGeneratedExerciseRound({
  required String questionId,
  required List<GeneratedExercise> existingExercises,
  required List<GeneratedExercise> generatedExercises,
}) {
  if (generatedExercises.isEmpty) return existingExercises;
  final nextRound = latestExerciseRoundIndex(existingExercises) + 1;
  final roundGroupId = '$questionId-round-$nextRound';
  final nextExercises = generatedExercises.asMap().entries.map((entry) {
    final source = entry.value;
    return source.copyWith(
      id: '$questionId-round-$nextRound-exercise-${entry.key + 1}',
      questionId: questionId,
      order: entry.key,
      isCorrect: null,
      userAnswer: null,
      roundIndex: nextRound,
      roundTotal: generatedExercises.length,
      roundGroupId: roundGroupId,
      sourceExerciseId: source.sourceExerciseId ?? source.id,
    );
  }).toList(growable: false);
  return <GeneratedExercise>[
    ...existingExercises,
    ...nextExercises,
  ];
}
