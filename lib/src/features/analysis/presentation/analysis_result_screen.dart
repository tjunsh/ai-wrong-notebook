import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';

class AnalysisResultScreen extends ConsumerWidget {
  const AnalysisResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(currentQuestionProvider);

    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI 解析结果')),
        body: const Center(child: Text('未找到错题记录')),
      );
    }

    final result = record.analysisResult;
    return Scaffold(
      appBar: AppBar(title: const Text('AI 解析结果')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // Question preview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Chip(label: Text(record.subject.label), visualDensity: VisualDensity.compact),
                      const Spacer(),
                      if (File(record.imagePath).existsSync())
                        GestureDetector(
                          onTap: () => _showFullImage(context, record.imagePath),
                          child: const Icon(Icons.image_outlined, size: 18, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(record.correctedText, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (result != null) ...<Widget>[
            _SectionCard(
              title: '正确答案',
              icon: Icons.check_circle_outline,
              iconColor: Colors.green,
              child: Text(result.finalAnswer, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: '错因分析',
              icon: Icons.error_outline,
              iconColor: Colors.red,
              child: Text(result.mistakeReason),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: '学习建议',
              icon: Icons.lightbulb_outline,
              iconColor: Colors.amber,
              child: Text(result.studyAdvice),
            ),
            const SizedBox(height: 12),
            if (result.knowledgePoints.isNotEmpty)
              _SectionCard(
                title: '知识点',
                icon: Icons.psychology_outlined,
                iconColor: Colors.blue,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: result.knowledgePoints.map((p) => Chip(label: Text(p), visualDensity: VisualDensity.compact)).toList(),
                ),
              ),
            if (result.knowledgePoints.isNotEmpty) const SizedBox(height: 12),
            if (result.steps.isNotEmpty) ...<Widget>[
              _SectionCard(
                title: '解题步骤',
                icon: Icons.format_list_numbered,
                iconColor: Colors.indigo,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: result.steps.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            '${e.key + 1}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.value)),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (result.generatedExercises.isNotEmpty) ...<Widget>[
              Text('举一反三', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...result.generatedExercises.map((e) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _difficultyColor(e.difficulty).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              e.difficulty,
                              style: TextStyle(
                                fontSize: 12,
                                color: _difficultyColor(e.difficulty),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (e.isCorrect == true)
                            const Icon(Icons.check_circle, color: Colors.green, size: 18)
                          else if (e.isCorrect == false)
                            const Icon(Icons.cancel, color: Colors.red, size: 18),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(e.question, style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          const Icon(Icons.lightbulb_outline, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('答案：${e.answer}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                      if (e.explanation.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(e.explanation, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ],
                  ),
                ),
              )),
            ],
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () {
                      ref.read(currentQuestionProvider.notifier).state = record;
                      context.go('/exercise/practice');
                    },
                    child: const Text('开始练习'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await ref.read(questionRepositoryProvider).saveDraft(record);
                      invalidateQuestionList(ref);
                      ref.read(currentQuestionProvider.notifier).state = null;
                      if (context.mounted) context.go('/notebook');
                    },
                    child: const Text('保存到错题本'),
                  ),
                ),
              ],
            ),
          ] else
            const Center(child: Text('暂无解析结果', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case '简单': return Colors.green;
      case '中等': return Colors.orange;
      case '困难': return Colors.red;
      case '提高': return Colors.purple;
      case '同级': return Colors.blue;
      default: return Colors.grey;
    }
  }

  void _showFullImage(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
          body: Center(child: InteractiveViewer(child: Image.file(File(imagePath)))),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.iconColor, required this.child});

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
