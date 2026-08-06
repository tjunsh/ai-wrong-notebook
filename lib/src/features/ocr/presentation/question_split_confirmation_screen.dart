import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_session.dart';
import 'package:smart_wrong_notebook/src/shared/widgets/math_content_view.dart';

const _mathPreviewFormat = QuestionContentFormat.latexMixed;

class QuestionSplitConfirmationScreen extends ConsumerStatefulWidget {
  const QuestionSplitConfirmationScreen({super.key});

  @override
  ConsumerState<QuestionSplitConfirmationScreen> createState() =>
      _QuestionSplitConfirmationScreenState();
}

class _QuestionSplitConfirmationScreenState
    extends ConsumerState<QuestionSplitConfirmationScreen> {
  int _activeIndex = 0;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentQuestionSplitSessionProvider);
    final source = session?.source;
    final drafts = session?.drafts ?? const <QuestionSplitDraft>[];
    final hasImage = source != null &&
        source.imagePath.isNotEmpty &&
        File(source.imagePath).existsSync();

    if (session == null || source == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('拆分保存')),
        body: const Center(child: Text('未找到待保存题目')),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeIndex =
        drafts.isEmpty ? 0 : _activeIndex.clamp(0, drafts.length - 1);
    final activeDraft = drafts.isEmpty ? null : drafts[safeIndex];
    final selectedCount =
        drafts.where((draft) => draft.canSave && draft.selected).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('拆分保存'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.go('/analysis/result'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF4F46E5).withValues(alpha: 0.18)
                              : const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(CupertinoIcons.square_split_2x2,
                            size: 18, color: Color(0xFF4F46E5)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text('逐题确认后保存',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              '保持当前分析结果页体验，保存前按题整理，方便后续检索、复习和继续练习。',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: <Widget>[
                      _SummaryChip(
                        label: '可保存 ${drafts.length} 题',
                        bgColor: isDark
                            ? const Color(0xFF4F46E5).withValues(alpha: 0.18)
                            : const Color(0xFFEEF2FF),
                        textColor: const Color(0xFF4F46E5),
                      ),
                      _SummaryChip(
                        label: '已选 $selectedCount 题',
                        bgColor: isDark
                            ? const Color(0xFF16A34A).withValues(alpha: 0.16)
                            : const Color(0xFFF0FDF4),
                        textColor: const Color(0xFF16A34A),
                      ),
                      _SummaryChip(
                        label: source.subject.label,
                        bgColor: isDark
                            ? const Color(0xFFD97706).withValues(alpha: 0.16)
                            : const Color(0xFFFFF7ED),
                        textColor: const Color(0xFFD97706),
                      ),
                      if (session.failedCandidateCount > 0)
                        _SummaryChip(
                          label: '${session.failedCandidateCount} 题未解析成功',
                          bgColor: isDark
                              ? const Color(0xFFDC2626).withValues(alpha: 0.16)
                              : const Color(0xFFFEF2F2),
                          textColor: const Color(0xFFB91C1C),
                        ),
                      if (session.retryingCandidateCount > 0)
                        _SummaryChip(
                          label: '${session.retryingCandidateCount} 题重新解析中',
                          bgColor: isDark
                              ? const Color(0xFFD97706).withValues(alpha: 0.16)
                              : const Color(0xFFFFF7ED),
                          textColor: const Color(0xFFB45309),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (hasImage)
              GestureDetector(
                onTap: () => _showFullImage(context, source.imagePath),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(source.imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            if (hasImage) const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('题目列表',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('仅展示解析成功的题目。取消不需要保存的题目，点击卡片切换当前编辑项。',
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      TextButton.icon(
                        onPressed:
                            _isSaving ? null : () => _setAllSelected(true),
                        icon: const Icon(CupertinoIcons.checkmark_circle,
                            size: 16),
                        label: const Text('全选'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed:
                            _isSaving ? null : () => _setAllSelected(false),
                        icon: const Icon(CupertinoIcons.circle, size: 16),
                        label: const Text('清空'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...drafts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final draft = entry.value;
                    final isActive = index == safeIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => setState(() => _activeIndex = index),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isActive
                                ? (isDark
                                    ? const Color(0xFF6366F1)
                                        .withValues(alpha: 0.18)
                                    : const Color(0xFFEEF2FF))
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? (isDark
                                      ? const Color(0xFF6366F1)
                                          .withValues(alpha: 0.45)
                                      : const Color(0xFFC7D2FE))
                                  : colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Transform.scale(
                                scale: 1.05,
                                child: Checkbox(
                                  value: draft.canSave && draft.selected,
                                  onChanged: draft.canSave
                                      ? (value) => _updateDraft(
                                            index,
                                            draft.copyWith(
                                                selected: value ?? false),
                                          )
                                      : null,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? const Color(0xFF6366F1)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isActive
                                                    ? Colors.white
                                                    : colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: MathContentView(
                                            draft.text.trim().isEmpty
                                                ? '待补充题目内容'
                                                : draft.text,
                                            contentFormat: _mathPreviewFormat,
                                            mode: MathContentViewMode.compact,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: draft.canSave &&
                                                      draft.selected
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(CupertinoIcons.chevron_right,
                                  size: 18,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (activeDraft != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Text('当前题目内容',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('第 ${activeDraft.originalOrder} 题',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('支持轻量修改，保存时会按当前内容逐题落库。',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: ValueKey(activeDraft.id),
                      initialValue: _displayEditableText(activeDraft.text),
                      maxLines: 8,
                      minLines: 6,
                      onChanged: (value) => _updateDraft(
                          safeIndex, activeDraft.copyWith(text: value)),
                      decoration: InputDecoration(
                        hintText: '请输入题目内容',
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FormulaPreviewCard(
                      content: activeDraft.text,
                      contentFormat: activeDraft.contentFormat,
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFDC2626).withValues(alpha: 0.14)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark
                          ? const Color(0xFFDC2626).withValues(alpha: 0.35)
                          : const Color(0xFFFECACA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(CupertinoIcons.exclamationmark_triangle,
                        size: 18, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFB91C1C)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ||
                      selectedCount == 0 ||
                      session.retryingCandidateCount > 0
                  ? null
                  : () => _saveQuestions(_draftsForSelected(session)),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(CupertinoIcons.tray_arrow_down, size: 18),
              label: Text(_isSaving ? '正在保存...' : '保存已勾选题目 ($selectedCount)'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 8),
            Text(
              selectedCount == 0
                  ? '请至少勾选一道题后再保存。'
                  : session.retryingCandidateCount > 0
                      ? '有题正在重新解析，完成后再决定保存，避免中断本次重试。'
                      : session.failedCandidateCount > 0
                          ? '将保存已勾选的 $selectedCount 道题；${session.failedCandidateCount} 道未解析成功的题不会写入错题本。'
                          : '将保存已勾选的 $selectedCount 道题；未勾选题目不会写入错题本。',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/analysis/result'),
              icon: const Icon(CupertinoIcons.chevron_left, size: 18),
              label: const Text('返回结果页'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
            ),
          ],
        ),
      ),
    );
  }

  void _updateDraft(int index, QuestionSplitDraft updatedDraft) {
    final session = ref.read(currentQuestionSplitSessionProvider);
    if (session == null) return;

    final nextDrafts = [...session.drafts];
    nextDrafts[index] =
        updatedDraft.copyWith(text: _normalizeEditableText(updatedDraft.text));
    ref.read(currentQuestionSplitSessionProvider.notifier).state =
        session.copyWith(drafts: nextDrafts);

    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  void _setAllSelected(bool selected) {
    final session = ref.read(currentQuestionSplitSessionProvider);
    if (session == null) return;
    ref.read(currentQuestionSplitSessionProvider.notifier).state =
        session.copyWith(
      drafts: session.drafts
          .map((draft) => draft.copyWith(
                selected: draft.canSave ? selected : false,
              ))
          .toList(),
    );
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  String _displayEditableText(String text) => text
      .replaceAll(r'\\(', r'\(')
      .replaceAll(r'\\)', r'\)')
      .replaceAll(r'\\[', r'\[')
      .replaceAll(r'\\]', r'\]');

  String _normalizeEditableText(String text) => text
      .replaceAll(r'\\(', r'\(')
      .replaceAll(r'\\)', r'\)')
      .replaceAll(r'\\[', r'\[')
      .replaceAll(r'\\]', r'\]');

  List<QuestionSplitDraft> _draftsForSelected(QuestionSplitSession session) {
    return session.drafts
        .where((draft) => draft.canSave && draft.selected)
        .toList();
  }

  Future<void> _saveQuestions(List<QuestionSplitDraft> draftsToSave) async {
    final session = ref.read(currentQuestionSplitSessionProvider);
    if (session == null || _isSaving) return;

    final normalizedDrafts = draftsToSave
        .map(
            (draft) => draft.copyWith(text: _normalizeEditableText(draft.text)))
        .toList();
    if (normalizedDrafts.isEmpty) {
      setState(() => _errorMessage = '请至少选择一道解析成功的题目后再保存');
      return;
    }

    if (normalizedDrafts.any((draft) => draft.text.trim().isEmpty)) {
      setState(() => _errorMessage = '保存范围内有空内容，请补充后再保存');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final confirmed = await _confirmSave(session, normalizedDrafts.length);
    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final records = normalizedDrafts.asMap().entries.map((entry) {
        return buildSplitQuestionRecord(
          source: session.source,
          draft: entry.value,
          sortOrder: entry.value.originalOrder,
        );
      }).toList();

      await ref.read(questionRepositoryProvider).saveDrafts(records);
      try {
        await ref
            .read(scanTaskLifecycleServiceProvider)
            .completeSaved(session.source.id);
      } catch (_) {
        // The saved notebook records remain authoritative.
      }
      invalidateQuestionList(ref);
      ref.invalidate(scanTaskCountProvider);
      ref.read(currentQuestionProvider.notifier).state = records.first;
      ref.read(currentQuestionSplitSessionProvider.notifier).state = null;
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('已保存 ${records.length} 道题到错题本'),
          duration: const Duration(seconds: 2),
        ),
      );
      router.go('/notebook/question/${records.first.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = '保存失败：$e';
      });
    }
  }

  Future<bool?> _confirmSave(
    QuestionSplitSession session,
    int selectedCount,
  ) {
    if (session.failedCandidateCount == 0) return Future<bool?>.value(true);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('保存已解析题目'),
        content: Text(
          '将保存 $selectedCount 道已解析题。另 ${session.failedCandidateCount} 道未解析成功的题不会保存，本次扫描结果将结束。',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('返回处理'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('继续保存'),
          ),
        ],
      ),
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
}

class _FormulaPreviewCard extends StatelessWidget {
  const _FormulaPreviewCard({required this.content, this.contentFormat});

  final String content;
  final QuestionContentFormat? contentFormat;

  @override
  Widget build(BuildContext context) {
    final trimmed = content.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '公式预览',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          trimmed.isEmpty
              ? Text('暂无可预览内容',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))
              : MathContentView(
                  trimmed,
                  contentFormat: contentFormat,
                  style: const TextStyle(fontSize: 14),
                ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, color: textColor, fontWeight: FontWeight.w500),
      ),
    );
  }
}
