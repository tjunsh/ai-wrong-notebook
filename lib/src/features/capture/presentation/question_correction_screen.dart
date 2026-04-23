import 'dart:io';
import 'package:flutter/cupertino.dart';
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
      appBar: AppBar(
        title: const Text('题目预览'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: imagePath != null && File(imagePath).existsSync()
                ? Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.file(File(imagePath), fit: BoxFit.contain),
                    ),
                  )
                : const Center(child: Text('未选择图片', style: TextStyle(color: Colors.grey))),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/capture/crop'),
                  child: const Text('重新框选'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => context.go('/analysis/loading'),
                  child: const Text('开始分析'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
