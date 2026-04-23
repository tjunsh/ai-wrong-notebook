import 'generated_exercise.dart';
import 'subject.dart';

class AnalysisResult {
  const AnalysisResult({
    required this.finalAnswer,
    required this.steps,
    required this.aiTags,
    required this.knowledgePoints,
    required this.mistakeReason,
    required this.studyAdvice,
    required this.generatedExercises,
    this.subject,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final subjectStr = json['subject'] as String?;
    Subject? subject;
    if (subjectStr != null && subjectStr.isNotEmpty) {
      subject = _parseSubject(subjectStr);
    }

    return AnalysisResult(
      subject: subject,
      finalAnswer: json['finalAnswer'] as String? ?? '',
      steps: List<String>.from(json['steps'] as List? ?? []),
      aiTags: List<String>.from(json['aiTags'] as List? ?? []),
      knowledgePoints: List<String>.from(json['knowledgePoints'] as List? ?? []),
      mistakeReason: json['mistakeReason'] as String? ?? '',
      studyAdvice: json['studyAdvice'] as String? ?? '',
      generatedExercises: (json['generatedExercises'] as List?)
              ?.map((e) => GeneratedExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static Subject? _parseSubject(String input) {
    final lower = input.toLowerCase();

    // 精确匹配
    for (final s in Subject.values) {
      if (s.label == input || s.name == input) {
        return s;
      }
    }

    // 模糊匹配
    if (lower.contains('物理') || lower == 'wuli' || lower == 'physics') {
      return Subject.physics;
    }
    if (lower.contains('语文') || lower == 'chinese' || lower == 'chinese') {
      return Subject.chinese;
    }
    if (lower.contains('英语') || lower == 'english' || lower.contains('english')) {
      return Subject.english;
    }
    if (lower.contains('化学') || lower == 'chemistry') {
      return Subject.chemistry;
    }
    if (lower.contains('生物') || lower == 'biology') {
      return Subject.biology;
    }
    if (lower.contains('历史') || lower == 'history') {
      return Subject.history;
    }
    if (lower.contains('地理') || lower == 'geography') {
      return Subject.geography;
    }
    if (lower.contains('政治') || lower == 'politics') {
      return Subject.politics;
    }
    if (lower.contains('科学') || lower == 'science') {
      return Subject.science;
    }
    if (lower.contains('数学') || lower == 'math' || lower.contains('mathematics')) {
      return Subject.math;
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject?.label ?? subject?.name ?? '',
      'finalAnswer': finalAnswer,
      'steps': steps,
      'aiTags': aiTags,
      'knowledgePoints': knowledgePoints,
      'mistakeReason': mistakeReason,
      'studyAdvice': studyAdvice,
      'generatedExercises': generatedExercises.map((e) => e.toJson()).toList(),
    };
  }

  final Subject? subject;
  final String finalAnswer;
  final List<String> steps;
  final List<String> aiTags;
  final List<String> knowledgePoints;
  final String mistakeReason;
  final String studyAdvice;
  final List<GeneratedExercise> generatedExercises;

  AnalysisResult copyWith({List<GeneratedExercise>? generatedExercises, Subject? subject}) {
    return AnalysisResult(
      subject: subject ?? this.subject,
      finalAnswer: finalAnswer,
      steps: steps,
      aiTags: aiTags,
      knowledgePoints: knowledgePoints,
      mistakeReason: mistakeReason,
      studyAdvice: studyAdvice,
      generatedExercises: generatedExercises ?? this.generatedExercises,
    );
  }
}
