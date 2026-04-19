import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/features/review/presentation/review_controller.dart';

class QuestionDetailScreen extends ConsumerWidget {
  const QuestionDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentQuestionProvider);

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
          if (File(current.imagePath).existsSync())
            GestureDetector(
              onTap: () => _showFullScreenImage(context, current.imagePath),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(current.imagePath),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          const SizedBox(height: 16),
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
          if (current.analysisResult != null)
            FilledButton.tonal(
              onPressed: () {
                ref.read(currentQuestionProvider.notifier).state = current;
                context.go('/analysis/result');
              },
              child: const Text('查看 AI 解析'),
            ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _markResult(context, ref, current, false),
                  child: const Text('仍需复习'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _markResult(context, ref, current, true),
                  child: const Text('已掌握'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(imagePath)),
            ),
          ),
        ),
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

  void _markResult(BuildContext context, WidgetRef ref, QuestionRecord question, bool mastered) async {
    final controller = ReviewController(repository: ref.read(questionRepositoryProvider));
    final updated = mastered
        ? await controller.markMastered(question.id)
        : await controller.markReviewing(question.id);
    invalidateQuestionList(ref);
    ref.read(currentQuestionProvider.notifier).state = updated;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mastered ? '已标记为已掌握' : '已标记为复习中')),
    );
  }
}
