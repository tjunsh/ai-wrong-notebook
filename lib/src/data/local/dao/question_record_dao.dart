// TODO: Re-enable part directive after build_runner generates code
// part 'question_record_dao.g.dart';

// Placeholder - will be fully implemented after Drift code generation
import 'dart:convert';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart' as domain;
import 'package:smart_wrong_notebook/src/domain/models/subject.dart' as domain;
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart' as domain;
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart' as domain;
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart' as domain;
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart' as domain;

// ignore: unused_element
domain.AnalysisResult parseAnalysisJson(String json) {
  final map = jsonDecode(json) as Map<String, dynamic>;
  final exercises = (map['generatedExercises'] as List).map((e) {
    final em = e as Map<String, dynamic>;
    return domain.GeneratedExercise(
      id: em['id'] as String,
      difficulty: em['difficulty'] as String,
      question: em['question'] as String,
      answer: em['answer'] as String,
      explanation: em['explanation'] as String,
      isCorrect: em['isCorrect'] as bool?,
    );
  }).toList();
  return domain.AnalysisResult(
    finalAnswer: map['finalAnswer'] as String,
    steps: List<String>.from(map['steps'] as List),
    knowledgePoints: List<String>.from(map['knowledgePoints'] as List),
    mistakeReason: map['mistakeReason'] as String,
    studyAdvice: map['studyAdvice'] as String,
    generatedExercises: exercises,
  );
}

// ignore: unused_element
String encodeAnalysisJson(domain.AnalysisResult result) {
  return jsonEncode({
    'finalAnswer': result.finalAnswer,
    'steps': result.steps,
    'knowledgePoints': result.knowledgePoints,
    'mistakeReason': result.mistakeReason,
    'studyAdvice': result.studyAdvice,
    'generatedExercises': result.generatedExercises.map((e) => {
      'id': e.id,
      'difficulty': e.difficulty,
      'question': e.question,
      'answer': e.answer,
      'explanation': e.explanation,
      'isCorrect': e.isCorrect,
    }).toList(),
  });
}
