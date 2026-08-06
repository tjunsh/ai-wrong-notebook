import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

class QuestionTextCorrectionScreen extends ConsumerStatefulWidget {
  const QuestionTextCorrectionScreen({super.key});

  @override
  ConsumerState<QuestionTextCorrectionScreen> createState() =>
      _QuestionTextCorrectionScreenState();
}

class _QuestionTextCorrectionScreenState
    extends ConsumerState<QuestionTextCorrectionScreen> {
  late final TextEditingController _textController;
  String? _errorText;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: ref.read(currentQuestionProvider)?.correctedText ?? '',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = ref.watch(currentQuestionProvider);
    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('核对题干')),
        body: const Center(child: Text('未找到本次解析结果')),
      );
    }

    final note = record.analysisResult?.consistencyNote.trim() ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('核对题干'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: _submitting ? null : () => context.go('/analysis/result'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  if (File(record.imagePath).existsSync()) ...<Widget>[
                    GestureDetector(
                      onTap: () => _showFullImage(context, record.imagePath),
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(record.imagePath),
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (note.isNotEmpty) ...<Widget>[
                    Text(
                      note,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _textController,
                    minLines: 9,
                    maxLines: 16,
                    autofocus: true,
                    enabled: !_submitting,
                    onChanged: (_) {
                      if (_errorText != null) {
                        setState(() => _errorText = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: '题干',
                      alignLabelWithHint: true,
                      errorText: _errorText,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : () => _submit(record),
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(CupertinoIcons.arrow_clockwise, size: 18),
                  label: const Text('重新解析'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(QuestionRecord record) async {
    final correctedText = _textController.text.trim();
    if (correctedText.isEmpty) {
      setState(() => _errorText = '题干不能为空');
      return;
    }
    if (correctedText == record.correctedText.trim()) {
      setState(() => _errorText = '请补正或补充题干后再重新解析');
      return;
    }

    // Settle the focused text field before replacing this route.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _submitting = true);
    try {
      await ref.read(scanTaskLifecycleServiceProvider).prepareRetry(record);
      ref.read(currentQuestionSplitSessionProvider.notifier).state = null;
      ref.read(currentQuestionProvider.notifier).state =
          record.createReanalysisDraft(correctedText: correctedText);
      if (!mounted) return;

      // The provider update rebuilds this page. Deferring route replacement to
      // the next frame prevents its focused TextField from being disposed in
      // the same build scope.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      context.go('/analysis/loading');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = '无法创建重新解析任务：$error';
      });
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
            child: InteractiveViewer(child: Image.file(File(imagePath))),
          ),
        ),
      ),
    );
  }
}
