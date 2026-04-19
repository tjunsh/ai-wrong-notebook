import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

class NotebookScreen extends ConsumerStatefulWidget {
  const NotebookScreen({super.key});

  @override
  ConsumerState<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends ConsumerState<NotebookScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic question) {
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
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(filteredQuestionListProvider);
    final selectedSubject = ref.watch(selectedSubjectFilterProvider);
    final selectedMastery = ref.watch(selectedMasteryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('错题本'),
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: () => context.go('/capture/correction'),
            tooltip: '添加错题',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索错题',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              onChanged: (v) {
                ref.read(searchQueryProvider.notifier).state = v;
                setState(() {});
              },
            ),
          ),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: <Widget>[
                _Chip(
                  label: '全部',
                  selected: selectedSubject == null && selectedMastery == null,
                  onTap: () {
                    ref.read(selectedSubjectFilterProvider.notifier).state = null;
                    ref.read(selectedMasteryFilterProvider.notifier).state = null;
                  },
                ),
                const SizedBox(width: 8),
                ...Subject.values.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _Chip(
                    label: s.label,
                    selected: selectedSubject == s,
                    onTap: () {
                      ref.read(selectedSubjectFilterProvider.notifier).state = selectedSubject == s ? null : s;
                    },
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: questionsAsync.when(
              data: (questions) {
                if (questions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.quiz_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('暂无错题', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('点击 + 拍照添加', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(questionListProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      return RepaintBoundary(
                        child: _QuestionCard(
                          question: q,
                          onTap: () {
                            ref.read(currentQuestionProvider.notifier).state = q;
                            context.go('/notebook/question/${q.id}');
                          },
                          onDelete: () => _confirmDelete(context, ref, q),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.onTap, required this.onDelete});

  final dynamic question;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final masteryColor = _masteryColor(question.masteryLevel);
    final subjectIcon = _subjectIcon(question.subject);

    return Dismissible(
      key: ValueKey(question.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      child: Semantics(
        button: true,
        label: '错题: ${question.correctedText}，科目: ${question.subject.label}，状态: ${_masteryLabel(question.masteryLevel)}，日期: ${_formatDate(question.createdAt)}，左滑删除',
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: subjectIcon.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Hero(
                      tag: 'subject_icon_${question.id}',
                      child: Icon(subjectIcon.icon, size: 20, color: subjectIcon.color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Hero(
                          tag: 'question_text_${question.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              question.correctedText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Text(
                              '${question.subject.label} · ${_formatDate(question.createdAt)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: masteryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _masteryLabel(question.masteryLevel),
                                style: TextStyle(fontSize: 11, color: masteryColor, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${date.month}月${date.day}日';
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

  ({IconData icon, Color color}) _subjectIcon(Subject subject) {
    switch (subject) {
      case Subject.math: return (icon: Icons.functions, color: const Color(0xFF6366F1));
      case Subject.english: return (icon: Icons.translate, color: const Color(0xFFD97706));
      case Subject.chinese: return (icon: Icons.article_outlined, color: const Color(0xFF16A34A));
      case Subject.physics: return (icon: Icons.science, color: const Color(0xFFEA580C));
      case Subject.chemistry: return (icon: Icons.biotech, color: const Color(0xFF7C3AED));
      case Subject.biology: return (icon: Icons.eco, color: const Color(0xFF16A34A));
      case Subject.history: return (icon: Icons.history_edu, color: const Color(0xFFD97706));
      case Subject.geography: return (icon: Icons.public, color: const Color(0xFF6366F1));
      case Subject.politics: return (icon: Icons.account_balance, color: const Color(0xFF7C3AED));
      case Subject.science: return (icon: Icons.science, color: const Color(0xFFEA580C));
      case Subject.custom: return (icon: Icons.quiz_outlined, color: Colors.grey);
    }
  }
}
