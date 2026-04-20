import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
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
          // Progress
          LinearProgressIndicator(
            value: answeredCount / exercises.length,
            backgroundColor: Colors.grey.shade200,
            minHeight: 3,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                // Meta row
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
                const SizedBox(height: 16),
                // Answer reveal
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: answered ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
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
                        Text('答案：${exercise.answer}', style: TextStyle(fontSize: 15, color: Colors.grey.shade800)),
                        if (exercise.explanation.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(exercise.explanation, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom action
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
                  : Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _markResult(exercises, _index, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              minimumSize: const Size(0, 48),
                            ),
                            icon: const Icon(CupertinoIcons.xmark),
                            label: const Text('做错了'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _markResult(exercises, _index, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              minimumSize: const Size(0, 48),
                            ),
                            icon: const Icon(CupertinoIcons.checkmark),
                            label: const Text('做对了'),
                          ),
                        ),
                      ],
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

  void _markResult(List<GeneratedExercise> exercises, int index, bool correct) {
    setState(() {
      exercises[index] = exercises[index].copyWith(isCorrect: correct);
    });
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
