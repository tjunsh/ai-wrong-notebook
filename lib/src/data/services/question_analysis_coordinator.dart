import 'dart:convert';

import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/data/services/question_analysis_pipeline.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/domain/repositories/analysis_job_repository.dart';
import 'package:smart_wrong_notebook/src/domain/services/ai_route_resolver.dart';
import 'package:smart_wrong_notebook/src/domain/services/analysis_job_queue_executor.dart';
import 'package:smart_wrong_notebook/src/domain/services/analysis_planner.dart';

abstract interface class QuestionAnalysisCoordinator {
  Future<QuestionRecord> analyze(
    QuestionRecord question, {
    CandidateAnalysisProgress? onProgress,
  });
}

class QuestionAnalysisHandle {
  const QuestionAnalysisHandle({
    required this.parentQuestionId,
    required this.firstPassJobId,
  });

  final String parentQuestionId;
  final String firstPassJobId;
}

class QuestionAnalysisTaskSnapshot {
  const QuestionAnalysisTaskSnapshot({
    required this.handle,
    required this.job,
    required this.sourceQuestion,
    this.resultQuestion,
    this.recognizedQuestionText = '',
    this.recognizedSubject,
    this.questionCount = 1,
    this.isRecognizing = false,
  });

  final QuestionAnalysisHandle handle;
  final AnalysisJob job;
  final QuestionRecord sourceQuestion;
  final QuestionRecord? resultQuestion;
  final String recognizedQuestionText;
  final Subject? recognizedSubject;
  final int questionCount;
  final bool isRecognizing;

  Subject get displaySubject =>
      resultQuestion?.analysisResult?.subject ??
      resultQuestion?.subject ??
      recognizedSubject ??
      sourceQuestion.subject;

  String get displayQuestionText {
    final reconstructed =
        resultQuestion?.analysisResult?.reconstructedQuestionText ?? '';
    final candidates = questionCount > 1
        ? <String>[
            resultQuestion?.correctedText ?? '',
            resultQuestion?.extractedQuestionText ?? '',
            recognizedQuestionText,
            sourceQuestion.correctedText,
            sourceQuestion.extractedQuestionText,
            reconstructed,
          ]
        : <String>[
            reconstructed,
            resultQuestion?.correctedText ?? '',
            resultQuestion?.extractedQuestionText ?? '',
            recognizedQuestionText,
            sourceQuestion.correctedText,
            sourceQuestion.extractedQuestionText,
          ];
    for (final candidate in candidates) {
      final text = candidate.trim();
      if (text.isNotEmpty) return text;
    }
    return '正在识别题目内容…';
  }
}

abstract interface class BackgroundQuestionAnalysisCoordinator
    implements QuestionAnalysisCoordinator {
  Future<QuestionAnalysisHandle> enqueue(QuestionRecord question);
  Future<QuestionRecord> waitForResult(QuestionAnalysisHandle handle);
  QuestionAnalysisTaskSnapshot snapshotFromJob(
    AnalysisJob job, {
    Iterable<AnalysisJob> dependencyJobs = const <AnalysisJob>[],
    Iterable<AnalysisJob> relatedJobs = const <AnalysisJob>[],
  });
}

abstract interface class CandidateAnalysisRetryCoordinator {
  /// Queues one failed candidate from an existing multi-question result.
  /// Returns false when that candidate is already queued or running.
  Future<bool> retryCandidate(
    QuestionRecord source,
    CandidateAnalysisSnapshot candidate,
  );
}

class DirectQuestionAnalysisCoordinator implements QuestionAnalysisCoordinator {
  const DirectQuestionAnalysisCoordinator(this._pipeline);

  final QuestionAnalysisPipeline _pipeline;

  @override
  Future<QuestionRecord> analyze(
    QuestionRecord question, {
    CandidateAnalysisProgress? onProgress,
  }) {
    return _pipeline.analyze(question, onProgress: onProgress);
  }
}

class QueuedQuestionAnalysisCoordinator
    implements
        BackgroundQuestionAnalysisCoordinator,
        CandidateAnalysisRetryCoordinator {
  QueuedQuestionAnalysisCoordinator({
    required AiAnalysisService service,
    required SettingsRepository settingsRepository,
    required AnalysisJobRepository repository,
    required AnalysisJobQueueExecutor executor,
    AnalysisPlanner planner = const AnalysisPlanner(),
    String Function()? runIdFactory,
  })  : _pipeline = QuestionAnalysisPipeline(service),
        _settingsRepository = settingsRepository,
        _repository = repository,
        _executor = executor,
        _planner = planner,
        _runIdFactory = runIdFactory ??
            (() => DateTime.now().microsecondsSinceEpoch.toString());

  final QuestionAnalysisPipeline _pipeline;
  final SettingsRepository _settingsRepository;
  final AnalysisJobRepository _repository;
  final AnalysisJobQueueExecutor _executor;
  final AnalysisPlanner _planner;
  final String Function() _runIdFactory;

  @override
  Future<QuestionRecord> analyze(
    QuestionRecord question, {
    CandidateAnalysisProgress? onProgress,
  }) async {
    final handle = await enqueue(question);
    return waitForResult(handle);
  }

  @override
  Future<QuestionAnalysisHandle> enqueue(QuestionRecord question) async {
    final config = await _settingsRepository.getAiProviderConfig();
    if (config == null ||
        config.baseUrl.isEmpty ||
        config.model.isEmpty ||
        config.apiKey.isEmpty) {
      throw AiAnalysisException('AI 服务未配置，请先在设置中填写 Base URL、模型和 API Key');
    }

    final runId = _runIdFactory();
    final plan = _planner.buildInitialPlan(
      questionId: question.id,
      needsExtraction: _pipeline.needsExtraction(question),
      requiresImageAnalysis: _pipeline.requiresImageAnalysis(question),
      runId: runId,
    );
    final resolver = SingleProviderAiRouteResolver(
      routeId: '${config.id}:${config.model}',
      providerConfigId: config.id,
      modelName: config.model,
    );

    for (final task in plan.executionOrder) {
      final route = resolver.resolve(
        task,
        promptVersion: _promptVersion(task.type),
      );
      await _executor.enqueue(AnalysisJob.queued(
        id: task.id,
        idempotencyKey: task.id,
        taskSpec: task,
        route: route,
        payloadJson: _payloadFor(task, question),
        maxAttempts: 2,
        createdAt: DateTime.now(),
      ));
    }

    final firstPassTask = plan.tasks.firstWhere(
      (task) => task.type == AiTaskType.firstPassAnalysis,
    );
    return QuestionAnalysisHandle(
      parentQuestionId: question.id,
      firstPassJobId: firstPassTask.id,
    );
  }

  @override
  Future<bool> retryCandidate(
    QuestionRecord source,
    CandidateAnalysisSnapshot candidate,
  ) async {
    if (candidate.status != CandidateAnalysisStatus.failed ||
        candidate.questionText.trim().isEmpty) {
      throw ArgumentError('只有解析失败且题干完整的题目可以重新解析。');
    }

    final config = await _settingsRepository.getAiProviderConfig();
    if (config == null ||
        config.baseUrl.isEmpty ||
        config.model.isEmpty ||
        config.apiKey.isEmpty) {
      throw AiAnalysisException('AI 服务未配置，请先在设置中填写 Base URL、模型和 API Key');
    }

    final jobs = await _repository.listAll();
    final hasActiveRetry = jobs.any((job) {
      return job.taskSpec.parentQuestionId == source.id &&
          job.taskSpec.type == AiTaskType.candidateAnalysisRetry &&
          (job.status == AnalysisJobStatus.queued ||
              job.status == AnalysisJobStatus.running) &&
          _candidateIdFromRetryJob(job) == candidate.candidateId;
    });
    if (hasActiveRetry) return false;

    final parentJob = _latestCompletedParentJob(
      jobs,
      sourceQuestionId: source.id,
      candidateId: candidate.candidateId,
    );
    if (parentJob == null) {
      throw AiAnalysisException('未找到这次扫描的原始解析结果，请返回首页后重新打开。');
    }

    final requiresImage = _pipeline.requiresImageAnalysis(
      source.copyWith(
        normalizedQuestionText: candidate.questionText,
        extractedQuestionText: candidate.questionText,
      ),
    );
    final requestId = _runIdFactory();
    final task = _planner.buildCandidateAnalysisRetryTask(
      questionId: source.id,
      candidateId: candidate.candidateId,
      parentFirstPassJobId: parentJob.id,
      requestId: requestId,
      requiresImageAnalysis: requiresImage,
    );
    final route = SingleProviderAiRouteResolver(
      routeId: '${config.id}:${config.model}',
      providerConfigId: config.id,
      modelName: config.model,
    ).resolve(
      task,
      promptVersion: _promptVersion(task.type),
    );
    await _executor.enqueue(AnalysisJob.queued(
      id: task.id,
      idempotencyKey: task.id,
      taskSpec: task,
      route: route,
      payloadJson: jsonEncode(<String, dynamic>{
        'parentFirstPassJobId': parentJob.id,
        'candidateId': candidate.candidateId,
      }),
      // The service owns its bounded request retry. A manual tap creates one
      // explicit retry session instead of an unbounded queue retry loop.
      maxAttempts: 1,
      createdAt: DateTime.now(),
    ));
    return true;
  }

  @override
  Future<QuestionRecord> waitForResult(QuestionAnalysisHandle handle) async {
    final completed = await _waitForTerminal(
      handle.parentQuestionId,
      handle.firstPassJobId,
    );
    if (completed.status != AnalysisJobStatus.completed ||
        completed.resultJson == null) {
      throw AiAnalysisException(
        completed.errorMessage ?? 'AI 解析任务失败，请重试',
      );
    }
    return QuestionRecord.fromJson(_decodeMap(completed.resultJson!));
  }

  @override
  QuestionAnalysisTaskSnapshot snapshotFromJob(
    AnalysisJob job, {
    Iterable<AnalysisJob> dependencyJobs = const <AnalysisJob>[],
    Iterable<AnalysisJob> relatedJobs = const <AnalysisJob>[],
  }) {
    if (job.taskSpec.type != AiTaskType.firstPassAnalysis) {
      throw ArgumentError.value(
        job.taskSpec.type,
        'job.taskSpec.type',
        'Only first-pass jobs are visible analysis tasks.',
      );
    }
    final payload = _decodeMap(job.payloadJson);
    final sourceJson = payload['question'];
    if (sourceJson is! Map) {
      throw const FormatException('First-pass task has no source question.');
    }
    QuestionRecord? resultQuestion;
    if (job.status == AnalysisJobStatus.completed && job.resultJson != null) {
      resultQuestion = QuestionRecord.fromJson(_decodeMap(job.resultJson!));
      resultQuestion = _applyActiveCandidateRetries(
        resultQuestion,
        relatedJobs,
      );
    }
    final sourceQuestion = QuestionRecord.fromJson(
      Map<String, dynamic>.from(sourceJson),
    );
    AiQuestionExtractionResult? extraction;
    AnalysisJob? extractionJob;
    for (final dependency in dependencyJobs) {
      if (dependency.taskSpec.type != AiTaskType.extraction) continue;
      extractionJob = dependency;
      final resultJson = dependency.resultJson;
      if (resultJson != null) {
        try {
          extraction = AiQuestionExtractionResult.fromJson(
            _decodeMap(resultJson),
          );
        } catch (_) {
          // Legacy extraction data should not hide an otherwise valid task.
        }
      }
      break;
    }
    return QuestionAnalysisTaskSnapshot(
      handle: QuestionAnalysisHandle(
        parentQuestionId: job.taskSpec.parentQuestionId,
        firstPassJobId: job.id,
      ),
      job: job,
      sourceQuestion: sourceQuestion,
      resultQuestion: resultQuestion,
      recognizedQuestionText:
          extraction?.normalizedQuestionText.isNotEmpty == true
              ? extraction!.normalizedQuestionText
              : extraction?.extractedQuestionText ?? '',
      recognizedSubject: extraction?.subject,
      questionCount: _questionCount(
        job: job,
        sourceQuestion: sourceQuestion,
        resultQuestion: resultQuestion,
        extraction: extraction,
      ),
      isRecognizing: extractionJob?.status == AnalysisJobStatus.running,
    );
  }

  AnalysisJob? _latestCompletedParentJob(
    List<AnalysisJob> jobs, {
    required String sourceQuestionId,
    required String candidateId,
  }) {
    final candidates = jobs
        .where((job) =>
            job.taskSpec.parentQuestionId == sourceQuestionId &&
            job.taskSpec.type == AiTaskType.firstPassAnalysis &&
            job.status == AnalysisJobStatus.completed &&
            job.resultJson != null)
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    for (final job in candidates) {
      try {
        final record = QuestionRecord.fromJson(_decodeMap(job.resultJson!));
        if (record.candidateAnalyses
            .any((item) => item.candidateId == candidateId)) {
          return job;
        }
      } catch (_) {
        // A malformed legacy result must not block a newer valid result.
      }
    }
    return null;
  }

  QuestionRecord _applyActiveCandidateRetries(
    QuestionRecord source,
    Iterable<AnalysisJob> jobs,
  ) {
    if (source.candidateAnalyses.isEmpty) return source;
    final activeByCandidate = <String, AnalysisJob>{};
    for (final job in jobs) {
      if (job.taskSpec.parentQuestionId != source.id ||
          job.taskSpec.type != AiTaskType.candidateAnalysisRetry ||
          (job.status != AnalysisJobStatus.queued &&
              job.status != AnalysisJobStatus.running)) {
        continue;
      }
      final candidateId = _candidateIdFromRetryJob(job);
      if (candidateId == null || candidateId.isEmpty) continue;
      final existing = activeByCandidate[candidateId];
      if (existing == null || job.createdAt.isAfter(existing.createdAt)) {
        activeByCandidate[candidateId] = job;
      }
    }
    if (activeByCandidate.isEmpty) return source;

    return source.copyWith(
      candidateAnalyses: source.candidateAnalyses.map((candidate) {
        final job = activeByCandidate[candidate.candidateId];
        if (job == null) return candidate;
        return CandidateAnalysisSnapshot(
          candidateId: candidate.candidateId,
          order: candidate.order,
          questionText: candidate.questionText,
          analysisResult: candidate.analysisResult,
          savedExercises: candidate.savedExercises,
          subject: candidate.subject,
          aiTags: candidate.aiTags,
          aiKnowledgePoints: candidate.aiKnowledgePoints,
          status: job.status == AnalysisJobStatus.running
              ? CandidateAnalysisStatus.running
              : CandidateAnalysisStatus.queued,
        );
      }).toList(growable: false),
    );
  }

  String? _candidateIdFromRetryJob(AnalysisJob job) {
    try {
      return _decodeMap(job.payloadJson)['candidateId'] as String?;
    } catch (_) {
      return null;
    }
  }

  int _questionCount({
    required AnalysisJob job,
    required QuestionRecord sourceQuestion,
    required QuestionRecord? resultQuestion,
    required AiQuestionExtractionResult? extraction,
  }) {
    final counts = <int>[
      job.progress?.totalUnits ?? 0,
      resultQuestion?.candidateAnalyses.length ?? 0,
      resultQuestion?.splitResult?.candidates.length ?? 0,
      extraction?.splitResult?.candidates.length ?? 0,
      sourceQuestion.splitResult?.candidates.length ?? 0,
    ];
    return counts.firstWhere((count) => count > 1, orElse: () => 1);
  }

  String _payloadFor(AiTaskSpec task, QuestionRecord question) {
    switch (task.type) {
      case AiTaskType.extraction:
        return jsonEncode(<String, dynamic>{
          'subjectName': question.subject.name,
          'imagePath': question.imagePath,
          'textHint': question.extractedQuestionText,
        });
      case AiTaskType.firstPassAnalysis:
        return jsonEncode(<String, dynamic>{
          'question': question.toJson(),
        });
      case AiTaskType.independentQuestionSplit:
      case AiTaskType.candidateAnalysisRetry:
      case AiTaskType.deepAnalysis:
      case AiTaskType.verification:
      case AiTaskType.followUp:
      case AiTaskType.exerciseGeneration:
      case AiTaskType.answerJudgement:
        throw StateError(
            'Unexpected initial-analysis task: ${task.type.name}.');
    }
  }

  String _promptVersion(AiTaskType type) {
    return switch (type) {
      AiTaskType.extraction => 'extraction-v1',
      AiTaskType.firstPassAnalysis => 'analysis-v1',
      AiTaskType.candidateAnalysisRetry => 'candidate-retry-v1',
      _ => '${type.name}-v1',
    };
  }

  Future<AnalysisJob> _waitForTerminal(
    String parentQuestionId,
    String jobId,
  ) async {
    final jobs = await _repository
        .watchByParentQuestionId(parentQuestionId)
        .firstWhere((items) => items.any(
              (job) => job.id == jobId && job.isTerminal,
            ));
    return jobs.firstWhere((job) => job.id == jobId);
  }

  Map<String, dynamic> _decodeMap(String source) {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const FormatException('Expected a JSON object.');
  }
}
