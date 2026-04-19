import 'dart:io';
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
      appBar: AppBar(title: const Text('识别确认')),
      body: Column(
        children: <Widget>[
          if (hasImage && current != null)
            GestureDetector(
              onTap: () => _showFullImage(context, current.imagePath),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey.shade100,
                child: Image.file(
                  File(current.imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  DropdownButtonFormField<Subject>(
                    value: _selectedSubject,
                    decoration: const InputDecoration(
                      labelText: '学科',
                      border: OutlineInputBorder(),
                    ),
                    items: Subject.values.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.label),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedSubject = v ?? Subject.math),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        labelText: '识别文本',
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                        suffixIcon: _textController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _textController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _textController.text.trim().isEmpty ? null : _submit,
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
