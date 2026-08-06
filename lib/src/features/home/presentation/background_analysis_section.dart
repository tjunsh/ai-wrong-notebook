import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_wrong_notebook/src/data/services/question_analysis_coordinator.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/shared/widgets/math_content_view.dart';

class BackgroundAnalysisSection extends StatelessWidget {
  const BackgroundAnalysisSection({
    required this.tasks,
    required this.onOpenResult,
    required this.onRetry,
    required this.onDelete,
    super.key,
  });

  final List<QuestionAnalysisTaskSnapshot> tasks;
  final ValueChanged<QuestionAnalysisTaskSnapshot> onOpenResult;
  final ValueChanged<QuestionAnalysisTaskSnapshot> onRetry;
  final ValueChanged<QuestionAnalysisTaskSnapshot> onDelete;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(CupertinoIcons.doc_text_search, size: 18),
            const SizedBox(width: 8),
            Text('录题进度', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 10),
        ...tasks.map((task) => _TaskTile(
              task: task,
              onOpenResult: onOpenResult,
              onRetry: onRetry,
              onDelete: onDelete,
            )),
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onOpenResult,
    required this.onRetry,
    required this.onDelete,
  });

  final QuestionAnalysisTaskSnapshot task;
  final ValueChanged<QuestionAnalysisTaskSnapshot> onOpenResult;
  final ValueChanged<QuestionAnalysisTaskSnapshot> onRetry;
  final ValueChanged<QuestionAnalysisTaskSnapshot> onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = task.job.status;
    final canOpen =
        status == AnalysisJobStatus.completed && task.resultQuestion != null;
    final progress = task.job.progress;
    final showUnitProgress = status == AnalysisJobStatus.running &&
        progress?.stage == AnalysisJobProgressStage.analyzingCandidates &&
        progress?.hasUnitProgress == true;
    final subjectIsResolving = task.displaySubject == Subject.unknown &&
        (task.isRecognizing || status == AnalysisJobStatus.running);
    final subjectLabel = task.displaySubject == Subject.unknown
        ? subjectIsResolving
            ? '学科识别中'
            : '学科待识别'
        : task.displaySubject.label;
    final subjectLine = task.questionCount > 1
        ? '$subjectLabel · 共 ${task.questionCount} 道题'
        : subjectLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: ListTile(
          minTileHeight: 92,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: _StatusIcon(task: task),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                subjectLine,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: task.displaySubject.color,
                ),
              ),
              const SizedBox(height: 4),
              MathContentView(
                task.displayQuestionText,
                contentFormat: task.resultQuestion?.contentFormat ??
                    task.sourceQuestion.contentFormat,
                mode: MathContentViewMode.compact,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _statusLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _statusColor(colorScheme),
                  ),
                ),
                if (showUnitProgress) ...<Widget>[
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress!.fraction,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ],
            ),
          ),
          trailing: _TaskActions(
            task: task,
            canOpen: canOpen,
            onOpenResult: onOpenResult,
            onRetry: onRetry,
            onDelete: onDelete,
          ),
          onTap: canOpen ? () => onOpenResult(task) : null,
        ),
      ),
    );
  }

  String _statusLabel() {
    final status = task.job.status;
    if (status == AnalysisJobStatus.queued && task.isRecognizing) {
      return '正在识别题目内容';
    }
    if (status == AnalysisJobStatus.running) {
      final progress = task.job.progress;
      if (progress == null) return '正在解析';
      return switch (progress.stage) {
        AnalysisJobProgressStage.recognizing => '正在识别题目内容',
        AnalysisJobProgressStage.analyzing => '正在生成解析',
        AnalysisJobProgressStage.analyzingCandidates =>
          _candidateProgressLabel(progress),
        AnalysisJobProgressStage.finalizing => '正在整理解析结果',
      };
    }
    if (status == AnalysisJobStatus.completed) {
      final candidateSummary = _candidateSummary;
      if (candidateSummary != null) {
        final retrying = candidateSummary.retryingCandidate;
        if (retrying != null) {
          return retrying.status == CandidateAnalysisStatus.running
              ? '已解析 ${candidateSummary.successful}/${candidateSummary.total}，正在重新解析第 ${retrying.order} 题'
              : '已解析 ${candidateSummary.successful}/${candidateSummary.total}，第 ${retrying.order} 题排队中';
        }
        if (candidateSummary.failed > 0) {
          return '已解析 ${candidateSummary.successful}/${candidateSummary.total}，${candidateSummary.failed} 道未成功，待确认';
        }
      }
      final progress = task.job.progress;
      if (progress != null &&
          progress.totalUnits > 1 &&
          progress.failedUnits > 0) {
        return '已解析 ${progress.totalUnits - progress.failedUnits}/${progress.totalUnits}，${progress.failedUnits} 道未成功，待确认';
      }
    }
    return switch (status) {
      AnalysisJobStatus.queued => '等待解析',
      AnalysisJobStatus.running => '正在解析',
      AnalysisJobStatus.completed => '解析好了，待确认',
      AnalysisJobStatus.failed => '解析失败',
      AnalysisJobStatus.cancelled => '已停止',
    };
  }

  String _candidateProgressLabel(AnalysisJobProgress progress) {
    final completed = progress.completedUnits.clamp(0, progress.totalUnits);
    if (completed >= progress.totalUnits) return '正在整理解析结果';
    final current = completed + 1;
    return '已完成 $completed/${progress.totalUnits}，正在解析第 $current 题';
  }

  bool get _hasPartialFailures {
    final summary = _candidateSummary;
    if (summary != null) return summary.failed > 0;
    final progress = task.job.progress;
    return task.job.status == AnalysisJobStatus.completed &&
        progress != null &&
        progress.totalUnits > 1 &&
        progress.failedUnits > 0;
  }

  _CandidateSummary? get _candidateSummary {
    final candidates = task.resultQuestion?.candidateAnalyses ?? const [];
    if (candidates.length <= 1) return null;
    CandidateAnalysisSnapshot? retrying;
    for (final candidate in candidates) {
      if (candidate.status == CandidateAnalysisStatus.queued ||
          candidate.status == CandidateAnalysisStatus.running) {
        retrying = candidate;
        break;
      }
    }
    return _CandidateSummary(
      total: candidates.length,
      successful:
          candidates.where((candidate) => candidate.isSuccessful).length,
      failed: candidates
          .where(
              (candidate) => candidate.status == CandidateAnalysisStatus.failed)
          .length,
      retryingCandidate: retrying,
    );
  }

  Color _statusColor(ColorScheme colorScheme) {
    final isRetrying = _candidateSummary?.retryingCandidate != null;
    if (_hasPartialFailures || isRetrying) return const Color(0xFFB45309);
    return switch (task.job.status) {
      AnalysisJobStatus.completed => const Color(0xFF15803D),
      AnalysisJobStatus.failed => colorScheme.error,
      _ => colorScheme.onSurfaceVariant,
    };
  }
}

class _CandidateSummary {
  const _CandidateSummary({
    required this.total,
    required this.successful,
    required this.failed,
    required this.retryingCandidate,
  });

  final int total;
  final int successful;
  final int failed;
  final CandidateAnalysisSnapshot? retryingCandidate;
}

class _TaskActions extends StatelessWidget {
  const _TaskActions({
    required this.task,
    required this.canOpen,
    required this.onOpenResult,
    required this.onRetry,
    required this.onDelete,
  });

  final QuestionAnalysisTaskSnapshot task;
  final bool canOpen;
  final ValueChanged<QuestionAnalysisTaskSnapshot> onOpenResult;
  final ValueChanged<QuestionAnalysisTaskSnapshot> onRetry;
  final ValueChanged<QuestionAnalysisTaskSnapshot> onDelete;

  @override
  Widget build(BuildContext context) {
    final failed = task.job.status == AnalysisJobStatus.failed;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          onPressed: () => onDelete(task),
          tooltip: failed ? '删除失败任务' : '删除任务',
          icon: const Icon(CupertinoIcons.delete, size: 18),
        ),
        if (failed)
          TextButton.icon(
            onPressed: () => onRetry(task),
            icon: const Icon(CupertinoIcons.refresh, size: 16),
            label: const Text('重试'),
          )
        else if (canOpen)
          TextButton(
            onPressed: () => onOpenResult(task),
            child: const Text('查看结果'),
          ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.task});

  final QuestionAnalysisTaskSnapshot task;

  @override
  Widget build(BuildContext context) {
    final status = task.job.status;
    if (status == AnalysisJobStatus.running || task.isRecognizing) {
      return const SizedBox.square(
        dimension: 28,
        child: Padding(
          padding: EdgeInsets.all(4),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    final progress = task.job.progress;
    final hasPartialFailures = status == AnalysisJobStatus.completed &&
        progress != null &&
        progress.totalUnits > 1 &&
        progress.failedUnits > 0;
    if (hasPartialFailures) {
      return const Icon(
        CupertinoIcons.exclamationmark_circle_fill,
        size: 28,
        color: Color(0xFFB45309),
      );
    }
    final (icon, color) = switch (status) {
      AnalysisJobStatus.queued => (
          CupertinoIcons.clock,
          colorScheme.onSurfaceVariant
        ),
      AnalysisJobStatus.completed => (
          CupertinoIcons.check_mark_circled_solid,
          const Color(0xFF15803D)
        ),
      AnalysisJobStatus.failed => (
          CupertinoIcons.exclamationmark_circle_fill,
          colorScheme.error
        ),
      AnalysisJobStatus.cancelled => (
          CupertinoIcons.clear_circled,
          colorScheme.onSurfaceVariant
        ),
      AnalysisJobStatus.running => (
          CupertinoIcons.clock,
          colorScheme.onSurfaceVariant
        ),
    };
    return Icon(icon, size: 28, color: color);
  }
}
