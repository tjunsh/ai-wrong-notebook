import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueAsync = ref.watch(dueReviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('复习')),
      body: dueAsync.when(
        data: (questions) => ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text('今日待复习', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (questions.isEmpty)
              const Text('暂无待复习错题', style: TextStyle(color: Colors.grey))
            else
              ...questions.map((q) => Card(
                child: ListTile(
                  leading: const Icon(Icons.quiz_outlined),
                  title: Text(
                    q.correctedText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${q.subject.label} · ${_masteryLabel(q.masteryLevel)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _startReview(context, ref, q),
                ),
              )),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('复习记录'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/review/history'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  String _masteryLabel(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.newQuestion:
        return '未复习';
      case MasteryLevel.reviewing:
        return '复习中';
      case MasteryLevel.mastered:
        return '已掌握';
    }
  }

  void _startReview(BuildContext context, WidgetRef ref, QuestionRecord question) {
    ref.read(currentQuestionProvider.notifier).state = question;
    context.go('/notebook/question/${question.id}');
  }
}
