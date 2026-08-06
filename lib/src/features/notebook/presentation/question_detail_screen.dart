import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_conversation_message.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/services/exercise_round_service.dart';
import 'package:smart_wrong_notebook/src/features/review/presentation/review_controller.dart';
import 'package:smart_wrong_notebook/src/shared/widgets/math_content_view.dart';

final _exerciseGenerationJobProvider =
    StreamProvider.autoDispose.family<AnalysisJob?, String>((ref, questionId) {
  final repository = ref.watch(analysisJobRepositoryProvider);
  if (repository == null) return Stream<AnalysisJob?>.value(null);
  return repository.watchByParentQuestionId(questionId).map((jobs) {
    final exerciseJobs = jobs
        .where((job) => job.taskSpec.type == AiTaskType.exerciseGeneration)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return exerciseJobs.isEmpty ? null : exerciseJobs.first;
  });
});

class QuestionDetailScreen extends ConsumerWidget {
  const QuestionDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentQuestionProvider);

    if (current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('错题详情')),
        body: const Center(child: Text('未找到该错题')),
      );
    }

    final result = current.analysisResult;
    final masteryColor = _masteryColor(context, current.masteryLevel);
    final batchGroups = ref.watch(questionBatchGroupsProvider).valueOrNull;
    final batchGroup = batchGroups?[questionBatchRootId(current)];
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('错题详情'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.go('/notebook'),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(CupertinoIcons.pencil),
            onPressed: () => _editQuestion(context, ref, current),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _confirmDelete(context, ref, current);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(CupertinoIcons.trash, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          // 统一标签分类框：科目 | AI识别 | 状态
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 第一行：科目 + AI识别 + 状态
                Row(
                  children: <Widget>[
                    _TagChip(
                      label: current.subject.label,
                      bgColor: const Color(0xFFEEF2FF),
                      textColor: const Color(0xFF4F46E5),
                    ),
                    if (result?.subject != null) ...<Widget>[
                      const SizedBox(width: 8),
                      const _TagChip(
                        label: 'AI识别',
                        bgColor: Color(0xFFF0FDF4),
                        textColor: Color(0xFF16A34A),
                      ),
                    ],
                    const SizedBox(width: 8),
                    _TagChip(
                      label: _masteryLabel(current.masteryLevel),
                      bgColor: masteryColor.withValues(alpha: 0.1),
                      textColor: masteryColor,
                    ),
                    if (_batchLabel(current) != null) ...<Widget>[
                      const SizedBox(width: 8),
                      _TagChip(
                        label: _batchLabel(current)!,
                        bgColor: const Color(0xFFF8FAFC),
                        textColor: const Color(0xFF64748B),
                      ),
                    ],
                  ],
                ),
                // AI 短标签（橙色）
                if (current.aiTags.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Text('AI标签',
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: current.aiTags
                        .map((tag) => _TagChip(
                              label: tag,
                              bgColor: const Color(0xFFFFF7ED),
                              textColor: const Color(0xFFD97706),
                            ))
                        .toList(),
                  ),
                ],
                // 自定义标签（蓝色）
                if (current.customTags.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text('自定义标签',
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: current.customTags
                        .map((t) => _TagChip(
                              label: t,
                              bgColor: const Color(0xFFEEF2FF),
                              textColor: const Color(0xFF4F46E5),
                            ))
                        .toList(),
                  ),
                ],
                // 添加标签按钮
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showAddTagDialog(context, ref, current),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.5),
                          style: BorderStyle.solid),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(CupertinoIcons.plus,
                            size: 14,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('添加标签',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (batchGroup != null) ...<Widget>[
            const SizedBox(height: 12),
            _BatchSiblingCard(
              current: current,
              group: batchGroup,
              onSelect: (question) {
                ref.read(currentQuestionProvider.notifier).state = question;
                context.go('/notebook/question/${question.id}');
              },
            ),
          ],
          if (result == null) ...<Widget>[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Column(
                children: <Widget>[
                  Icon(CupertinoIcons.sparkles,
                      size: 40,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  const Text('暂无 AI 解析结果', style: TextStyle(fontSize: 15)),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(currentQuestionProvider.notifier).state =
                          current;
                      context.go('/capture/correction');
                    },
                    icon: const Icon(CupertinoIcons.camera),
                    label: const Text('去添加'),
                  ),
                ],
              ),
            ),
          ],
          if (result != null) ...<Widget>[
            const SizedBox(height: 16),
            // 原题（包含图片和文本）
            _InfoCard(
              icon: CupertinoIcons.doc_text,
              iconColor: const Color(0xFF6366F1),
              bg: const Color(0xFFEEF2FF),
              border: const Color(0xFFC7D2FE),
              title: '原题',
              titleColor: const Color(0xFF4338CA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 图片预览
                  if (current.imagePath.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showFullImage(context, current.imagePath),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(current.imagePath),
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(CupertinoIcons.photo,
                                          size: 30,
                                          color: colorScheme.onSurfaceVariant),
                                      const SizedBox(height: 4),
                                      Text('图片加载失败',
                                          style: TextStyle(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                              fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.58),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(CupertinoIcons.zoom_in,
                                        size: 12, color: Colors.white),
                                    SizedBox(width: 3),
                                    Text('查看原图',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (current.imagePath.isNotEmpty) const SizedBox(height: 10),
                  MathContentView(
                    current.correctedText,
                    contentFormat: current.contentFormat,
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Answer
            _InfoCard(
              icon: result.visualAssumptionStatus ==
                      VisualAssumptionStatus.needsReview
                  ? CupertinoIcons.exclamationmark_triangle
                  : CupertinoIcons.checkmark_circle,
              iconColor: result.visualAssumptionStatus ==
                      VisualAssumptionStatus.needsReview
                  ? const Color(0xFFEA580C)
                  : const Color(0xFF16A34A),
              bg: result.visualAssumptionStatus ==
                      VisualAssumptionStatus.needsReview
                  ? const Color(0xFFFFF7ED)
                  : const Color(0xFFF0FDF4),
              border: result.visualAssumptionStatus ==
                      VisualAssumptionStatus.needsReview
                  ? const Color(0xFFFED7AA)
                  : const Color(0xFFBBF7D0),
              title: result.visualAssumptionStatus ==
                      VisualAssumptionStatus.needsReview
                  ? '可能解法'
                  : '正确答案',
              titleColor: result.visualAssumptionStatus ==
                      VisualAssumptionStatus.needsReview
                  ? const Color(0xFF9A3412)
                  : const Color(0xFF166534),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MathContentView(
                    result.finalAnswer,
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? colorScheme.onSurface
                            : const Color(0xFF15803D),
                        fontWeight: FontWeight.w600),
                  ),
                  if (_consistencyNotice(result) != null) ...<Widget>[
                    const SizedBox(height: 10),
                    _ConsistencyNotice(
                      notice: _consistencyNotice(result)!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Mistake reason
            _InfoCard(
              icon: CupertinoIcons.exclamationmark_triangle,
              iconColor: const Color(0xFFEA580C),
              bg: const Color(0xFFFFF7ED),
              border: const Color(0xFFFED7AA),
              title: '错因分析',
              titleColor: const Color(0xFF9A3412),
              child: MathContentView(
                result.mistakeReason,
                style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? colorScheme.onSurface
                        : const Color(0xFFC2410C),
                    height: 1.5),
              ),
            ),
            const SizedBox(height: 10),
            // Study advice
            _InfoCard(
              icon: CupertinoIcons.lightbulb,
              iconColor: const Color(0xFFD97706),
              bg: const Color(0xFFFFFBEB),
              border: const Color(0xFFFDE68A),
              title: '学习建议',
              titleColor: const Color(0xFF92400E),
              child: MathContentView(
                result.studyAdvice,
                style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? colorScheme.onSurface
                        : const Color(0xFFB45309),
                    height: 1.5),
              ),
            ),
            // Knowledge points
            if (result.knowledgePoints.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Text('知识点',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: result.knowledgePoints
                    .map((p) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.surface
                                : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? colorScheme.outlineVariant
                                  : const Color(0xFFC7D2FE),
                            ),
                          ),
                          child: MathContentView(
                            p,
                            style: TextStyle(
                                fontSize: 12,
                                height: 1.45,
                                color: isDark
                                    ? colorScheme.onSurface
                                    : const Color(0xFF4F46E5)),
                          ),
                        ))
                    .toList(),
              ),
            ],
            // Steps
            if (result.steps.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Text('解题步骤',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ...result.steps.asMap().entries.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surface
                          : const Color(0xFFFAFAFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? colorScheme.outlineVariant
                            : const Color(0xFFE0E7FF),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.primary.withValues(alpha: 0.14)
                                : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                              child: Text('${e.key + 1}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? colorScheme.primary
                                          : const Color(0xFF4F46E5)))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: MathContentView(e.value,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurface,
                                    height: 1.5))),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 24),
            _AskAiCard(current: current),
            const SizedBox(height: 16),
            _PracticeSummaryCard(current: current),
            const SizedBox(height: 16),
            _MasteryActions(
              current: current,
              onMarkReviewing: () => _markResult(context, ref, current, false),
              onMarkMastered: () => _markResult(context, ref, current, true),
            ),
          ],
        ],
      ),
    );
  }

  _ConsistencyNoticeData? _consistencyNotice(AnalysisResult result) {
    switch (result.consistencyStatus) {
      case AnalysisConsistencyStatus.repaired:
        if (result.visualAssumptionStatus ==
            VisualAssumptionStatus.needsReview) {
          return _ConsistencyNoticeData(
            text: result.consistencyNote.isNotEmpty
                ? result.consistencyNote
                : 'AI 已复核答案；图中关键标注含义仍需核对',
            icon: CupertinoIcons.exclamationmark_triangle,
            color: const Color(0xFFEA580C),
            background: const Color(0xFFFFF7ED),
          );
        }
        return const _ConsistencyNoticeData(
          text: 'AI 已复核并修正答案',
          icon: CupertinoIcons.checkmark_shield,
          color: Color(0xFF16A34A),
          background: Color(0xFFEFFDF5),
        );
      case AnalysisConsistencyStatus.needsReview:
        if (result.visualAssumptionStatus ==
            VisualAssumptionStatus.needsReview) {
          return _ConsistencyNoticeData(
            text: result.consistencyNote.isNotEmpty
                ? result.consistencyNote
                : '图中关键标注含义需核对，当前为可能解法',
            icon: CupertinoIcons.exclamationmark_triangle,
            color: const Color(0xFFEA580C),
            background: const Color(0xFFFFF7ED),
          );
        }
        return const _ConsistencyNoticeData(
          text: '答案与步骤可能不一致，请核对',
          icon: CupertinoIcons.exclamationmark_triangle,
          color: Color(0xFFEA580C),
          background: Color(0xFFFFF7ED),
        );
      case AnalysisConsistencyStatus.unchecked:
      case AnalysisConsistencyStatus.consistent:
      case AnalysisConsistencyStatus.unverifiable:
        return null;
    }
  }

  String _masteryLabel(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.newQuestion:
        return '待复习';
      case MasteryLevel.reviewing:
        return '待复习';
      case MasteryLevel.mastered:
        return '已掌握';
    }
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

  String? _batchLabel(QuestionRecord question) {
    if (question.parentQuestionId == null && question.rootQuestionId == null) {
      return null;
    }
    final order = question.splitOrder;
    return order == null ? '拍照批次' : '拍照批次 · 第 $order 题';
  }

  void _editQuestion(
      BuildContext context, WidgetRef ref, QuestionRecord question) {
    final controller = TextEditingController(text: question.correctedText);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑题目'),
        content: TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final updated = question.copyWith(
                  normalizedQuestionText: controller.text.trim());
              await ref.read(questionRepositoryProvider).update(updated);
              ref.read(currentQuestionProvider.notifier).state = updated;
              invalidateQuestionList(ref);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, QuestionRecord question) {
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
              if (context.mounted) context.go('/notebook');
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog(
      BuildContext context, WidgetRef ref, QuestionRecord question) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加标签'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '输入标签名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text('已有标签',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ...question.aiTags
                    .map((tag) => _dialogTagChip(tag, Colors.orange)),
                ...question.aiKnowledgePoints
                    .map((kp) => _dialogTagChip(kp, Colors.orange)),
                ...question.customTags
                    .map((t) => _dialogTagChip(t, Colors.indigo)),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final tag = controller.text.trim();
              if (tag.isEmpty) return;

              // 检查是否已存在（去重）
              final allTags = [
                ...question.aiTags,
                ...question.aiKnowledgePoints,
                ...question.customTags
              ];
              if (allTags.contains(tag)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('标签已存在')),
                );
                return;
              }

              final newTags = [...question.customTags, tag];
              final updated = question.copyWith(customTags: newTags);
              await ref.read(questionRepositoryProvider).update(updated);
              ref.read(currentQuestionProvider.notifier).state = updated;
              invalidateQuestionList(ref);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Widget _dialogTagChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color)),
    );
  }

  void _showFullImage(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: const Text('原图'),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(imagePath)),
            ),
          ),
        ),
      ),
    );
  }

  void _markResult(BuildContext context, WidgetRef ref, QuestionRecord question,
      bool mastered) async {
    final controller = ReviewController(
      repository: ref.read(questionRepositoryProvider),
      logRepository: ref.read(reviewLogRepositoryProvider),
    );
    final updated = mastered
        ? await controller.markMastered(question.id)
        : await controller.markReviewing(question.id);
    invalidateQuestionList(ref);
    ref.read(currentQuestionProvider.notifier).state = updated;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mastered ? '已标记为已掌握' : '已标记为待复习')),
    );
  }
}

class _AskAiCard extends ConsumerStatefulWidget {
  const _AskAiCard({required this.current});

  final QuestionRecord current;

  @override
  ConsumerState<_AskAiCard> createState() => _AskAiCardState();
}

class _AskAiMessage {
  const _AskAiMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String role;
  final String content;
  final DateTime createdAt;
}

class _AskAiCardState extends ConsumerState<_AskAiCard> {
  final TextEditingController _controller = TextEditingController();
  final List<_AskAiMessage> _messages = <_AskAiMessage>[];
  bool _isExpanded = false;
  bool _isSending = false;
  bool _isLoadingHistory = true;
  int _historyLoadToken = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didUpdateWidget(covariant _AskAiCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current.id != widget.current.id) {
      _loadHistory();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final token = ++_historyLoadToken;
    setState(() {
      _isLoadingHistory = true;
      _messages.clear();
    });

    try {
      final stored = await ref
          .read(aiConversationRepositoryProvider)
          .getByQuestionId(widget.current.id);
      if (!mounted || token != _historyLoadToken) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(stored.map((message) => _AskAiMessage(
                role: message.role == AiConversationRole.assistant
                    ? 'assistant'
                    : 'user',
                content: message.content,
                createdAt: message.createdAt,
              )));
        _isLoadingHistory = false;
      });
    } catch (e) {
      if (!mounted || token != _historyLoadToken) return;
      setState(() => _isLoadingHistory = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('读取 AI 答疑历史失败：$e')),
      );
    }
  }

  Future<void> _sendQuestion() async {
    final question = _controller.text.trim();
    if (question.isEmpty || _isSending) return;
    final askedAt = DateTime.now();
    final userMessage = _AskAiMessage(
      role: 'user',
      content: question,
      createdAt: askedAt,
    );

    setState(() {
      _isSending = true;
      _messages.add(userMessage);
      _controller.clear();
    });

    try {
      final answer = await ref
          .read(aiLearningTaskCoordinatorProvider)
          .answerQuestionFollowUp(
            question: widget.current,
            userQuestion: question,
            history: _messages
                .take(_messages.length - 1)
                .map((message) => AiFollowUpMessage(
                      role: message.role == 'assistant' ? 'assistant' : 'user',
                      content: message.content,
                    ))
                .toList(),
          );
      if (!mounted) return;
      final answeredAt = DateTime.now();
      final assistantMessage = _AskAiMessage(
        role: 'assistant',
        content: answer,
        createdAt: answeredAt,
      );

      await ref.read(aiConversationRepositoryProvider).insertAll(
        <AiConversationMessage>[
          _toStoredMessage(userMessage, suffix: 'u'),
          _toStoredMessage(assistantMessage, suffix: 'a'),
        ],
      );
      if (!mounted) return;
      setState(() {
        _messages.add(assistantMessage);
        _isSending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI 答疑失败：$e')),
      );
    }
  }

  AiConversationMessage _toStoredMessage(
    _AskAiMessage message, {
    required String suffix,
  }) {
    return AiConversationMessage(
      id: '${widget.current.id}-${message.createdAt.microsecondsSinceEpoch}-$suffix',
      questionId: widget.current.id,
      role: message.role == 'assistant'
          ? AiConversationRole.assistant
          : AiConversationRole.user,
      content: message.content,
      createdAt: message.createdAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF0F766E);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(CupertinoIcons.chat_bubble_2,
                    size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Text('AI 答疑',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface)),
              const Spacer(),
              Text(_messages.isEmpty ? '可追问' : '${_messages.length ~/ 2} 轮',
                  style: TextStyle(
                      fontSize: 12, color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '围绕这道错题继续追问，后续会自动带入题干、答案、步骤、错因和知识点。',
            style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _isExpanded = !_isExpanded);
              },
              icon: const Icon(CupertinoIcons.chat_bubble_text),
              label: Text(_isExpanded ? '收起追问' : '追问这道题'),
            ),
          ),
          if (_isExpanded) ...<Widget>[
            const SizedBox(height: 14),
            if (_isLoadingHistory) ...<Widget>[
              Row(
                children: <Widget>[
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '正在读取历史追问...',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (_messages.isNotEmpty) ...<Widget>[
              ..._messages.map((message) => _AskAiMessageBubble(
                    message: message,
                  )),
              const SizedBox(height: 4),
            ],
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: '哪里没看懂？可以继续追问哦～',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSending ? null : _sendQuestion,
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(CupertinoIcons.paperplane_fill),
                label: Text(_isSending ? '正在回答...' : '发送追问'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AskAiMessageBubble extends StatelessWidget {
  const _AskAiMessageBubble({required this.message});

  final _AskAiMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isUser
        ? colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.1)
        : isDark
            ? colorScheme.surface
            : const Color(0xFFF8FAFC);
    final borderColor = isUser
        ? colorScheme.primary.withValues(alpha: 0.22)
        : colorScheme.outlineVariant;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: align,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 2, right: 2, bottom: 4),
          child: Text(
            isUser ? '你' : 'AI 解答',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  isUser ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: isUser ? 360 : double.infinity,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: isUser
              ? Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: colorScheme.onSurface,
                  ),
                )
              : _AskAiAnswerView(content: message.content),
        ),
      ],
    );
  }
}

class _AskAiAnswerView extends StatelessWidget {
  const _AskAiAnswerView({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final blocks = _splitAnswerBlocks(_normalizeAnswerContent(content));

    if (blocks.isEmpty) {
      return Text(
        '',
        style: TextStyle(
          fontSize: 14,
          height: 1.55,
          color: colorScheme.onSurface,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.asMap().entries.map((entry) {
        final block = entry.value;
        final isFormula = _isDisplayFormulaBlock(block);
        final child = isFormula
            ? Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: MathContentView(
                  _displayFormulaForMathView(block),
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: colorScheme.onSurface,
                  ),
                ),
              )
            : _AskAiTextBlock(block: block);

        if (entry.key == blocks.length - 1) return child;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: child,
        );
      }).toList(),
    );
  }

  static List<String> _splitAnswerBlocks(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return const <String>[];
    return normalized
        .split(RegExp(r'\n\s*\n'))
        .map((block) => block.trim())
        .where((block) => block.isNotEmpty)
        .toList();
  }

  static bool _isDisplayFormulaBlock(String block) {
    final trimmed = block.trim();
    if (RegExp(r'^\\\[[\s\S]*\\\]$').hasMatch(trimmed) ||
        RegExp(r'^\$\$[\s\S]*\$\$$').hasMatch(trimmed)) {
      return true;
    }
    if (RegExp(r'^\\\([\s\S]*\\\)$').hasMatch(trimmed) ||
        RegExp(r'^\$[^\$]+\$$').hasMatch(trimmed)) {
      return RegExp(r'[=+\-*/^]|\\frac|\\sqrt|\\times|\\begin')
          .hasMatch(trimmed);
    }
    if (trimmed.length > 80 || trimmed.contains(RegExp(r'[\u4e00-\u9fa5]'))) {
      return false;
    }
    return RegExp(r'[=<>]|\\frac|\\sqrt|\\begin|\^').hasMatch(trimmed) &&
        RegExp(r'^[A-Za-z0-9\\{}\[\]().,，:：;；+\-*/=<>_^|\s]+$')
            .hasMatch(trimmed);
  }

  static String _displayFormulaForMathView(String block) {
    final trimmed = block.trim();
    if (RegExp(r'^\\\[[\s\S]*\\\]$').hasMatch(trimmed) ||
        RegExp(r'^\$\$[\s\S]*\$\$$').hasMatch(trimmed)) {
      return trimmed;
    }
    if (RegExp(r'^\\\([\s\S]*\\\)$').hasMatch(trimmed)) {
      return '\\[${trimmed.substring(2, trimmed.length - 2).trim()}\\]';
    }
    if (RegExp(r'^\$[^\$]+\$$').hasMatch(trimmed)) {
      return '\\[${trimmed.substring(1, trimmed.length - 1).trim()}\\]';
    }
    return '\\[$trimmed\\]';
  }

  static String _normalizeAnswerContent(String value) {
    var text = value.replaceAll('\r\n', '\n').trim();
    text = text.replaceAllMapped(
      RegExp(r'\\\[\s*([\s\S]*?)\s*\\\]'),
      (match) => '\n\n\\[${match.group(1)!.trim()}\\]\n\n',
    );
    text = text.replaceAllMapped(
      RegExp(r'\$\$\s*([\s\S]*?)\s*\$\$'),
      (match) => '\n\n\$\$${match.group(1)!.trim()}\$\$\n\n',
    );
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text;
  }
}

class _AskAiTextBlock extends StatelessWidget {
  const _AskAiTextBlock({required this.block});

  final String block;

  @override
  Widget build(BuildContext context) {
    final normalized = block.trim();
    if (_isBulletBlock(normalized)) {
      return _AskAiBulletList(block: normalized);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final heading = _headingText(normalized);
    if (heading != null) {
      return _AskAiInlineText(
        heading,
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      );
    }

    return _AskAiInlineText(
      normalized.replaceAll(RegExp(r'\s*\n\s*'), ' '),
      style: TextStyle(
        fontSize: 14,
        height: 1.62,
        color: colorScheme.onSurface,
      ),
    );
  }

  static bool _isBulletBlock(String value) {
    final lines = value
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return false;
    return lines
        .every((line) => RegExp(r'^([-*•]\s+|\d+[.)、]\s+)').hasMatch(line));
  }

  static String? _headingText(String value) {
    final markdownHeading = RegExp(r'^\s{0,3}#{1,4}\s+(.+)$').firstMatch(value);
    if (markdownHeading != null) return markdownHeading.group(1)!.trim();
    if (!value.contains('\n') && value.length <= 18 && value.endsWith('：')) {
      return value;
    }
    return null;
  }
}

class _AskAiBulletList extends StatelessWidget {
  const _AskAiBulletList({required this.block});

  final String block;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lines = block
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final text =
            line.replaceFirst(RegExp(r'^([-*•]\s+|\d+[.)、]\s+)'), '').trim();
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AskAiInlineText(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AskAiInlineText extends StatelessWidget {
  const _AskAiInlineText(
    this.text, {
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _inlineSpans(text, style)),
      style: style,
    );
  }

  static List<InlineSpan> _inlineSpans(String value, TextStyle style) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\\\(([\s\S]*?)\\\)|(?<!\\)\$([^\$]+)\$');
    var cursor = 0;
    for (final match in pattern.allMatches(value)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: value.substring(cursor, match.start)));
      }
      final formula = match.group(1) ?? match.group(2) ?? '';
      spans.add(TextSpan(
        text: _inlineFormulaToReadable(formula),
        style: style.copyWith(fontWeight: FontWeight.w500),
      ));
      cursor = match.end;
    }
    if (cursor < value.length) {
      spans.add(TextSpan(text: value.substring(cursor)));
    }
    return spans;
  }

  static String _inlineFormulaToReadable(String value) {
    var text = value.trim();
    text = text
        .replaceAll(r'\left', '')
        .replaceAll(r'\right', '')
        .replaceAll(r'\,', ' ')
        .replaceAll(r'\;', ' ')
        .replaceAll(r'\quad', ' ')
        .replaceAll(r'\qquad', ' ')
        .replaceAllMapped(
          RegExp(r'\\mathrm\{([^}]*)\}'),
          (match) => match.group(1)!,
        )
        .replaceAllMapped(
          RegExp(r'\\text\{([^}]*)\}'),
          (match) => match.group(1)!,
        )
        .replaceAllMapped(
          RegExp(r'\\frac\{([^}]*)\}\{([^}]*)\}'),
          (match) => '${match.group(1)!}/${match.group(2)!}',
        )
        .replaceAllMapped(
          RegExp(r'\\sqrt\{([^}]*)\}'),
          (match) => '√${match.group(1)!}',
        )
        .replaceAll(r'\times', '×')
        .replaceAll(r'\cdot', '·')
        .replaceAll(r'\div', '÷')
        .replaceAll(r'\pm', '±')
        .replaceAll(r'\mp', '∓')
        .replaceAll(r'\leq', '≤')
        .replaceAll(r'\geq', '≥')
        .replaceAll(r'\neq', '≠')
        .replaceAll(r'\approx', '≈')
        .replaceAll(r'\angle', '∠')
        .replaceAll(r'\triangle', '△')
        .replaceAll(r'\circ', '°')
        .replaceAll(r'\pi', 'π')
        .replaceAll(r'\Delta', 'Δ')
        .replaceAll(r'\alpha', 'α')
        .replaceAll(r'\beta', 'β')
        .replaceAll(r'\gamma', 'γ')
        .replaceAll(r'\theta', 'θ');
    text = text.replaceAllMapped(
      RegExp(r'\^\{?([0-9+\-]+)\}?'),
      (match) => _superscript(match.group(1)!),
    );
    text = text.replaceAllMapped(
      RegExp(r'_\{?([0-9+\-]+)\}?'),
      (match) => _subscript(match.group(1)!),
    );
    return text
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll(r'\ ', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _superscript(String value) {
    const map = <String, String>{
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
      '+': '⁺',
      '-': '⁻',
    };
    return value.split('').map((char) => map[char] ?? char).join();
  }

  static String _subscript(String value) {
    const map = <String, String>{
      '0': '₀',
      '1': '₁',
      '2': '₂',
      '3': '₃',
      '4': '₄',
      '5': '₅',
      '6': '₆',
      '7': '₇',
      '8': '₈',
      '9': '₉',
      '+': '₊',
      '-': '₋',
    };
    return value.split('').map((char) => map[char] ?? char).join();
  }
}

class _MasteryActions extends StatelessWidget {
  const _MasteryActions({
    required this.current,
    required this.onMarkReviewing,
    required this.onMarkMastered,
  });

  final QuestionRecord current;
  final VoidCallback onMarkReviewing;
  final VoidCallback onMarkMastered;

  @override
  Widget build(BuildContext context) {
    if (current.masteryLevel == MasteryLevel.mastered) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onMarkReviewing,
          child: const Text('仍需复习'),
        ),
      );
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton(
            onPressed: onMarkReviewing,
            child: const Text('仍需复习'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: onMarkMastered,
            child: const Text('已掌握'),
          ),
        ),
      ],
    );
  }
}

class _PracticeSummaryCard extends ConsumerStatefulWidget {
  const _PracticeSummaryCard({required this.current});

  final QuestionRecord current;

  @override
  ConsumerState<_PracticeSummaryCard> createState() =>
      _PracticeSummaryCardState();
}

class _PracticeSummaryCardState extends ConsumerState<_PracticeSummaryCard> {
  bool _isGenerating = false;
  String? _statusMessage;
  bool _statusIsError = false;
  String? _lastSyncedCompletedExerciseJobId;

  Future<void> _generateAndStartPractice({bool forceNew = false}) async {
    if (_isGenerating) return;

    final current = widget.current;
    if (current.savedExercises.isNotEmpty && !forceNew) {
      _startPractice(current);
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = '正在生成练习题，请稍等...';
      _statusIsError = false;
    });
    try {
      final exercises = await ref
          .read(aiLearningTaskCoordinatorProvider)
          .generateExercisesForQuestion(current, forceNew: forceNew);
      if (!mounted) return;

      if (exercises.isEmpty ||
          (forceNew && exercises.length <= current.savedExercises.length)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('暂未生成可用练习，请稍后重试')),
        );
        setState(() {
          _isGenerating = false;
          _statusMessage = '这次没有生成可用练习，可以稍后重试。';
          _statusIsError = true;
        });
        return;
      }

      final latest =
          await ref.read(questionRepositoryProvider).getById(current.id);
      final updated = (latest ?? current).copyWith(savedExercises: exercises);
      await ref.read(questionRepositoryProvider).update(updated);
      if (!mounted) return;

      ref.read(currentQuestionProvider.notifier).state = updated;
      invalidateQuestionList(ref);
      final latestGeneratedRound = latestExerciseRound(exercises);
      final generatedCount = latestGeneratedRound.isEmpty
          ? exercises.length
          : latestGeneratedRound.length;
      setState(() {
        _isGenerating = false;
        _statusMessage = '已生成 $generatedCount 道练习题，可以开始练习。';
        _statusIsError = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('举一反三已生成，可以开始练习')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _statusMessage = '生成失败，请检查网络或稍后重试。';
        _statusIsError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('举一反三生成失败：$e')),
      );
    }
  }

  void _startPractice(QuestionRecord current) {
    ref.read(currentPracticeContextProvider.notifier).state = PracticeContext(
      source: PracticeContextSource.notebook,
      returnRoute: '/notebook/question/${current.id}',
    );
    ref.read(currentQuestionProvider.notifier).state = current;
    context.go('/exercise/practice');
  }

  Future<void> _syncCompletedExerciseJob(AnalysisJob job) async {
    if (_lastSyncedCompletedExerciseJobId == job.id) return;
    _lastSyncedCompletedExerciseJobId = job.id;

    final latest =
        await ref.read(questionRepositoryProvider).getById(widget.current.id);
    if (!mounted || latest == null || latest.savedExercises.isEmpty) return;

    ref.read(currentQuestionProvider.notifier).state = latest;
    invalidateQuestionList(ref);
    setState(() {
      _isGenerating = false;
      _statusMessage = '已生成 ${latest.savedExercises.length} 道练习题，可以开始练习。';
      _statusIsError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.current;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasExercises = current.savedExercises.isNotEmpty;
    final latestRound = latestExerciseRound(current.savedExercises);
    final latestRoundCompleted =
        isLatestExerciseRoundCompleted(current.savedExercises);
    final generationJob =
        ref.watch(_exerciseGenerationJobProvider(current.id)).valueOrNull;
    ref.listen<AsyncValue<AnalysisJob?>>(
      _exerciseGenerationJobProvider(current.id),
      (_, next) {
        final job = next.valueOrNull;
        if (job?.status == AnalysisJobStatus.completed) {
          unawaited(_syncCompletedExerciseJob(job!));
        }
      },
    );
    final isQueued = generationJob?.status == AnalysisJobStatus.queued;
    final isRunning = generationJob?.status == AnalysisJobStatus.running;
    final hasActiveGenerationJob = isQueued || isRunning;
    final isSubmitting = _isGenerating && generationJob == null;
    final isGenerating = isSubmitting || hasActiveGenerationJob;
    final jobStatusMessage = _exerciseGenerationStatusMessage(
      generationJob,
      hasExercises: hasExercises,
    );
    final effectiveStatusMessage = hasActiveGenerationJob
        ? jobStatusMessage
        : (_statusMessage ?? jobStatusMessage);
    final effectiveStatusIsError = (!hasActiveGenerationJob &&
            _statusIsError) ||
        generationJob?.status == AnalysisJobStatus.failed ||
        (generationJob?.status == AnalysisJobStatus.completed &&
            !hasExercises &&
            (generationJob?.resultJson?.contains('"exercises":[]') ?? false));
    final inlineStatusIsLoading = isSubmitting || isRunning;
    final answeredCount = latestRound.where((e) => e.isCorrect != null).length;
    final totalCount = latestRound.isNotEmpty
        ? latestRound.length
        : current.savedExercises.length;
    const accent = Color(0xFF6366F1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.16 : 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(CupertinoIcons.arrow_2_circlepath,
                    size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Text('举一反三',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface)),
              const Spacer(),
              Text(
                hasExercises
                    ? '$answeredCount/$totalCount 已答'
                    : isQueued
                        ? '排队中'
                        : isGenerating
                            ? '生成中'
                            : generationJob?.status == AnalysisJobStatus.failed
                                ? '生成失败'
                                : '未生成',
                style: TextStyle(
                    fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasExercises
                ? latestRoundCompleted
                    ? '本轮练习已完成，可以再生成一组新的举一反三。'
                    : '已基于这道错题生成 $totalCount 道练习，继续完成剩余题目。'
                : '根据这道错题的题干、知识点和解析生成练习；宁可少生成，也不展示低质量练习。',
            style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: colorScheme.onSurfaceVariant),
          ),
          if (hasExercises) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _PracticeStatusChip(
                  icon: CupertinoIcons.square_list,
                  label: '$totalCount 题',
                  color: accent,
                ),
                _PracticeStatusChip(
                  icon: CupertinoIcons.check_mark_circled,
                  label: '$answeredCount 已答',
                  color: answeredCount == totalCount
                      ? const Color(0xFF059669)
                      : colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
          if (effectiveStatusMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            _PracticeInlineStatus(
              message: effectiveStatusMessage,
              isError: effectiveStatusIsError,
              isLoading: inlineStatusIsLoading,
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isGenerating
                  ? null
                  : hasExercises
                      ? latestRoundCompleted
                          ? () => _generateAndStartPractice(forceNew: true)
                          : () => _startPractice(current)
                      : _generateAndStartPractice,
              icon: isQueued
                  ? const Icon(CupertinoIcons.clock)
                  : isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(hasExercises
                          ? CupertinoIcons.play_fill
                          : CupertinoIcons.add_circled),
              label: Text(isGenerating
                  ? isQueued
                      ? '排队中...'
                      : isSubmitting
                          ? '提交中...'
                          : '正在生成...'
                  : hasExercises
                      ? latestRoundCompleted
                          ? '再生成一组'
                          : '继续练习'
                      : '生成举一反三'),
            ),
          ),
          if (!hasExercises && !isGenerating) ...<Widget>[
            const SizedBox(height: 8),
            Center(
              child: Text(
                '生成练习不会影响原题解析。',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _exerciseGenerationStatusMessage(
    AnalysisJob? job, {
    required bool hasExercises,
  }) {
    if (job == null) return null;
    return switch (job.status) {
      AnalysisJobStatus.queued => '已加入 AI 队列，会在前面的任务完成后继续；你可以先返回首页继续使用。',
      AnalysisJobStatus.running => '正在生成练习题，请稍等...',
      AnalysisJobStatus.completed => hasExercises ? null : '这次没有生成可用练习，可以稍后重试。',
      AnalysisJobStatus.failed => '生成失败，请检查网络或稍后重试。',
      AnalysisJobStatus.cancelled => '生成任务已取消，可以重新生成。',
    };
  }
}

class _PracticeStatusChip extends StatelessWidget {
  const _PracticeStatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeInlineStatus extends StatelessWidget {
  const _PracticeInlineStatus({
    required this.message,
    required this.isError,
    required this.isLoading,
  });

  final String message;
  final bool isError;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isError ? colorScheme.error : const Color(0xFF6366F1);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (isLoading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else
            Icon(
              isError
                  ? CupertinoIcons.exclamationmark_triangle
                  : CupertinoIcons.check_mark_circled,
              size: 15,
              color: color,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: isError ? colorScheme.error : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.border,
    required this.title,
    required this.titleColor,
    this.child,
  });

  final IconData icon;
  final Color iconColor;
  final Color bg;
  final Color border;
  final String title;
  final Color titleColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? iconColor.withValues(alpha: 0.28) : border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color:
                      isDark ? iconColor.withValues(alpha: 0.16) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? colorScheme.onSurface : titleColor)),
            ],
          ),
          const SizedBox(height: 10),
          if (child != null) child! else const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _ConsistencyNoticeData {
  const _ConsistencyNoticeData({
    required this.text,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String text;
  final IconData icon;
  final Color color;
  final Color background;
}

class _ConsistencyNotice extends StatelessWidget {
  const _ConsistencyNotice({required this.notice});

  final _ConsistencyNoticeData notice;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:
            isDark ? notice.color.withValues(alpha: 0.14) : notice.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: notice.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(notice.icon, size: 15, color: notice.color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              notice.text,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: isDark
                    ? Theme.of(context).colorScheme.onSurface
                    : notice.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchSiblingCard extends StatelessWidget {
  const _BatchSiblingCard(
      {required this.current, required this.group, required this.onSelect});

  final QuestionRecord current;
  final QuestionBatchGroup group;
  final void Function(QuestionRecord question) onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(CupertinoIcons.square_grid_2x2,
                  size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('同批题目',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant)),
              const SizedBox(width: 6),
              Text('${group.questions.length} 题',
                  style: TextStyle(
                      fontSize: 12, color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.questions.map((question) {
              final selected = question.id == current.id;
              return GestureDetector(
                onTap: selected ? null : () => onSelect(question),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? colorScheme.primary : colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant),
                  ),
                  child: Text(
                    _siblingLabel(question),
                    style: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _siblingLabel(QuestionRecord question) {
    final order = question.splitOrder;
    return order == null ? '同批题' : '第 $order 题';
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(
      {required this.label, required this.bgColor, required this.textColor});

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? textColor.withValues(alpha: 0.14) : bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? textColor.withValues(alpha: 0.24)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              color: isDark ? colorScheme.onSurface : textColor,
              fontWeight: FontWeight.w500)),
    );
  }
}
