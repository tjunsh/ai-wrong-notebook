import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';

class QuestionCorrectionScreen extends ConsumerWidget {
  const QuestionCorrectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentQuestionProvider);
    final imagePath = current?.imagePath;

    return Scaffold(
      appBar: AppBar(title: const Text('校正与框选')),
      body: imagePath != null && File(imagePath).existsSync()
          ? Center(child: Image.file(File(imagePath), fit: BoxFit.contain))
          : const Center(child: Text('未选择图片')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                  onPressed: () => context.go('/capture/ocr-confirmation'),
                  child: const Text('继续 OCR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
