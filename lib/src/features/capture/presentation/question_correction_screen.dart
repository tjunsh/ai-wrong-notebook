import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuestionCorrectionScreen extends StatelessWidget {
  const QuestionCorrectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('校正与框选')),
      body: const Center(child: Text('图片校正区')),
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
