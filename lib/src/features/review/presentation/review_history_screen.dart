import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/review_log.dart';

class ReviewHistoryScreen extends ConsumerWidget {
  const ReviewHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(_reviewLogsWithQuestionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('复习记录')),
      body: logsAsync.when(
        data: (entries) => entries.isEmpty
            ? const Center(child: Text('暂无复习记录', style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (_, index) => _buildEntry(context, ref, entries[index], index, entries.length),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildEntry(BuildContext context, WidgetRef ref, _ReviewEntry entry, int index, int total) {
    final isLast = index == total - 1;
    final icon = entry.log.masteryAfter == MasteryLevel.mastered
        ? Icons.check_circle
        : Icons.refresh;

    final color = entry.log.masteryAfter == MasteryLevel.mastered
        ? Colors.green
        : Colors.orange;

    return Column(
      children: <Widget>[
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            entry.question?.correctedText ?? '已删除',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${_formatDate(entry.log.reviewedAt)} · ${entry.log.result == "mastered" ? "已掌握" : entry.log.result == "reviewing" ? "复习中" : "重置"}',
          ),
          trailing: Text(
            '${entry.log.masteryAfter.name}',
            style: TextStyle(color: color, fontSize: 12),
          ),
          onTap: () {
            if (entry.question != null) {
              ref.read(currentQuestionProvider.notifier).state = entry.question;
              context.go('/notebook/question/${entry.question!.id}');
            }
          },
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }
}

class _ReviewEntry {
  const _ReviewEntry({required this.log, this.question});
  final ReviewLog log;
  final QuestionRecord? question;
}

final FutureProvider<List<_ReviewEntry>> _reviewLogsWithQuestionsProvider =
    FutureProvider<List<_ReviewEntry>>((ref) async {
  final logRepo = ref.watch(reviewLogRepositoryProvider);
  final questionRepo = ref.watch(questionRepositoryProvider);
  final logs = await logRepo.listAll();
  final questions = await questionRepo.listAll();
  final questionMap = <String, QuestionRecord>{};
  for (final q in questions) {
    questionMap[q.id] = q;
  }
  logs.sort((a, b) => b.reviewedAt.compareTo(a.reviewedAt));
  return logs.map((log) => _ReviewEntry(log: log, question: questionMap[log.questionRecordId])).toList();
});
