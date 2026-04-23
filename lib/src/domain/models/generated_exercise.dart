class GeneratedExercise {
  const GeneratedExercise({
    required this.id,
    required this.difficulty,
    required this.question,
    required this.answer,
    required this.explanation,
    this.isCorrect,
    this.options,
    this.userAnswer,
  });

  factory GeneratedExercise.fromJson(Map<String, dynamic> json) {
    List<String>? options;
    if (json['options'] != null) {
      options = List<String>.from(json['options'] as List);
    }
    return GeneratedExercise(
      id: json['id'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool?,
      options: options,
      userAnswer: json['userAnswer'] as String?,
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
      'options': options,
      'userAnswer': userAnswer,
    };
  }

  final String id;
  final String difficulty;
  final String question;
  final String answer;
  final String explanation;
  final bool? isCorrect;
  final List<String>? options; // A/B/C/D 选项
  final String? userAnswer; // 用户选择的答案

  GeneratedExercise copyWith({
    bool? isCorrect,
    List<String>? options,
    String? userAnswer,
  }) {
    return GeneratedExercise(
      id: id,
      difficulty: difficulty,
      question: question,
      answer: answer,
      explanation: explanation,
      isCorrect: isCorrect ?? this.isCorrect,
      options: options ?? this.options,
      userAnswer: userAnswer ?? this.userAnswer,
    );
  }
}
