import 'package:flutter/cupertino.dart';
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
      appBar: AppBar(
        title: const Text('复习记录'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.go('/review'),
        ),
      ),
      body: logsAsync.when(
        data: (entries) => entries.isEmpty
            ? _EmptyHistoryCard()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (_, index) => _buildEntry(context, ref, entries[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildEntry(BuildContext context, WidgetRef ref, _ReviewEntry entry) {
    final isMastered = entry.log.masteryAfter == MasteryLevel.mastered;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isMastered ? Colors.green : Colors.orange).withValues(alpha: 0.1),
          child: Icon(
            isMastered ? CupertinoIcons.checkmark_circle : CupertinoIcons.arrow_2_circlepath,
            color: isMastered ? Colors.green : Colors.orange,
            size: 18,
          ),
        ),
        title: Text(
          entry.question?.correctedText ?? '已删除',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_formatDate(entry.log.reviewedAt)} · ${_resultLabel(entry.log.result)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Chip(
          label: Text(_masteryLabel(entry.log.masteryAfter)),
          backgroundColor: (isMastered ? Colors.green : Colors.orange).withValues(alpha: 0.1),
          labelStyle: TextStyle(
            fontSize: 11,
            color: isMastered ? Colors.green : Colors.orange,
          ),
          visualDensity: VisualDensity.compact,
        ),
        onTap: entry.question != null
            ? () {
                ref.read(currentQuestionProvider.notifier).state = entry.question;
                context.go('/notebook/question/${entry.question!.id}');
              }
            : null,
      ),
    );
  }

  String _resultLabel(String result) {
    switch (result) {
      case 'mastered': return '已掌握';
      case 'reviewing': return '复习中';
      case 'reset': return '重置';
      default: return result;
    }
  }

  String _masteryLabel(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.newQuestion: return '未复习';
      case MasteryLevel.reviewing: return '复习中';
      case MasteryLevel.mastered: return '已掌握';
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return '今天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return '昨天';
    return '${dt.month}/${dt.day}';
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(CupertinoIcons.clock, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('暂无复习记录', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              '开始复习后在首页查看历史',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
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
