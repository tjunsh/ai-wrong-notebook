import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/features/capture/presentation/capture_entry_sheet.dart';
import 'package:smart_wrong_notebook/src/shared/widgets/math_content_view.dart';

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
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
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
    final colorScheme = Theme.of(context).colorScheme;
    final questionsAsync = ref.watch(filteredQuestionListProvider);
    final selectedSubject = ref.watch(selectedSubjectFilterProvider);
    final selectedMastery = ref.watch(selectedMasteryFilterProvider);
    final selectedCreatedToday = ref.watch(selectedCreatedTodayFilterProvider);
    final selectedKnowledgePoint =
        ref.watch(selectedKnowledgePointFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('错题本'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.camera),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const CaptureEntrySheet(),
            ),
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
                prefixIcon: const Icon(CupertinoIcons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
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
                  selected: selectedSubject == null &&
                      selectedMastery == null &&
                      !selectedCreatedToday &&
                      selectedKnowledgePoint == null,
                  onTap: () {
                    ref.read(selectedSubjectFilterProvider.notifier).state =
                        null;
                    ref.read(selectedMasteryFilterProvider.notifier).state =
                        null;
                    ref
                        .read(selectedCreatedTodayFilterProvider.notifier)
                        .state = false;
                    ref
                        .read(selectedKnowledgePointFilterProvider.notifier)
                        .state = null;
                  },
                ),
                const SizedBox(width: 8),
                if (selectedCreatedToday) ...<Widget>[
                  _Chip(
                    label: '今日新增',
                    selected: true,
                    onTap: () {
                      ref
                          .read(selectedCreatedTodayFilterProvider.notifier)
                          .state = false;
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                if (selectedMastery != null) ...<Widget>[
                  _Chip(
                    label: _masteryFilterLabel(selectedMastery),
                    selected: true,
                    onTap: () {
                      ref.read(selectedMasteryFilterProvider.notifier).state =
                          null;
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                ...Subject.selectableValues.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _Chip(
                        label: s.label,
                        selected: selectedSubject == s,
                        onTap: () {
                          ref
                              .read(selectedSubjectFilterProvider.notifier)
                              .state = selectedSubject == s ? null : s;
                        },
                      ),
                    )),
                // AI 知识点过滤
                if (selectedKnowledgePoint != null) ...<Widget>[
                  const SizedBox(width: 8),
                  _Chip(
                    label: '📚 $selectedKnowledgePoint',
                    selected: true,
                    onTap: () {
                      ref
                          .read(selectedKnowledgePointFilterProvider.notifier)
                          .state = null;
                    },
                  ),
                ],
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
                        Icon(CupertinoIcons.question,
                            size: 64,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.45)),
                        const SizedBox(height: 16),
                        Text('暂无错题',
                            style: TextStyle(
                                fontSize: 16, color: colorScheme.onSurface)),
                        const SizedBox(height: 8),
                        Text('点击 + 拍照添加',
                            style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(questionListProvider);
                  },
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      return RepaintBoundary(
                        child: _QuestionCard(
                          question: q,
                          onTap: () {
                            ref.read(currentQuestionProvider.notifier).state =
                                q;
                            context.go('/notebook/question/${q.id}');
                          },
                          onDelete: () => _confirmDelete(context, ref, q),
                          onKnowledgePointTap: (kp) {
                            ref
                                .read(selectedKnowledgePointFilterProvider
                                    .notifier)
                                .state = kp;
                          },
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

String _masteryFilterLabel(MasteryLevel level) {
  return switch (level) {
    MasteryLevel.newQuestion => '新题',
    MasteryLevel.reviewing => '复习中',
    MasteryLevel.mastered => '已掌握',
  };
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color:
                selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.onTap,
    required this.onDelete,
    required this.onKnowledgePointTap,
  });

  final dynamic question;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(String knowledgePoint) onKnowledgePointTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final masteryColor = _masteryColor(context, question.masteryLevel);
    final aiTags = question.aiTags ?? <String>[];
    final customTags = question.customTags ?? <String>[];
    final allTags = [...aiTags, ...customTags];

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
          color:
              isDark ? Colors.red.withValues(alpha: 0.14) : Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(CupertinoIcons.trash, color: Colors.red),
      ),
      child: Semantics(
        button: true,
        label:
            '错题: ${question.correctedText}，科目: ${question.subject.label}，状态: ${_masteryLabel(question.masteryLevel)}，日期: ${_formatDate(question.createdAt)}，左滑删除',
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: question.subject.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Hero(
                      tag: 'subject_icon_${question.id}',
                      child: Icon(question.subject.icon,
                          size: 20, color: question.subject.color),
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
                            child: MathContentView(
                              question.correctedText,
                              contentFormat: question.contentFormat,
                              mode: MathContentViewMode.compact,
                              maxLines: 1,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Text(
                              '${question.subject.label} · ${_formatDate(question.createdAt)}',
                              style: TextStyle(
                                  fontSize: 12, color: question.subject.color),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: masteryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _masteryLabel(question.masteryLevel),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: masteryColor,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        if (_batchLabel(question) != null) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            _batchLabel(question)!,
                            style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                        // AI 知识点标签（有颜色区分 AI 生成和手动）
                        if (allTags.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: allTags.take(5).map((tag) {
                              final isAiTag = aiTags.contains(tag);
                              final tagColor = isAiTag
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF4F46E5);
                              final tagBackground = isDark
                                  ? tagColor.withValues(alpha: 0.14)
                                  : isAiTag
                                      ? const Color(0xFFFFF7ED)
                                      : const Color(0xFFEEF2FF);
                              return GestureDetector(
                                onTap: () => onKnowledgePointTap(tag),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tagBackground,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDark
                                          ? tagColor.withValues(alpha: 0.22)
                                          : colorScheme.outlineVariant
                                              .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: MathContentView(
                                    tag,
                                    mode: MathContentViewMode.compact,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark
                                          ? colorScheme.onSurface
                                          : tagColor,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(CupertinoIcons.chevron_right,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                      size: 22),
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

  Color _masteryColor(BuildContext context, MasteryLevel level) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (level) {
      case MasteryLevel.newQuestion:
        return colorScheme.onSurfaceVariant;
      case MasteryLevel.reviewing:
        return const Color(0xFFD97706);
      case MasteryLevel.mastered:
        return const Color(0xFF16A34A);
    }
  }

  String _masteryLabel(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.newQuestion:
        return '新增';
      case MasteryLevel.reviewing:
        return '复习中';
      case MasteryLevel.mastered:
        return '已掌握';
    }
  }

  String? _batchLabel(QuestionRecord question) {
    if (question.parentQuestionId == null && question.rootQuestionId == null) {
      return null;
    }
    final order = question.splitOrder;
    return order == null ? '来自同一拍照批次' : '来自同一拍照批次 · 第 $order 题';
  }
}
