import 'dart:convert';
import 'dart:io';

import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/repositories/analysis_job_repository.dart';

class ScanTaskLifecycleService {
  const ScanTaskLifecycleService({
    required AnalysisJobRepository? analysisJobs,
    required QuestionRepository questions,
  })  : _analysisJobs = analysisJobs,
        _questions = questions;

  final AnalysisJobRepository? _analysisJobs;
  final QuestionRepository _questions;

  Future<int> countTasks() async {
    final jobs = await _analysisJobs?.listAll() ?? const <AnalysisJob>[];
    return jobs.map((job) => job.taskSpec.parentQuestionId).toSet().length;
  }

  Future<void> completeSaved(String sourceQuestionId) async {
    await _analysisJobs?.deleteByParentQuestionId(sourceQuestionId);
  }

  Future<void> prepareRetry(QuestionRecord source) async {
    await _analysisJobs?.deleteByParentQuestionId(source.id);
  }

  Future<void> discard(QuestionRecord source) async {
    await _analysisJobs?.deleteByParentQuestionId(source.id);
    await _deleteImageIfUnreferenced(source.imagePath);
  }

  Future<void> clearAllTasks() async {
    final jobs = await _analysisJobs?.listAll() ?? const <AnalysisJob>[];
    final temporaryImagePaths = jobs
        .map(_imagePathFromJob)
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .toSet();

    await _analysisJobs?.clearAll();

    final savedImagePaths = (await _questions.listAll())
        .map((question) => question.imagePath)
        .where((path) => path.isNotEmpty)
        .toSet();
    for (final path in temporaryImagePaths.difference(savedImagePaths)) {
      await _deleteFile(path);
    }
  }

  Future<void> _deleteImageIfUnreferenced(String path) async {
    if (path.isEmpty) return;
    final isSaved = (await _questions.listAll())
        .any((question) => question.imagePath == path);
    if (isSaved) return;

    final isUsedByAnotherTask =
        (await _analysisJobs?.listAll() ?? const <AnalysisJob>[])
            .any((job) => _imagePathFromJob(job) == path);
    if (!isUsedByAnotherTask) await _deleteFile(path);
  }

  String? _imagePathFromJob(AnalysisJob job) {
    try {
      final payload = jsonDecode(job.payloadJson);
      if (payload is! Map) return null;
      final directPath = payload['imagePath'];
      if (directPath is String && directPath.isNotEmpty) return directPath;
      final question = payload['question'];
      if (question is Map) {
        final path = question['imagePath'];
        if (path is String && path.isNotEmpty) return path;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> _deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Database cleanup must still succeed if a temporary file is unavailable.
    }
  }
}
