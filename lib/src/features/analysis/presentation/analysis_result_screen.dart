import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/services/question_analysis_coordinator.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/shared/widgets/math_content_view.dart';

class AnalysisResultScreen extends ConsumerStatefulWidget {
  const AnalysisResultScreen({super.key});

  @override
  ConsumerState<AnalysisResultScreen> createState() =>
      _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends ConsumerState<AnalysisResultScreen> {
  int _activeCandidateIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selectedRecord = ref.watch(currentQuestionProvider);
    final backgroundTasks =
        ref.watch(backgroundAnalysisTasksProvider).valueOrNull ??
            const <QuestionAnalysisTaskSnapshot>[];
    final record = _latestTaskResultFor(
      selectedRecord,
      backgroundTasks,
    );

    if (record == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AI 解析结果'),
          leading: IconButton(
            icon: const Icon(CupertinoIcons.chevron_left),
            onPressed: () => context.go('/analysis/loading'),
          ),
        ),
        body: const Center(child: Text('未找到错题记录')),
      );
    }

    final result = record.analysisResult;
    final splitResult = record.splitResult;
    final hasMultipleCandidates = splitResult?.hasMultipleCandidates ?? false;
    final safeCandidateIndex = hasMultipleCandidates
        ? _activeCandidateIndex.clamp(0, splitResult!.candidates.length - 1)
        : 0;
    final activeCandidate = hasMultipleCandidates
        ? splitResult!.candidates[safeCandidateIndex]
        : null;
    final activeCandidateAnalysis = activeCandidate == null
        ? null
        : record.candidateAnalyses.firstWhereOrNull(
            (candidate) => candidate.candidateId == activeCandidate.id);
    final displayResult = hasMultipleCandidates
        ? activeCandidateAnalysis?.analysisResult
        : result;
    final displayAiTags = hasMultipleCandidates
        ? activeCandidateAnalysis?.aiTags ?? const <String>[]
        : record.aiTags;
    final displayKnowledgePoints = hasMultipleCandidates
        ? activeCandidateAnalysis?.aiKnowledgePoints ?? const <String>[]
        : result?.knowledgePoints ?? const <String>[];
    final displayQuestionText = activeCandidateAnalysis?.questionText ??
        activeCandidate?.text ??
        record.correctedText;
    final hasRetryingCandidate = record.candidateAnalyses.any((candidate) =>
        candidate.status == CandidateAnalysisStatus.queued ||
        candidate.status == CandidateAnalysisStatus.running);
    final candidateInsight = hasMultipleCandidates
        ? _candidateInsight(
            candidateOrder: activeCandidate?.order ?? 1,
            total: splitResult?.candidates.length ?? 1,
            hasIndependentAnalysis: activeCandidateAnalysis != null,
          )
        : null;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 解析结果'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          // 统一标签分类框：科目 | AI识别 | 状态 | 知识点
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
                      label:
                          displayResult?.subject?.label ?? record.subject.label,
                      bgColor: const Color(0xFFEEF2FF),
                      textColor: const Color(0xFF4F46E5),
                    ),
                    if (displayResult?.subject != null) ...<Widget>[
                      const SizedBox(width: 8),
                      const _TagChip(
                        label: 'AI识别',
                        bgColor: Color(0xFFF0FDF4),
                        textColor: Color(0xFF16A34A),
                      ),
                    ],
                    const SizedBox(width: 8),
                    _TagChip(
                      label: _masteryLabel(record.masteryLevel),
                      bgColor: _masteryColor(record.masteryLevel)
                          .withValues(alpha: 0.1),
                      textColor: _masteryColor(record.masteryLevel),
                    ),
                  ],
                ),
                if (record.splitResult != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: <Widget>[
                      _TagChip(
                        label: '候选 ${record.splitResult!.candidates.length} 题',
                        bgColor: const Color(0xFFF5F3FF),
                        textColor: const Color(0xFF7C3AED),
                      ),
                      _TagChip(
                        label:
                            _splitStrategyLabel(record.splitResult!.strategy),
                        bgColor: const Color(0xFFF8FAFC),
                        textColor: const Color(0xFF475569),
                      ),
                      if (activeCandidate != null)
                        _TagChip(
                          label: '当前第 ${activeCandidate.order} 题',
                          bgColor: const Color(0xFFFEF3C7),
                          textColor: const Color(0xFFB45309),
                        ),
                    ],
                  ),
                  if (record.splitResult!.hasMultipleCandidates) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      '这张图片已识别为多题内容，保存时会进入逐题确认。',
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
                // AI 短标签（橙色）
                if (displayAiTags.isNotEmpty) ...<Widget>[
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
                    children: displayAiTags
                        .map((tag) => _TagChip(
                              label: tag,
                              bgColor: const Color(0xFFFFF7ED),
                              textColor: const Color(0xFFD97706),
                            ))
                        .toList(),
                  ),
                ],
                // 自定义标签（蓝色）
                if (record.customTags.isNotEmpty) ...<Widget>[
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
                    children: record.customTags
                        .map((t) => _TagChip(
                              label: t,
                              bgColor: const Color(0xFFEEF2FF),
                              textColor: const Color(0xFF4F46E5),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          if (record.splitResult?.hasMultipleCandidates ?? false) ...<Widget>[
            const SizedBox(height: 12),
            _CandidateSwitcherCard(
              splitResult: splitResult!,
              candidateAnalyses: record.candidateAnalyses,
              safeCandidateIndex: safeCandidateIndex,
              onSelected: (index) =>
                  setState(() => _activeCandidateIndex = index),
            ),
          ],
          if (displayResult == null) ...<Widget>[
            const SizedBox(height: 20),
            _SectionCard(
              icon: CupertinoIcons.exclamationmark_triangle,
              iconColor: const Color(0xFFDC2626),
              bg: const Color(0xFFFEF2F2),
              border: const Color(0xFFFECACA),
              title: _candidateFailureTitle(activeCandidateAnalysis,
                  order: activeCandidate?.order ?? 1),
              titleColor: const Color(0xFFB91C1C),
              contentWidget: MathContentView(
                _candidateFailureMessage(activeCandidateAnalysis),
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDark ? colorScheme.onSurface : const Color(0xFFB91C1C),
                  height: 1.5,
                ),
              ),
            ),
            if (hasMultipleCandidates &&
                activeCandidateAnalysis != null) ...<Widget>[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: activeCandidateAnalysis.status ==
                              CandidateAnalysisStatus.failed &&
                          activeCandidate != null
                      ? () => _retryCandidate(
                            record,
                            activeCandidateAnalysis,
                          )
                      : null,
                  icon: Icon(_candidateRetryIcon(activeCandidateAnalysis)),
                  label: Text(_candidateRetryLabel(
                    activeCandidateAnalysis,
                    activeCandidate?.order ?? 1,
                  )),
                ),
              ),
            ],
          ],
          if (displayResult != null) ...<Widget>[
            const SizedBox(height: 20),
            // 原题（包含图片和文本）
            _SectionCard(
              icon: CupertinoIcons.doc_text,
              iconColor: const Color(0xFF6366F1),
              bg: const Color(0xFFEEF2FF),
              border: const Color(0xFFC7D2FE),
              title: '原题',
              titleColor: const Color(0xFF4338CA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (File(record.imagePath).existsSync())
                    GestureDetector(
                      onTap: () => _showFullImage(context, record.imagePath),
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
                                File(record.imagePath),
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.contain,
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
                  if (File(record.imagePath).existsSync())
                    const SizedBox(height: 10),
                  MathContentView(
                    displayQuestionText,
                    contentFormat: hasMultipleCandidates
                        ? QuestionContentFormat.latexMixed
                        : record.contentFormat,
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
            _SectionCard(
              icon: displayResult.visualAssumptionStatus ==
                      VisualAssumptionStatus.needsReview
                  ? CupertinoIcons.exclamationmark_triangle
                  : CupertinoIcons.checkmark_circle,
              iconColor: displayResult.visualAssumptionStatus ==
                      VisualAssumptionStatus.needsReview
                  ? const Color(0xFFEA580C)
                  : const Color(0xFF16A34A),
              bg: displayResult.visualAssumptionStatus ==
                      VisualAssumptionStatus.needsReview
                  ? const Color(0xFFFFF7ED)
                  : const Color(0xFFF0FDF4),
              border: displayResult.visualAssumptionStatus ==
                      VisualAssumptionStatus.needsReview
                  ? const Color(0xFFFED7AA)
                  : const Color(0xFFBBF7D0),
              title: displayResult.visualAssumptionStatus ==
                      VisualAssumptionStatus.needsReview
                  ? '可能解法'
                  : '正确解答',
              titleColor: displayResult.visualAssumptionStatus ==
                      VisualAssumptionStatus.needsReview
                  ? const Color(0xFF9A3412)
                  : const Color(0xFF166534),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MathContentView(
                    displayResult.finalAnswer,
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? colorScheme.onSurface
                            : const Color(0xFF15803D),
                        fontWeight: FontWeight.w600),
                  ),
                  if (_consistencyNotice(displayResult) != null) ...<Widget>[
                    const SizedBox(height: 10),
                    _ConsistencyNotice(
                      notice: _consistencyNotice(displayResult)!,
                    ),
                  ],
                  if (_shouldOfferQuestionCorrection(
                    displayResult,
                    hasMultipleCandidates: hasMultipleCandidates,
                  )) ...<Widget>[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.go('/analysis/text-correction'),
                        icon: const Icon(CupertinoIcons.pencil, size: 17),
                        label: const Text('核对题干后重新解析'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Mistake reason
            _SectionCard(
              icon: CupertinoIcons.exclamationmark_triangle,
              iconColor: const Color(0xFFEA580C),
              bg: const Color(0xFFFFF7ED),
              border: const Color(0xFFFED7AA),
              title: '错因分析',
              titleColor: const Color(0xFF9A3412),
              contentWidget: MathContentView(
                displayResult.mistakeReason,
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
            _SectionCard(
              icon: CupertinoIcons.lightbulb,
              iconColor: const Color(0xFFD97706),
              bg: const Color(0xFFFFFBEB),
              border: const Color(0xFFFDE68A),
              title: '学习建议',
              titleColor: const Color(0xFF92400E),
              contentWidget: MathContentView(
                displayResult.studyAdvice,
                style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? colorScheme.onSurface
                        : const Color(0xFFB45309),
                    height: 1.5),
              ),
            ),
            if (candidateInsight != null) ...<Widget>[
              const SizedBox(height: 10),
              _SectionCard(
                icon: CupertinoIcons.layers,
                iconColor: const Color(0xFF0F766E),
                bg: const Color(0xFFF0FDFA),
                border: const Color(0xFF99F6E4),
                title: '当前子题状态',
                titleColor: const Color(0xFF115E59),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    MathContentView(
                      candidateInsight,
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? colorScheme.onSurface
                              : const Color(0xFF134E4A),
                          height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeCandidateAnalysis != null
                          ? '当前已切换到第 ${activeCandidate?.order ?? 1} 题独立解析。'
                          : '第 ${activeCandidate?.order ?? 1} 题暂无独立解析。',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
            // Knowledge points
            if (displayKnowledgePoints.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Text('知识点',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: displayKnowledgePoints
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
            if (displayResult.steps.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Text('解题步骤',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ...displayResult.steps.asMap().entries.map((e) => Container(
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
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: hasRetryingCandidate
                    ? null
                    : () async {
                        final splitter = ref.read(questionSplitServiceProvider);
                        ref
                            .read(currentQuestionSplitSessionProvider.notifier)
                            .state = await buildQuestionSplitSession(
                          record,
                          splitter: splitter,
                        );
                        if (!context.mounted) return;
                        context.go('/capture/split-confirmation');
                      },
                child: Text(hasRetryingCandidate ? '有题正在重新解析' : '保存到错题本'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _discardResult(record),
                icon: const Icon(CupertinoIcons.delete, size: 18),
                label: const Text('放弃本次结果'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _discardResult(QuestionRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('放弃本次结果'),
        content: const Text('确定放弃这次解析结果吗？此操作不可恢复。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('放弃'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(scanTaskLifecycleServiceProvider).discard(record);
      ref.read(currentQuestionProvider.notifier).state = null;
      ref.read(currentQuestionSplitSessionProvider.notifier).state = null;
      ref.invalidate(scanTaskCountProvider);
      if (mounted) context.go('/');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('放弃失败：$error')),
      );
    }
  }

  QuestionRecord? _latestTaskResultFor(
    QuestionRecord? selected,
    List<QuestionAnalysisTaskSnapshot> tasks,
  ) {
    if (selected == null) return null;
    for (final task in tasks) {
      if (task.handle.parentQuestionId != selected.id) continue;
      final result = task.resultQuestion;
      if (result != null) return result;
    }
    return selected;
  }

  String _candidateFailureTitle(
    CandidateAnalysisSnapshot? candidate, {
    required int order,
  }) {
    return switch (candidate?.status) {
      CandidateAnalysisStatus.queued => '第 $order 题排队中',
      CandidateAnalysisStatus.running => '正在重新解析第 $order 题',
      _ => '第 $order 题解析失败',
    };
  }

  String _candidateFailureMessage(CandidateAnalysisSnapshot? candidate) {
    return switch (candidate?.status) {
      CandidateAnalysisStatus.queued => '已加入解析队列，完成后会补全到当前结果。',
      CandidateAnalysisStatus.running => '正在重新解析本题，完成后会补全到当前结果。',
      _ => candidate?.errorMessage?.isNotEmpty == true
          ? '已自动重试，仍未成功。该题暂不可保存，可单独重试。\n${candidate!.errorMessage}'
          : '已自动重试，仍未成功。该题暂不可保存，可单独重试。',
    };
  }

  IconData _candidateRetryIcon(CandidateAnalysisSnapshot candidate) {
    return switch (candidate.status) {
      CandidateAnalysisStatus.queued => CupertinoIcons.clock,
      CandidateAnalysisStatus.running => CupertinoIcons.arrow_clockwise,
      CandidateAnalysisStatus.success => CupertinoIcons.checkmark,
      CandidateAnalysisStatus.failed => CupertinoIcons.refresh,
    };
  }

  String _candidateRetryLabel(
    CandidateAnalysisSnapshot candidate,
    int order,
  ) {
    return switch (candidate.status) {
      CandidateAnalysisStatus.queued => '第 $order 题排队中',
      CandidateAnalysisStatus.running => '正在重新解析第 $order 题',
      CandidateAnalysisStatus.success => '第 $order 题已解析',
      CandidateAnalysisStatus.failed => '重试第 $order 题',
    };
  }

  Future<void> _retryCandidate(
    QuestionRecord source,
    CandidateAnalysisSnapshot candidate,
  ) async {
    final coordinator = ref.read(questionAnalysisCoordinatorProvider);
    final CandidateAnalysisRetryCoordinator? retryCoordinator =
        coordinator is CandidateAnalysisRetryCoordinator
            ? coordinator as CandidateAnalysisRetryCoordinator
            : null;
    if (retryCoordinator == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前解析任务不支持单题重试，请返回首页重新解析。')),
      );
      return;
    }
    try {
      final queued = await retryCoordinator.retryCandidate(source, candidate);
      if (!mounted) return;
      if (queued) {
        ref.read(currentQuestionProvider.notifier).state =
            _withQueuedCandidate(source, candidate.candidateId);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            queued
                ? '已加入队列，将只重新解析第 ${candidate.order} 题'
                : '第 ${candidate.order} 题已在解析队列中',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('重新解析失败：$error')),
      );
    }
  }

  QuestionRecord _withQueuedCandidate(
    QuestionRecord source,
    String candidateId,
  ) {
    return source.copyWith(
      candidateAnalyses: source.candidateAnalyses.map((candidate) {
        if (candidate.candidateId != candidateId) return candidate;
        return CandidateAnalysisSnapshot(
          candidateId: candidate.candidateId,
          order: candidate.order,
          questionText: candidate.questionText,
          analysisResult: candidate.analysisResult,
          savedExercises: candidate.savedExercises,
          subject: candidate.subject,
          aiTags: candidate.aiTags,
          aiKnowledgePoints: candidate.aiKnowledgePoints,
          status: CandidateAnalysisStatus.queued,
        );
      }).toList(growable: false),
    );
  }

  bool _shouldOfferQuestionCorrection(
    AnalysisResult result, {
    required bool hasMultipleCandidates,
  }) {
    if (hasMultipleCandidates) return false;
    return result.visualAssumptionStatus ==
            VisualAssumptionStatus.needsReview ||
        result.consistencyStatus == AnalysisConsistencyStatus.needsReview;
  }

  String _candidateInsight({
    required int candidateOrder,
    required int total,
    required bool hasIndependentAnalysis,
  }) {
    return hasIndependentAnalysis
        ? '当前正在查看第 $candidateOrder / $total 题，已切换到独立解析结果。'
        : '当前正在查看第 $candidateOrder / $total 题，题干切换已生效。';
  }

  String _splitStrategyLabel(Object strategy) {
    switch (strategy.toString().split('.').last) {
      case 'numbered':
        return '编号拆题';
      case 'paragraph':
        return '分段拆题';
      default:
        return '单题回退';
    }
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
}

extension _IterableFirstOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E item) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}

class _CandidateSwitcherCard extends StatelessWidget {
  const _CandidateSwitcherCard({
    required this.splitResult,
    required this.candidateAnalyses,
    required this.safeCandidateIndex,
    required this.onSelected,
  });

  final QuestionSplitResult splitResult;
  final List<CandidateAnalysisSnapshot> candidateAnalyses;
  final int safeCandidateIndex;
  final void Function(int index) onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF7C3AED);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: accent.withValues(alpha: isDark ? 0.28 : 0.22)),
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
                child: const Icon(CupertinoIcons.square_list,
                    size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Text('题号切换',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: splitResult.candidates.asMap().entries.map((entry) {
                final candidate = entry.value;
                final isActive = entry.key == safeCandidateIndex;
                final analysis = candidateAnalyses.firstWhereOrNull(
                  (item) => item.candidateId == candidate.id,
                );
                final statusColor = switch (analysis?.status) {
                  CandidateAnalysisStatus.failed => colorScheme.error,
                  CandidateAnalysisStatus.queued ||
                  CandidateAnalysisStatus.running =>
                    const Color(0xFFD97706),
                  _ => colorScheme.onSurfaceVariant,
                };
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('第 ${candidate.order} 题'),
                    selected: isActive,
                    onSelected: (_) => onSelected(entry.key),
                    labelStyle: TextStyle(
                      fontSize: 14,
                      color: isActive ? colorScheme.onPrimary : statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                    selectedColor: colorScheme.primary,
                    backgroundColor: colorScheme.surface,
                    side: BorderSide(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.border,
    required this.title,
    required this.titleColor,
    this.child,
    this.contentWidget,
  });

  final IconData icon;
  final Color iconColor;
  final Color bg;
  final Color border;
  final String title;
  final Color titleColor;
  final Widget? child;
  final Widget? contentWidget;

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
          if (child != null)
            child!
          else if (contentWidget != null)
            contentWidget!
          else
            const SizedBox.shrink(),
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

String _masteryLabel(MasteryLevel level) {
  switch (level) {
    case MasteryLevel.newQuestion:
      return '未复习';
    case MasteryLevel.reviewing:
      return '复习中';
    case MasteryLevel.mastered:
      return '已掌握';
  }
}

Color _masteryColor(MasteryLevel level) {
  switch (level) {
    case MasteryLevel.newQuestion:
      return Colors.grey;
    case MasteryLevel.reviewing:
      return Colors.orange;
    case MasteryLevel.mastered:
      return Colors.green;
  }
}
