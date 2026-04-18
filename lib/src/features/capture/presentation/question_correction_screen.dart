import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';

class QuestionCorrectionScreen extends ConsumerStatefulWidget {
  const QuestionCorrectionScreen({super.key});

  @override
  ConsumerState<QuestionCorrectionScreen> createState() => _QuestionCorrectionScreenState();
}

class _QuestionCorrectionScreenState extends ConsumerState<QuestionCorrectionScreen> {
  bool _ocrLoading = false;
  String? _ocrError;

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentQuestionProvider);
    final imagePath = current?.imagePath;

    return Scaffold(
      appBar: AppBar(title: const Text('校正与框选')),
      body: Stack(
        children: <Widget>[
          if (imagePath != null && File(imagePath).existsSync())
            Center(child: Image.file(File(imagePath), fit: BoxFit.contain))
          else
            const Center(child: Text('未选择图片')),
          if (_ocrLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text('正在识别文字...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (_ocrError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_ocrError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('重置'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('旋转'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _ocrLoading ? null : _runOcr,
                      child: const Text('继续 OCR'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

      if (text.isEmpty) {
        if (mounted) setState(() => _ocrError = '未识别到文字，请手动输入');
        return;
      }

      ref.read(currentQuestionProvider.notifier).state = current.copyWith(
        correctedText: text,
      );

      if (mounted) context.go('/capture/ocr-confirmation');
    } catch (e) {
      if (mounted) setState(() => _ocrError = 'OCR 失败: $e');
    } finally {
      if (mounted) setState(() => _ocrLoading = false);
    }
  }
}
