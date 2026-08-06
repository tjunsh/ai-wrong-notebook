import 'dart:convert';

import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/data/services/question_analysis_pipeline.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/repositories/analysis_job_repository.dart';
import 'package:smart_wrong_notebook/src/domain/services/analysis_job_queue_executor.dart';
import 'package:smart_wrong_notebook/src/domain/services/exercise_round_service.dart';

class AppAnalysisJobRunner implements AnalysisJobRunner {
  const AppAnalysisJobRunner(
    this._service, {
    QuestionRepository? questionRepository,
    AnalysisJobRepository? analysisJobRepository,
  })  : _questionRepository = questionRepository,
        _analysisJobRepository = analysisJobRepository;

  final AiAnalysisService _service;
  final QuestionRepository? _questionRepository;
  final AnalysisJobRepository? _analysisJobRepository;

  @override
  Future<String> run(AnalysisJobExecutionContext context) async {
    try {
      final payload = _decodeMap(context.job.payloadJson);
      switch (context.job.taskSpec.type) {
        case AiTaskType.extraction:
          await context.reportProgress(const AnalysisJobProgress(
            stage: AnalysisJobProgressStage.recognizing,
          ));
          return _runExtraction(payload);
        case AiTaskType.independentQuestionSplit:
          return _runIndependentQuestionSplit(payload);
        case AiTaskType.firstPassAnalysis:
          await context.reportProgress(const AnalysisJobProgress(
            stage: AnalysisJobProgressStage.analyzing,
          ));
          return _runFirstPass(payload, context);
        case AiTaskType.candidateAnalysisRetry:
          return _runCandidateAnalysisRetry(payload, context);
        case AiTaskType.followUp:
          return _runFollowUp(payload);
        case AiTaskType.exerciseGeneration:
          return _runExerciseGeneration(payload);
        case AiTaskType.answerJudgement:
          return _runAnswerJudgement(payload);
        case AiTaskType.deepAnalysis:
        case AiTaskType.verification:
          throw const AnalysisJobExecutionException(
            '当前版本尚未配置可用的深度分析路由。',
            retryable: false,
          );
      }
    } on AnalysisJobExecutionException {
      rethrow;
    } on AiAnalysisException catch (error) {
      // AiAnalysisService already owns its bounded network retry/fallback.
      throw AnalysisJobExecutionException(
        error.toString(),
        retryable: false,
      );
    } catch (error) {
      throw AnalysisJobExecutionException(
        'AI 任务数据或执行结果异常: $error',
        retryable: false,
      );
    }
  }

  Future<String> _runExtraction(Map<String, dynamic> payload) async {
    final extraction = await _service.extractQuestionStructure(
      subjectName: payload['subjectName'] as String? ?? '',
      imagePath: payload['imagePath'] as String? ?? '',
      textHint: payload['textHint'] as String? ?? '',
    );
    return jsonEncode(extraction.toJson());
  }

  Future<String> _runIndependentQuestionSplit(
    Map<String, dynamic> payload,
  ) async {
    final splitResult = await _service.splitQuestionCandidates(
      text: payload['text'] as String? ?? '',
      subjectName: payload['subjectName'] as String? ?? '',
    );
    return jsonEncode(splitResult.toJson());
  }

  Future<String> _runFirstPass(
    Map<String, dynamic> payload,
    AnalysisJobExecutionContext context,
  ) async {
    final question = QuestionRecord.fromJson(
      _mapValue(payload['question']),
    );
    AiQuestionExtractionResult? extraction;
    for (final resultJson in context.dependencyResults.values) {
      final result = _decodeMap(resultJson);
      if (result.containsKey('extractedQuestionText')) {
        extraction = AiQuestionExtractionResult.fromJson(result);
        break;
      }
    }
    var progressWrites = Future<void>.value();
    AnalysisJobProgress? candidateProgress;
    late final QuestionRecord updated;
    try {
      updated = await QuestionAnalysisPipeline(_service).analyze(
        question,
        extractionResult: extraction,
        onProgress: (completed, total, {int failed = 0}) {
          final nextProgress = AnalysisJobProgress(
            stage: AnalysisJobProgressStage.analyzingCandidates,
            completedUnits: completed,
            totalUnits: total,
            failedUnits: failed,
          );
          candidateProgress = nextProgress;
          progressWrites = progressWrites.then(
            (_) => context.reportProgress(nextProgress),
          );
        },
      );
    } finally {
      await progressWrites;
    }
    await context.reportProgress(AnalysisJobProgress(
      stage: AnalysisJobProgressStage.finalizing,
      completedUnits: candidateProgress?.completedUnits ?? 0,
      totalUnits: candidateProgress?.totalUnits ?? 0,
      failedUnits: candidateProgress?.failedUnits ?? 0,
    ));
    return jsonEncode(updated.toJson());
  }

  Future<String> _runCandidateAnalysisRetry(
    Map<String, dynamic> payload,
    AnalysisJobExecutionContext context,
  ) async {
    final parentJobId = payload['parentFirstPassJobId'] as String? ?? '';
    final candidateId = payload['candidateId'] as String? ?? '';
    final sourceJson = context.dependencyResults[parentJobId];
    if (parentJobId.isEmpty || candidateId.isEmpty || sourceJson == null) {
      throw const AnalysisJobExecutionException(
        '未找到待重试子题的原始解析结果。',
        retryable: false,
      );
    }

    final source = QuestionRecord.fromJson(_decodeMap(sourceJson));
    final candidate = source.splitResult?.candidates
        .where((item) => item.id == candidateId)
        .cast<QuestionSplitCandidate?>()
        .firstWhere((item) => item != null, orElse: () => null);
    if (candidate == null) {
      throw const AnalysisJobExecutionException(
        '未找到待重试的子题内容。',
        retryable: false,
      );
    }

    try {
      final result = await _service.retrySplitCandidate(
        questionId: source.id,
        subjectName: source.subject.name,
        candidate: candidate,
        imagePath: source.imagePath,
      );
      final updated = _mergeCandidateResult(source, result);
      final persisted = await _analysisJobRepository?.replaceCompletedResult(
        parentJobId,
        resultJson: jsonEncode(updated.toJson()),
      );
      if (persisted != true) {
        throw const AnalysisJobExecutionException(
          '原扫描记录已不存在，重试结果未保存。',
          retryable: false,
        );
      }
      return jsonEncode(<String, dynamic>{
        'candidateId': result.candidateId,
        'order': result.order,
      });
    } catch (error) {
      await _persistCandidateFailure(
        parentJobId: parentJobId,
        source: source,
        candidateId: candidateId,
        error: error,
      );
      rethrow;
    }
  }

  Future<void> _persistCandidateFailure({
    required String parentJobId,
    required QuestionRecord source,
    required String candidateId,
    required Object error,
  }) async {
    final updated = source.copyWith(
      candidateAnalyses: source.candidateAnalyses.map((candidate) {
        if (candidate.candidateId != candidateId) return candidate;
        return CandidateAnalysisSnapshot(
          candidateId: candidate.candidateId,
          order: candidate.order,
          questionText: candidate.questionText,
          savedExercises: candidate.savedExercises,
          subject: candidate.subject,
          aiTags: candidate.aiTags,
          aiKnowledgePoints: candidate.aiKnowledgePoints,
          status: CandidateAnalysisStatus.failed,
          errorMessage: error.toString(),
        );
      }).toList(growable: false),
    );
    await _analysisJobRepository?.replaceCompletedResult(
      parentJobId,
      resultJson: jsonEncode(updated.toJson()),
    );
  }

  QuestionRecord _mergeCandidateResult(
    QuestionRecord source,
    CandidateAnalysisPayload result,
  ) {
    return source.copyWith(
      candidateAnalyses: source.candidateAnalyses.map((candidate) {
        if (candidate.candidateId != result.candidateId) return candidate;
        return CandidateAnalysisSnapshot(
          candidateId: candidate.candidateId,
          order: candidate.order,
          questionText: candidate.questionText,
          analysisResult: result.analysisResult,
          savedExercises: candidate.savedExercises,
          subject: result.subject ?? candidate.subject,
          aiTags: result.aiTags,
          aiKnowledgePoints: result.aiKnowledgePoints,
          status: CandidateAnalysisStatus.success,
        );
      }).toList(growable: false),
    );
  }

  Future<String> _runFollowUp(Map<String, dynamic> payload) async {
    final history = (payload['history'] as List? ?? const <Object>[])
        .whereType<Map>()
        .map((item) => AiFollowUpMessage(
              role: item['role']?.toString() ?? 'user',
              content: item['content']?.toString() ?? '',
            ))
        .toList(growable: false);
    final answer = await _service.answerQuestionFollowUp(
      question: QuestionRecord.fromJson(_mapValue(payload['question'])),
      userQuestion: payload['userQuestion'] as String? ?? '',
      history: history,
    );
    return jsonEncode(<String, dynamic>{'answer': answer});
  }

  Future<String> _runExerciseGeneration(Map<String, dynamic> payload) async {
    final payloadQuestion =
        QuestionRecord.fromJson(_mapValue(payload['question']));
    final forceNew = payload['forceNew'] as bool? ?? false;
    final latestQuestion =
        await _questionRepository?.getById(payloadQuestion.id) ??
            payloadQuestion;
    if (!forceNew && latestQuestion.savedExercises.isNotEmpty) {
      return _encodeExercises(latestQuestion.savedExercises);
    }

    final exercises =
        await _service.generateExercisesForQuestion(latestQuestion);
    if (exercises.isNotEmpty && _questionRepository != null) {
      final refreshed = await _questionRepository.getById(latestQuestion.id) ??
          latestQuestion;
      if (!forceNew && refreshed.savedExercises.isNotEmpty) {
        return _encodeExercises(refreshed.savedExercises);
      }
      final updatedExercises = appendGeneratedExerciseRound(
        questionId: refreshed.id,
        existingExercises: refreshed.savedExercises,
        generatedExercises: exercises,
      );
      if (updatedExercises.length != refreshed.savedExercises.length) {
        await _questionRepository.update(
          refreshed.copyWith(savedExercises: updatedExercises),
        );
        return _encodeExercises(updatedExercises);
      } else {
        return _encodeExercises(refreshed.savedExercises);
      }
    }
    if (forceNew) {
      return _encodeExercises(appendGeneratedExerciseRound(
        questionId: latestQuestion.id,
        existingExercises: latestQuestion.savedExercises,
        generatedExercises: exercises,
      ));
    }
    return _encodeExercises(appendGeneratedExerciseRound(
      questionId: latestQuestion.id,
      existingExercises: const <GeneratedExercise>[],
      generatedExercises: exercises,
    ));
  }

  String _encodeExercises(List<GeneratedExercise> exercises) {
    return jsonEncode(<String, dynamic>{
      'exercises': exercises.map((item) => item.toJson()).toList(),
    });
  }

  Future<String> _runAnswerJudgement(Map<String, dynamic> payload) async {
    final isCorrect = await _service.judgeAnswer(
      question: payload['question'] as String? ?? '',
      userAnswer: payload['userAnswer'] as String? ?? '',
      correctAnswer: payload['correctAnswer'] as String? ?? '',
      options: payload['options'] is List
          ? List<String>.from(payload['options'] as List)
          : null,
    );
    return jsonEncode(<String, dynamic>{'isCorrect': isCorrect});
  }

  Map<String, dynamic> _decodeMap(String source) {
    return _mapValue(jsonDecode(source));
  }

  Map<String, dynamic> _mapValue(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Expected a JSON object.');
  }
}
