import 'generated_exercise.dart';

class AnalysisResult {
  const AnalysisResult({
    required this.finalAnswer,
    required this.steps,
    required this.knowledgePoints,
    required this.mistakeReason,
    required this.studyAdvice,
    required this.generatedExercises,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      finalAnswer: json['finalAnswer'] as String? ?? '',
      steps: List<String>.from(json['steps'] as List? ?? []),
      knowledgePoints: List<String>.from(json['knowledgePoints'] as List? ?? []),
      mistakeReason: json['mistakeReason'] as String? ?? '',
      studyAdvice: json['studyAdvice'] as String? ?? '',
      generatedExercises: (json['generatedExercises'] as List?)
              ?.map((e) => GeneratedExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'finalAnswer': finalAnswer,
      'steps': steps,
      'knowledgePoints': knowledgePoints,
      'mistakeReason': mistakeReason,
      'studyAdvice': studyAdvice,
      'generatedExercises': generatedExercises.map((e) => e.toJson()).toList(),
    };
  }

  final String finalAnswer;
  final List<String> steps;
  final List<String> knowledgePoints;
  final String mistakeReason;
  final String studyAdvice;
  final List<GeneratedExercise> generatedExercises;

  AnalysisResult copyWith({List<GeneratedExercise>? generatedExercises}) {
    return AnalysisResult(
      finalAnswer: finalAnswer,
      steps: steps,
      knowledgePoints: knowledgePoints,
      mistakeReason: mistakeReason,
      studyAdvice: studyAdvice,
      generatedExercises: generatedExercises ?? this.generatedExercises,
    );
  }
}
