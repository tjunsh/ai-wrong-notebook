import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

class SubjectManagementScreen extends ConsumerWidget {
  const SubjectManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('科目管理'),
        leading: IconButton(icon: const Icon(CupertinoIcons.chevron_left), onPressed: () => Navigator.of(context).pop()),
      ),
      body: questionsAsync.when(
        data: (questions) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: Subject.values.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final subject = Subject.values[index];
            final count = questions.where((q) => q.subject == subject).length;
            return ListTile(
              leading: const Icon(CupertinoIcons.book),
              title: Text(subject.label),
              trailing: Text(
                '$count 题',
                style: TextStyle(color: count > 0 ? Colors.grey.shade600 : Colors.grey.shade400),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }
}
