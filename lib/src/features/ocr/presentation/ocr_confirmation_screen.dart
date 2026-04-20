import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

class OcrConfirmationScreen extends ConsumerStatefulWidget {
  const OcrConfirmationScreen({super.key});

  @override
  ConsumerState<OcrConfirmationScreen> createState() => _OcrConfirmationScreenState();
}

class _OcrConfirmationScreenState extends ConsumerState<OcrConfirmationScreen> {
  late TextEditingController _textController;
  Subject _selectedSubject = Subject.math;
  bool _ocrLoading = false;
  String? _ocrError;

  @override
  void initState() {
    super.initState();
    final current = ref.read(currentQuestionProvider);
    _textController = TextEditingController(text: current?.correctedText ?? '');
    _selectedSubject = current?.subject ?? Subject.math;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentQuestionProvider);
    final hasImage = current?.imagePath != null && File(current!.imagePath).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('识别确认'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.go('/capture/correction'),
        ),
      ),
      body: Column(
        children: <Widget>[
          if (hasImage)
            GestureDetector(
              onTap: () => _showFullImage(context, current.imagePath),
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Image.file(
                  File(current.imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                Text('学科', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Subject>(
                      value: _selectedSubject,
                      isDense: true,
                      isExpanded: true,
                      items: Subject.values.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedSubject = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('识别文本', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (_ocrLoading)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        else
                          TextButton.icon(
                            onPressed: _runOcr,
                            icon: const Icon(CupertinoIcons.text_cursor, size: 16),
                            label: const Text('识别文字'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1), visualDensity: VisualDensity.compact),
                          ),
                        if (_textController.text.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              _textController.clear();
                              setState(() {});
                            },
                            icon: const Icon(CupertinoIcons.xmark_circle, size: 16),
                            label: const Text('清除'),
                            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600, visualDensity: VisualDensity.compact),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextFormField(
                    controller: _textController,
                    maxLines: 8,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: '请输入或修正识别的题目文本',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.all(14),
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: FilledButton(
            onPressed: _textController.text.trim().isEmpty ? null : _submit,
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            child: const Text('开始 AI 解析'),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final current = ref.read(currentQuestionProvider);
    if (current != null) {
      ref.read(currentQuestionProvider.notifier).state = current.copyWith(
        correctedText: _textController.text.trim(),
        subject: _selectedSubject,
      );
    }
    context.go('/analysis/loading');
  }

  Future<void> _runOcr() async {
    final current = ref.read(currentQuestionProvider);
    if (current == null) return;

    setState(() {
      _ocrLoading = true;
      _ocrError = null;
    });

    try {
      final ocr = ref.read(ocrServiceProvider);
      final text = await ocr.recognizeImage(current.imagePath);

      if (!mounted) return;
      setState(() => _ocrLoading = false);

      if (text.isNotEmpty) {
        setState(() {
          _textController.text = text;
        });
      } else {
        setState(() => _ocrError = '未识别到文字，请手动输入');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ocrLoading = false;
        _ocrError = '识别失败: $e';
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
            child: InteractiveViewer(
              child: Image.file(File(imagePath)),
            ),
          ),
        ),
      ),
    );
  }
}
