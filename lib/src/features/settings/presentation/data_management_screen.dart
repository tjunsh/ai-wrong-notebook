import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

class DataManagementScreen extends ConsumerWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('数据管理')),
      body: questionsAsync.when(
        data: (questions) => ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('题库总量'),
                trailing: Text('${questions.length} 题', style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.upload_outlined),
                title: const Text('导入错题'),
                subtitle: const Text('从 JSON 文件导入错题记录'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _importQuestions(context, ref),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('导出当前题库'),
                subtitle: const Text('导出所有错题为 JSON 文件，可分享'),
                trailing: const Icon(Icons.chevron_right),
                onTap: questions.isEmpty ? null : () => _exportQuestions(context, questions),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('清空所有数据', style: TextStyle(color: Colors.red)),
                subtitle: const Text('删除所有错题记录，不可恢复'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _confirmClearAll(context, ref, questions.length),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Future<void> _exportQuestions(BuildContext context, List<QuestionRecord> questions) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${dir.path}/exports');
      if (!exportDir.existsSync()) {
        await exportDir.create(recursive: true);
      }

      final now = DateTime.now();
      final ms = now.millisecond;
      final filename = 'wrong_notebook_$ms.json';
      final file = File('${exportDir.path}/$filename');

      final list = questions.map(_questionToJson).toList();
      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(list));

      if (!context.mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: '导出 ${questions.length} 道错题');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _questionToJson(QuestionRecord q) {
    final exercises = q.analysisResult?.generatedExercises.map((e) => {
      'id': e.id,
      'difficulty': e.difficulty,
      'question': e.question,
      'answer': e.answer,
      'explanation': e.explanation,
      'isCorrect': e.isCorrect,
    }).toList();

    return {
      'id': q.id,
      'subject': q.subject.name,
      'recognizedText': q.recognizedText,
      'correctedText': q.correctedText,
      'tags': q.tags,
      'contentStatus': q.contentStatus.name,
      'masteryLevel': q.masteryLevel.name,
      'isFavorite': q.isFavorite,
      'reviewCount': q.reviewCount,
      'createdAt': q.createdAt.toIso8601String(),
      'updatedAt': q.updatedAt.toIso8601String(),
      'lastReviewedAt': q.lastReviewedAt?.toIso8601String(),
      'analysisResult': q.analysisResult != null
          ? {
              'finalAnswer': q.analysisResult!.finalAnswer,
              'steps': q.analysisResult!.steps,
              'knowledgePoints': q.analysisResult!.knowledgePoints,
              'mistakeReason': q.analysisResult!.mistakeReason,
              'studyAdvice': q.analysisResult!.studyAdvice,
              'generatedExercises': exercises,
            }
          : null,
    };
  }

  Future<void> _importQuestions(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final list = jsonDecode(content) as List;
      final repo = ref.read(questionRepositoryProvider);
      int imported = 0;

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final record = _jsonToQuestion(map);
        if (record != null) {
          await repo.saveDraft(record);
          imported++;
        }
      }

      invalidateQuestionList(ref);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功导入 $imported 道错题')),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  QuestionRecord? _jsonToQuestion(Map<String, dynamic> map) {
    try {
      final analysisMap = map['analysisResult'] as Map<String, dynamic>?;
      List<GeneratedExercise>? exercises;
      if (analysisMap != null) {
        final exList = analysisMap['generatedExercises'] as List?;
        if (exList != null) {
          exercises = exList.map((e) {
            final em = e as Map<String, dynamic>;
            return GeneratedExercise(
              id: em['id'] as String? ?? '',
              difficulty: em['difficulty'] as String? ?? '',
              question: em['question'] as String? ?? '',
              answer: em['answer'] as String? ?? '',
              explanation: em['explanation'] as String? ?? '',
              isCorrect: em['isCorrect'] as bool?,
            );
          }).toList();
        }
      }

      return QuestionRecord(
        id: map['id'] as String? ?? '',
        imagePath: map['imagePath'] as String? ?? '',
        subject: Subject.values.firstWhere(
          (s) => s.name == map['subject'],
          orElse: () => Subject.math,
        ),
        recognizedText: map['recognizedText'] as String? ?? '',
        correctedText: map['correctedText'] as String? ?? '',
        tags: List<String>.from(map['tags'] as List? ?? []),
        contentStatus: ContentStatus.values.firstWhere(
          (s) => s.name == map['contentStatus'],
          orElse: () => ContentStatus.processing,
        ),
        masteryLevel: MasteryLevel.values.firstWhere(
          (m) => m.name == map['masteryLevel'],
          orElse: () => MasteryLevel.newQuestion,
        ),
        isFavorite: map['isFavorite'] as bool? ?? false,
        reviewCount: map['reviewCount'] as int? ?? 0,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
        lastReviewedAt: map['lastReviewedAt'] != null
            ? DateTime.tryParse(map['lastReviewedAt'] as String)
            : null,
        analysisResult: analysisMap != null
            ? AnalysisResult(
                finalAnswer: analysisMap['finalAnswer'] as String? ?? '',
                steps: List<String>.from(analysisMap['steps'] as List? ?? []),
                knowledgePoints: List<String>.from(analysisMap['knowledgePoints'] as List? ?? []),
                mistakeReason: analysisMap['mistakeReason'] as String? ?? '',
                studyAdvice: analysisMap['studyAdvice'] as String? ?? '',
                generatedExercises: exercises ?? [],
              )
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref, int count) {
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('题库为空，无需清空')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清空'),
        content: Text('确定要删除全部 $count 道错题吗？此操作不可恢复。'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearAllData(ref, context);
            },
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData(WidgetRef ref, BuildContext context) async {
    final repo = ref.read(questionRepositoryProvider);
    final all = await repo.listAll();
    for (final q in all) {
      await repo.delete(q.id);
    }
    invalidateQuestionList(ref);
    ref.read(currentQuestionProvider.notifier).state = null;

    try {
      for (final q in all) {
        final file = File(q.imagePath);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已清空 ${all.length} 道错题')),
      );
    }
  }
}
