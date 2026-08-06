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
        leading: IconButton(
            icon: const Icon(CupertinoIcons.chevron_left),
            onPressed: () => Navigator.of(context).pop()),
      ),
      body: questionsAsync.when(
        data: (questions) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: Subject.selectableValues.length,
          itemBuilder: (context, index) {
            final colorScheme = Theme.of(context).colorScheme;
            final subject = Subject.selectableValues[index];
            final count = questions.where((q) => q.subject == subject).length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: subject.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(subject.icon, size: 18, color: subject.color),
                  ),
                  title: Text(subject.label,
                      style: TextStyle(
                          fontSize: 14, color: colorScheme.onSurface)),
                  trailing: Text(
                    '$count 题',
                    style: TextStyle(
                        fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                ),
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
