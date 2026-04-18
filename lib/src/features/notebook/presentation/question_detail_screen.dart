import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

class QuestionDetailScreen extends ConsumerWidget {
  const QuestionDetailScreen({super.key, required this.record});

  final dynamic record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = record is QuestionRecord
        ? record as QuestionRecord
        : ref.watch(currentQuestionProvider);

    if (current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('错题详情')),
        body: const Center(child: Text('未找到该错题')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${current.subject.label} 错题详情'),
        actions: <Widget>[
          IconButton(
            icon: Icon(current.isFavorite ? Icons.star : Icons.star_border),
            onPressed: () async {
              final updated = current.copyWith(isFavorite: !current.isFavorite);
              await ref.read(questionRepositoryProvider).update(updated);
              ref.read(currentQuestionProvider.notifier).state = updated;
              invalidateQuestionList(ref);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref, current),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('题目：${current.correctedText}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Text('掌握状态：${current.masteryLevel.name}'),
          Text('复习次数：${current.reviewCount}'),
          const SizedBox(height: 24),
          if (current.analysisResult != null) ...<Widget>[
            Text('答案：${current.analysisResult!.finalAnswer}'),
            const SizedBox(height: 8),
            Text('错因：${current.analysisResult!.mistakeReason}'),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ref.read(currentQuestionProvider.notifier).state = current;
              context.go('/analysis/result');
            },
            child: const Text('查看 AI 解析'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _markReviewed(context, ref, current),
            child: const Text('标记为已复习'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, QuestionRecord question) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，确定要删除这道错题吗？'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              await ref.read(questionRepositoryProvider).delete(question.id);
              invalidateQuestionList(ref);
              if (context.mounted) {
                Navigator.pop(ctx);
                context.go('/notebook');
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _markReviewed(BuildContext context, WidgetRef ref, QuestionRecord question) async {
    final nextLevel = question.masteryLevel == MasteryLevel.newQuestion
        ? MasteryLevel.reviewing
        : MasteryLevel.mastered;
    final updated = question.copyWith(
      masteryLevel: nextLevel,
      reviewCount: question.reviewCount + 1,
    );
    await ref.read(questionRepositoryProvider).update(updated);
    invalidateQuestionList(ref);
    ref.read(currentQuestionProvider.notifier).state = updated;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已标记为${nextLevel == MasteryLevel.mastered ? '已掌握' : '复习中'}')),
    );
  }
}
