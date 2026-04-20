class GeneratedExercise {
  const GeneratedExercise({
    required this.id,
    required this.difficulty,
    required this.question,
    required this.answer,
    required this.explanation,
    this.isCorrect,
  });

  factory GeneratedExercise.fromJson(Map<String, dynamic> json) {
    return GeneratedExercise(
      id: json['id'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'difficulty': difficulty,
      'question': question,
      'answer': answer,
      'explanation': explanation,
      'isCorrect': isCorrect,
    };
  }

  final String id;
  final String difficulty;
  final String question;
  final String answer;
  final String explanation;
  final bool? isCorrect;

  GeneratedExercise copyWith({bool? isCorrect}) {
    return GeneratedExercise(
      id: id,
      difficulty: difficulty,
      question: question,
      answer: answer,
      explanation: explanation,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}
