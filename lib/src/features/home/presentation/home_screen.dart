import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/features/capture/presentation/capture_entry_sheet.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionListProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('开始拍错题', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              builder: (_) => const CaptureEntrySheet(),
            );
          },
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('拍照录题'),
        ),
        const SizedBox(height: 24),
        Text('最近新增', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        questionsAsync.when(
          data: (questions) => _buildRecentList(context, ref, questions),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('加载失败: $e'),
        ),
      ],
    );
  }

  Widget _buildRecentList(BuildContext context, WidgetRef ref, List<QuestionRecord> questions) {
    if (questions.isEmpty) {
      return const Text('暂无错题，拍照开始添加', style: TextStyle(color: Colors.grey));
    }
    return Column(
      children: questions.take(5).map((q) {
        return Card(
          child: ListTile(
            title: Text(q.correctedText, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(q.subject.label),
            trailing: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                ref.read(currentQuestionProvider.notifier).state = q;
                context.go('/notebook');
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}
