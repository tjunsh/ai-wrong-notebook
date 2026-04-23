import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

class ExercisePracticeScreen extends ConsumerStatefulWidget {
  const ExercisePracticeScreen({super.key});

  @override
  ConsumerState<ExercisePracticeScreen> createState() => _ExercisePracticeState();
}

class _ExercisePracticeState extends ConsumerState<ExercisePracticeScreen> {
  int _index = 0;
  List<GeneratedExercise>? _exercises;
  String? _questionId;
  bool _isJudging = false;

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentQuestionProvider);

    if (current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('练习'), leading: IconButton(icon: const Icon(CupertinoIcons.chevron_left), onPressed: () => context.go('/notebook'))),
        body: const Center(child: Text('未找到错题记录')),
      );
    }

    if (current.id != _questionId) {
      _index = 0;
      _questionId = current.id;
      _exercises = List.from(current.analysisResult?.generatedExercises ?? []);
    }

    final exercises = _exercises!;
    if (exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('举一反三'),
          leading: IconButton(
            icon: const Icon(CupertinoIcons.chevron_left),
            onPressed: () => context.go('/analysis/result'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(CupertinoIcons.question, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('暂无练习题', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/analysis/result'),
                child: const Text('返回查看解析'),
              ),
            ],
          ),
        ),
      );
    }

    final exercise = exercises[_index];
    final answered = exercise.isCorrect != null;
    final isCorrect = exercise.isCorrect == true;
    final isLast = _index >= exercises.length - 1;
    final answeredCount = exercises.where((e) => e.isCorrect != null).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('举一反三 ${_index + 1}/${exercises.length}'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark),
          onPressed: () => context.go('/notebook'),
        ),
      ),
      body: Column(
        children: <Widget>[
          LinearProgressIndicator(
            value: answeredCount / exercises.length,
            backgroundColor: Colors.grey.shade200,
            minHeight: 3,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _difficultyColor(exercise.difficulty).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _difficultyColor(exercise.difficulty).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        exercise.difficulty,
                        style: TextStyle(fontSize: 12, color: _difficultyColor(exercise.difficulty), fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Spacer(),
                    Text('$answeredCount/${exercises.length} 已答', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 20),
                // Question card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('第 ${_index + 1} 题', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text(exercise.question, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Options
                if (exercise.options != null && exercise.options!.isNotEmpty)
                  ...exercise.options!.asMap().entries.map((entry) {
                    final option = entry.value;
                    final optionLetter = option.substring(0, 1); // A, B, C, D
                    final optionText = option.substring(3); // 选项内容
                    final isSelected = exercise.userAnswer == optionLetter;
                    final isCorrectAnswer = exercise.answer == optionLetter;

                    Color? borderColor;
                    Color? bgColor;
                    Color? textColor;

                    if (answered) {
                      if (isCorrectAnswer) {
                        borderColor = const Color(0xFF16A34A);
                        bgColor = const Color(0xFFF0FDF4);
                        textColor = const Color(0xFF166534);
                      } else if (isSelected && !isCorrect) {
                        borderColor = const Color(0xFFEA580C);
                        bgColor = const Color(0xFFFFF7ED);
                        textColor = const Color(0xFF9A3412);
                      }
                    } else if (isSelected) {
                      borderColor = const Color(0xFF6366F1);
                      bgColor = const Color(0xFFEEF2FF);
                      textColor = const Color(0xFF4338CA);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: answered ? null : () => _selectOption(optionLetter),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: bgColor ?? Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor ?? Colors.grey.shade300),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: isSelected || (answered && isCorrectAnswer)
                                      ? (borderColor ?? const Color(0xFF6366F1))
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    optionLetter,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected || (answered && isCorrectAnswer)
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(optionText, style: TextStyle(fontSize: 14, color: textColor ?? Colors.grey.shade800)),
                              ),
                              if (answered && isCorrectAnswer)
                                const Icon(CupertinoIcons.checkmark_circle, color: Color(0xFF16A34A), size: 20)
                              else if (answered && isSelected && !isCorrect)
                                const Icon(CupertinoIcons.xmark_circle, color: Color(0xFFEA580C), size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  })
                else
                  // Fallback: no options, show simple correct/wrong buttons
                  const SizedBox.shrink(),
                // Answer reveal
                if (answered) ...<Widget>[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isCorrect ? const Color(0xFFBBF7D0) : const Color(0xFFFED7AA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              isCorrect ? CupertinoIcons.checkmark_circle : CupertinoIcons.xmark_circle,
                              color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isCorrect ? '回答正确' : '回答错误',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCorrect ? const Color(0xFF166534) : const Color(0xFF9A3412),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('正确答案：${exercise.answer}', style: TextStyle(fontSize: 15, color: Colors.grey.shade800)),
                        if (exercise.explanation.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(exercise.explanation, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: answered
                  ? FilledButton.icon(
                      onPressed: () {
                        if (isLast) {
                          _finish(current, exercises);
                        } else {
                          setState(() => _index++);
                        }
                      },
                      icon: Icon(isLast ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.arrow_right),
                      label: Text(isLast ? '完成练习' : '下一题'),
                      style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    )
                  : _isJudging
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton.icon(
                          onPressed: exercise.userAnswer != null ? () => _submitAnswer(exercises, _index) : null,
                          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                          icon: const Icon(CupertinoIcons.checkmark),
                          label: const Text('提交答案'),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case '简单': return Colors.green;
      case '中等': return Colors.orange;
      case '困难': return Colors.red;
      case '提高': return const Color(0xFF7C3AED);
      case '同级': return Colors.blue;
      default: return Colors.grey;
    }
  }

  void _selectOption(String optionLetter) {
    setState(() {
      _exercises![_index] = _exercises![_index].copyWith(userAnswer: optionLetter);
    });
  }

  void _submitAnswer(List<GeneratedExercise> exercises, int index) async {
    final exercise = exercises[index];
    if (exercise.userAnswer == null) return;

    setState(() => _isJudging = true);

    // AI 判断答案是否正确
    final isCorrect = await _judgeAnswer(exercise);

    setState(() {
      exercises[index] = exercises[index].copyWith(isCorrect: isCorrect);
      _isJudging = false;
    });
  }

  Future<bool> _judgeAnswer(GeneratedExercise exercise) async {
    // 获取当前题目的上下文用于 AI 判断
    final current = ref.read(currentQuestionProvider);
    if (current?.analysisResult == null) {
      // Fallback: 直接比较答案
      return exercise.userAnswer == exercise.answer;
    }

    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final config = await settingsRepo.getAiProviderConfig();

      if (config == null || config.baseUrl.isEmpty || config.apiKey.isEmpty || config.model.isEmpty) {
        // 没有配置，回退到直接比较
        return exercise.userAnswer == exercise.answer;
      }

      final service = ref.read(aiAnalysisServiceProvider);
      final isCorrect = await service.judgeAnswer(
        question: exercise.question,
        userAnswer: exercise.userAnswer!,
        correctAnswer: exercise.answer,
        options: exercise.options,
      );
      return isCorrect;
    } catch (e) {
      debugPrint('[ExercisePractice] AI judgment failed: $e, fallback to direct compare');
      return exercise.userAnswer == exercise.answer;
    }
  }

  Future<void> _finish(QuestionRecord question, List<GeneratedExercise> exercises) async {
    final updatedAnalysis = question.analysisResult!.copyWith(generatedExercises: exercises);
    final updated = question.copyWith(analysisResult: updatedAnalysis);
    await ref.read(questionRepositoryProvider).update(updated);
    invalidateQuestionList(ref);
    ref.read(currentQuestionProvider.notifier).state = updated;

    if (!mounted) return;
    final correctCount = exercises.where((e) => e.isCorrect == true).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('练习完成：${exercises.length} 题中答对 $correctCount 题')),
    );
    context.go('/notebook');
  }
}