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
    final questionsAsync = ref.watch(questionListProvider);
    final dueAsync = ref.watch(dueReviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('复习')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // Summary card
          questionsAsync.when(
            data: (questions) => _buildSummaryCard(context, questions),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          // Today review section
          Text('今日待复习', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          dueAsync.when(
            data: (questions) {
              if (questions.isEmpty) {
                return _EmptyReviewCard();
              }
              return Column(
                children: <Widget>[
                  _TodayBanner(count: questions.length),
                  const SizedBox(height: 12),
                  ...questions.map((q) => _buildReviewCard(context, ref, q)),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败: $e')),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('复习记录'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/review/history'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<QuestionRecord> questions) {
    final mastered = questions.where((q) => q.masteryLevel == MasteryLevel.mastered).length;
    final reviewing = questions.where((q) => q.masteryLevel == MasteryLevel.reviewing).length;
    final newQ = questions.where((q) => q.masteryLevel == MasteryLevel.newQuestion).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('整体进度', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text('共 ${questions.length} 题', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                _progressItem(context, mastered, '已掌握', Colors.green),
                const SizedBox(width: 16),
                _progressItem(context, reviewing, '复习中', Colors.orange),
                const SizedBox(width: 16),
                _progressItem(context, newQ, '新增', Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressItem(BuildContext context, int count, String label, Color color) {
    return Column(
      children: <Widget>[
        Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context, WidgetRef ref, QuestionRecord question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _masteryColor(question.masteryLevel).withOpacity(0.1),
          child: Icon(Icons.quiz_outlined, color: _masteryColor(question.masteryLevel), size: 18),
        ),
        title: Text(
          question.correctedText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${question.subject.label} · ${_masteryLabel(question.masteryLevel)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          ref.read(currentQuestionProvider.notifier).state = question;
          context.go('/notebook/question/${question.id}');
        },
      ),
    );
  }

  String _masteryLabel(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.newQuestion: return '未复习';
      case MasteryLevel.reviewing: return '复习中';
      case MasteryLevel.mastered: return '已掌握';
    }
  }

  Color _masteryColor(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.newQuestion: return Colors.grey;
      case MasteryLevel.reviewing: return Colors.orange;
      case MasteryLevel.mastered: return Colors.green;
    }
  }
}

class _TodayBanner extends StatelessWidget {
  const _TodayBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              radius: 16,
              child: const Icon(Icons.refresh, color: Colors.orange, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$count 道错题等待复习',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Icon(Icons.celebration, size: 48, color: Colors.green.shade300),
            const SizedBox(height: 8),
            const Text('太棒了！', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('暂无待复习错题', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
