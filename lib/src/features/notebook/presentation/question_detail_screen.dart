import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/features/review/presentation/review_controller.dart';

class QuestionDetailScreen extends ConsumerWidget {
  const QuestionDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentQuestionProvider);

    if (current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('错题详情')),
        body: const Center(child: Text('未找到该错题')),
      );
    }

    final result = current.analysisResult;
    final masteryColor = _masteryColor(current.masteryLevel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('错题详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/notebook'),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editQuestion(context, ref, current),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _confirmDelete(context, ref, current);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          // Question preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Hero(
                      tag: 'subject_icon_${current.id}',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(current.subject.label, style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Hero(
                      tag: 'mastery_${current.id}',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: masteryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(_masteryLabel(current.masteryLevel), style: TextStyle(fontSize: 12, color: masteryColor, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Hero(
                  tag: 'question_text_${current.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(current.correctedText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ),
          if (result == null) ...<Widget>[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: <Widget>[
                  Icon(Icons.auto_awesome_outlined, size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('暂无 AI 解析结果', style: TextStyle(fontSize: 15)),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(currentQuestionProvider.notifier).state = current;
                      context.go('/capture/correction');
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('去添加'),
                  ),
                ],
              ),
            ),
          ],
          if (result != null) ...<Widget>[
            const SizedBox(height: 16),
            // Answer
            _InfoCard(
              icon: Icons.check_circle,
              iconColor: const Color(0xFF16A34A),
              bg: const Color(0xFFF0FDF4),
              border: const Color(0xFFBBF7D0),
              title: '正确答案',
              titleColor: const Color(0xFF166534),
              value: result.finalAnswer,
              valueColor: const Color(0xFF15803D),
            ),
            const SizedBox(height: 10),
            // Mistake reason
            _InfoCard(
              icon: Icons.error_outline,
              iconColor: const Color(0xFFEA580C),
              bg: const Color(0xFFFFF7ED),
              border: const Color(0xFFFED7AA),
              title: '错因分析',
              titleColor: const Color(0xFF9A3412),
              value: result.mistakeReason,
              valueColor: const Color(0xFFC2410C),
            ),
            const SizedBox(height: 10),
            // Study advice
            _InfoCard(
              icon: Icons.lightbulb_outline,
              iconColor: const Color(0xFFD97706),
              bg: const Color(0xFFFFFBEB),
              border: const Color(0xFFFDE68A),
              title: '学习建议',
              titleColor: const Color(0xFF92400E),
              value: result.studyAdvice,
              valueColor: const Color(0xFFB45309),
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
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _markResult(context, ref, current, false),
                    child: const Text('仍需复习'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _markResult(context, ref, current, true),
                    child: const Text('已掌握'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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

  void _editQuestion(BuildContext context, WidgetRef ref, QuestionRecord question) {
    final controller = TextEditingController(text: question.correctedText);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑题目'),
        content: TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final updated = question.copyWith(correctedText: controller.text.trim());
              await ref.read(questionRepositoryProvider).update(updated);
              ref.read(currentQuestionProvider.notifier).state = updated;
              invalidateQuestionList(ref);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, QuestionRecord question) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，确定要删除这道错题吗？'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              await ref.read(questionRepositoryProvider).delete(question.id);
              invalidateQuestionList(ref);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) context.go('/notebook');
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _markResult(BuildContext context, WidgetRef ref, QuestionRecord question, bool mastered) async {
    final controller = ReviewController(repository: ref.read(questionRepositoryProvider));
    final updated = mastered
        ? await controller.markMastered(question.id)
        : await controller.markReviewing(question.id);
    invalidateQuestionList(ref);
    ref.read(currentQuestionProvider.notifier).state = updated;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mastered ? '已标记为已掌握' : '已标记为复习中')),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.iconColor, required this.bg, required this.border, required this.title, required this.titleColor, required this.value, required this.valueColor});

  final IconData icon;
  final Color iconColor;
  final Color bg;
  final Color border;
  final String title;
  final Color titleColor;
  final String value;
  final Color valueColor;

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
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 14, color: valueColor)),
        ],
      ),
    );
  }
}
