import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({super.key, required this.record});

  final QuestionRecord record;

  @override
  Widget build(BuildContext context) {
    final result = record.analysisResult;
    return Scaffold(
      appBar: AppBar(title: const Text('AI 解析结果')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (result != null) ...<Widget>[
            Text('答案：${result.finalAnswer}'),
            const SizedBox(height: 12),
            Text('错因：${result.mistakeReason}'),
            const SizedBox(height: 12),
            Text('学习建议：${result.studyAdvice}'),
          ] else
            const Text('暂无解析结果'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/notebook'),
            child: const Text('保存到错题本'),
          ),
        ],
      ),
    );
  }
}
