import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/common/widgets/stats_chart.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/features/capture/presentation/capture_entry_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionListProvider);
    final dueAsync = ref.watch(dueReviewProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: <Widget>[
          Text(
            '开始拍错题',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const CaptureEntrySheet(),
            ),
            icon: const Icon(CupertinoIcons.camera),
            label: const Text('拍照录题'),
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
          ),
          const SizedBox(height: 20),
          dueAsync.when(
            data: (due) => due.isNotEmpty
                ? _ReviewBanner(count: due.length, onTap: () => context.go('/review'))
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          Text('学习统计', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          RepaintBoundary(
            child: questionsAsync.when(
              data: (questions) => _buildStatsSection(context, questions, dueAsync),
              loading: () => const _StatsGridSkeleton(),
              error: (e, _) => Text('加载失败: $e'),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('最近新增', style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                onPressed: () => context.go('/notebook'),
                child: const Text('查看全部'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          questionsAsync.when(
            data: (questions) => _RecentList(questions: questions.take(5).toList(), ref: ref),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('加载失败: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, List<QuestionRecord> questions, AsyncValue<List<QuestionRecord>> dueAsync) {
    final total = questions.length;
    final mastered = questions.where((q) => q.masteryLevel == MasteryLevel.mastered).length;
    final reviewing = questions.where((q) => q.masteryLevel == MasteryLevel.reviewing).length;
    final newQ = questions.where((q) => q.masteryLevel == MasteryLevel.newQuestion).length;
    final due = dueAsync.valueOrNull?.length ?? 0;

    return Column(
      children: <Widget>[
        StatsGrid(total: total, mastered: mastered, reviewing: reviewing, newQ: newQ, due: due),
        if (total > 0) ...<Widget>[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('掌握进度', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                const SizedBox(height: 12),
                StatsBarChart(total: total, mastered: mastered, reviewing: reviewing, newQ: newQ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatsGridSkeleton extends StatelessWidget {
  const _StatsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _StatCardSkeleton()),
            SizedBox(width: 12, height: 70),
            Expanded(child: _StatCardSkeleton()),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(child: _StatCardSkeleton()),
            SizedBox(width: 12, height: 70),
            Expanded(child: _StatCardSkeleton()),
          ],
        ),
      ],
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.questions, required this.ref});

  final List<QuestionRecord> questions;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Column(
          children: <Widget>[
            Icon(CupertinoIcons.question, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('暂无错题，拍照开始添加', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return Column(
      children: List.generate(questions.length, (index) {
        final q = questions[index];
        return _RecentQuestionCard(
          key: ValueKey(q.id),
          question: q,
          onTap: () {
            ref.read(currentQuestionProvider.notifier).state = q;
            context.go('/notebook/question/${q.id}');
          },
        );
      }),
    );
  }
}

class _RecentQuestionCard extends StatelessWidget {
  const _RecentQuestionCard({super.key, required this.question, required this.onTap});

  final QuestionRecord question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final masteryColor = _masteryColor(question.masteryLevel);
    return Semantics(
      button: true,
      label: '错题: ${question.correctedText}，科目: ${question.subject.label}，状态: ${_masteryLabel(question.masteryLevel)}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: masteryColor.withValues(alpha: 0.1),
              child: Icon(CupertinoIcons.question, size: 16, color: masteryColor),
            ),
            title: Text(
              question.correctedText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(question.subject.label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            trailing: const Icon(CupertinoIcons.chevron_right, color: Colors.grey),
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  Color _masteryColor(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.newQuestion: return Colors.grey;
      case MasteryLevel.reviewing: return Colors.orange;
      case MasteryLevel.mastered: return Colors.green;
    }
  }

  String _masteryLabel(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.newQuestion: return '新增';
      case MasteryLevel.reviewing: return '复习中';
      case MasteryLevel.mastered: return '已掌握';
    }
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '今日待复习 $count 道错题，点击进入复习',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFFFFEDD5), borderRadius: BorderRadius.circular(22)),
                child: const Icon(CupertinoIcons.arrow_2_circlepath, color: Color(0xFFF97316), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('今日待复习', style: Theme.of(context).textTheme.titleMedium),
                    Text('$count 道错题等待巩固', style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_right, color: Color(0xFFF97316), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
