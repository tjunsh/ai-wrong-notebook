import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';

class AnalysisResultScreen extends ConsumerWidget {
  const AnalysisResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(currentQuestionProvider);

    if (record == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AI 解析结果'),
          leading: IconButton(
            icon: const Icon(CupertinoIcons.chevron_left),
            onPressed: () => context.go('/capture/ocr-confirmation'),
          ),
        ),
        body: const Center(child: Text('未找到错题记录')),
      );
    }

    final result = record.analysisResult;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 解析结果'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.go('/capture/ocr-confirmation'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          // 统一标签分类框：科目 | AI识别 | 状态 | 知识点
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 第一行：科目 + AI识别 + 状态
                Row(
                  children: <Widget>[
                    _TagChip(
                      label: result?.subject?.label ?? record.subject.label,
                      bgColor: const Color(0xFFEEF2FF),
                      textColor: const Color(0xFF4F46E5),
                    ),
                    if (result?.subject != null) ...<Widget>[
                      const SizedBox(width: 8),
                      _TagChip(
                        label: 'AI识别',
                        bgColor: const Color(0xFFF0FDF4),
                        textColor: const Color(0xFF16A34A),
                      ),
                    ],
                    const SizedBox(width: 8),
                    _TagChip(
                      label: _masteryLabel(record.masteryLevel),
                      bgColor: _masteryColor(record.masteryLevel).withValues(alpha: 0.1),
                      textColor: _masteryColor(record.masteryLevel),
                    ),
                  ],
                ),
                // AI 短标签（橙色）
                if (record.aiTags.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Text('AI标签', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: record.aiTags.map((tag) => _TagChip(
                      label: tag,
                      bgColor: const Color(0xFFFFF7ED),
                      textColor: const Color(0xFFD97706),
                    )).toList(),
                  ),
                ],
                // 自定义标签（蓝色）
                if (record.customTags.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text('自定义标签', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: record.customTags.map((t) => _TagChip(
                      label: t,
                      bgColor: const Color(0xFFEEF2FF),
                      textColor: const Color(0xFF4F46E5),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(record.correctedText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          if (result == null) ...<Widget>[
            const SizedBox(height: 40),
            Center(child: Text('暂无解析结果', style: TextStyle(color: Colors.grey.shade500))),
          ],
          if (result != null) ...<Widget>[
            const SizedBox(height: 20),
            // 原题（包含图片和文本）
            _SectionCard(
              icon: CupertinoIcons.doc_text,
              iconColor: const Color(0xFF6366F1),
              bg: const Color(0xFFEEF2FF),
              border: const Color(0xFFC7D2FE),
              title: '原题',
              titleColor: const Color(0xFF4338CA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 图片预览
                  if (File(record.imagePath).existsSync())
                    GestureDetector(
                      onTap: () => _showFullImage(context, record.imagePath),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(record.imagePath),
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(CupertinoIcons.zoom_in, size: 12, color: Colors.white),
                                    SizedBox(width: 3),
                                    Text('查看原图', style: TextStyle(fontSize: 10, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (File(record.imagePath).existsSync()) const SizedBox(height: 10),
                  Text(
                    record.correctedText,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF3730A3)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Answer
            _SectionCard(
              icon: CupertinoIcons.checkmark_circle,
              iconColor: const Color(0xFF16A34A),
              bg: const Color(0xFFF0FDF4),
              border: const Color(0xFFBBF7D0),
              title: '正确解答',
              titleColor: const Color(0xFF166534),
              content: result.finalAnswer,
              contentColor: const Color(0xFF15803D),
              contentWeight: FontWeight.w600,
            ),
            const SizedBox(height: 10),
            // Mistake reason
            _SectionCard(
              icon: CupertinoIcons.exclamationmark_triangle,
              iconColor: const Color(0xFFEA580C),
              bg: const Color(0xFFFFF7ED),
              border: const Color(0xFFFED7AA),
              title: '错因分析',
              titleColor: const Color(0xFF9A3412),
              content: result.mistakeReason,
              contentColor: const Color(0xFFC2410C),
            ),
            const SizedBox(height: 10),
            // Study advice
            _SectionCard(
              icon: CupertinoIcons.lightbulb,
              iconColor: const Color(0xFFD97706),
              bg: const Color(0xFFFFFBEB),
              border: const Color(0xFFFDE68A),
              title: '学习建议',
              titleColor: const Color(0xFF92400E),
              content: result.studyAdvice,
              contentColor: const Color(0xFFB45309),
            ),
            // Knowledge points
            if (result.knowledgePoints.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Text('知识点', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: result.knowledgePoints.map((p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Text(p, style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5))),
                )).toList(),
              ),
            ],
            // Steps
            if (result.steps.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Text('解题步骤', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ...result.steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.value, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              )),
            ],
            // Exercises
            if (result.generatedExercises.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('举一反三', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  Text('${result.generatedExercises.length} 题', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
              const SizedBox(height: 10),
              ...result.generatedExercises.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _difficultyColor(e.difficulty).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              e.difficulty,
                              style: TextStyle(
                                fontSize: 11,
                                color: _difficultyColor(e.difficulty),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (e.isCorrect == true)
                            const Icon(CupertinoIcons.checkmark_circle, color: Color(0xFF16A34A), size: 18)
                          else if (e.isCorrect == false)
                            const Icon(CupertinoIcons.xmark_circle, color: Color(0xFFEA580C), size: 18),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(e.question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Icon(CupertinoIcons.lightbulb, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text('答案：${e.answer}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                      if (e.explanation.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(e.explanation, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
                  child: OutlinedButton(
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
                      // 调试：显示保存时的信息
                      debugPrint('[AnalysisResult] Saving question:');
                      debugPrint('[AnalysisResult] - id: ${record.id}');
                      debugPrint('[AnalysisResult] - imagePath: ${record.imagePath}');
                      debugPrint('[AnalysisResult] - correctedText: ${record.correctedText}');
                      debugPrint('[AnalysisResult] - analysisResult: ${record.analysisResult != null}');

                      await ref.read(questionRepositoryProvider).saveDraft(record);
                      invalidateQuestionList(ref);
                      ref.read(currentQuestionProvider.notifier).state = null;
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已保存到错题本！\n图片: ${record.imagePath.isNotEmpty ? "有" : "无"}'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        context.go('/notebook');
                      }
                    },
                    child: const Text('保存到错题本'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case '简单': return Colors.green;
      case '中等': return Colors.orange;
      case '困难': return Colors.red;
      case '提高': return const Color(0xFF7C3AED);
      case '同级': return Colors.blue;
      default: return Colors.grey;
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.border,
    required this.title,
    required this.titleColor,
    this.content,
    this.contentColor,
    this.contentWeight = FontWeight.normal,
    this.child,
  });

  final IconData icon;
  final Color iconColor;
  final Color bg;
  final Color border;
  final String title;
  final Color titleColor;
  final String? content;
  final Color? contentColor;
  final FontWeight contentWeight;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: titleColor)),
            ],
          ),
          const SizedBox(height: 10),
          if (child != null)
            child!
          else
            Text(content ?? '', style: TextStyle(fontSize: 14, color: contentColor, fontWeight: contentWeight)),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.bgColor, required this.textColor});

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500)),
    );
  }
}

String _masteryLabel(MasteryLevel level) {
  switch (level) {
    case MasteryLevel.newQuestion: return '未复习';
    case MasteryLevel.reviewing: return '复习中';
    case MasteryLevel.mastered: return '已掌握';
  }
}

Color _masteryColor(MasteryLevel level) {
  switch (level) {
    case MasteryLevel.newQuestion: return Colors.grey;
    case MasteryLevel.reviewing: return Colors.orange;
    case MasteryLevel.mastered: return Colors.green;
  }
}
