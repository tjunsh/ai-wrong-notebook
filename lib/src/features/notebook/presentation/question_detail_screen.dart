import 'package:flutter/material.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

class QuestionDetailScreen extends StatelessWidget {
  const QuestionDetailScreen({super.key, required this.record});

  final QuestionRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${record.subject.label} 错题详情')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('题目：${record.correctedText}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Text('掌握状态：${record.masteryLevel.name}'),
          Text('复习次数：${record.reviewCount}'),
          const SizedBox(height: 24),
          if (record.analysisResult != null) ...<Widget>[
            Text('答案：${record.analysisResult!.finalAnswer}'),
            const SizedBox(height: 8),
            Text('错因：${record.analysisResult!.mistakeReason}'),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pushNamed('/analysis/result'),
            child: const Text('开始 AI 解析'),
          ),
        ],
      ),
    );
  }
}
