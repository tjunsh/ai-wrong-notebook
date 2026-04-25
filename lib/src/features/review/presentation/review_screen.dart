import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionListProvider);
    final dueAsync = ref.watch(dueReviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('复习')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          // Summary card
          questionsAsync.when(
            data: (questions) => _SummaryCard(total: questions.length, mastered: questions.where((q) => q.masteryLevel == MasteryLevel.mastered).length, reviewing: questions.where((q) => q.masteryLevel == MasteryLevel.reviewing).length),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          // Today section
          Row(
            children: <Widget>[
              Text('今日待复习', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              dueAsync.when(
                data: (questions) => Text('${questions.length}道错题等待巩固', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          dueAsync.when(
            data: (questions) {
              if (questions.isEmpty) return _EmptyCard();
              return Column(
                children: questions.map((q) => _ReviewCard(question: q, ref: ref)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败: $e')),
          ),
          const SizedBox(height: 24),
          // History row
          GestureDetector(
            onTap: () => context.go('/review/history'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: <Widget>[
                  Icon(CupertinoIcons.clock, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('复习记录', style: TextStyle(fontSize: 15))),
                  Icon(CupertinoIcons.chevron_right, size: 22, color: Colors.grey.shade300),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total, required this.mastered, required this.reviewing});

  final int total;
  final int mastered;
  final int reviewing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('整体进度', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('共 $total 题', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _MiniStat(value: '$mastered', label: '已掌握', color: Colors.green),
              _MiniStat(value: '$reviewing', label: '复习中', color: Colors.orange),
              _MiniStat(value: '${total - mastered - reviewing}', label: '新增', color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        children: <Widget>[
          Icon(CupertinoIcons.star, size: 48, color: Colors.green.shade300),
          const SizedBox(height: 12),
          const Text('太棒了！', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('暂无待复习错题', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.question, required this.ref});

  final QuestionRecord question;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          ref.read(currentQuestionProvider.notifier).state = question;
          context.go('/notebook/question/${question.id}');
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: question.subject.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(question.subject.icon, size: 18, color: question.subject.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      question.correctedText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Text(
                          question.subject.label,
                          style: TextStyle(fontSize: 12, color: question.subject.color),
                        ),
                        if (question.aiTags.isNotEmpty) ...<Widget>[
                          const SizedBox(width: 8),
                          ...question.aiTags.take(3).map((tag) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(tag, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                          )),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right, color: Colors.grey.shade300, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
