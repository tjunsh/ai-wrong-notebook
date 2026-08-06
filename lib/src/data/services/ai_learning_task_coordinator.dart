import 'dart:convert';

import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/repositories/analysis_job_repository.dart';
import 'package:smart_wrong_notebook/src/domain/services/ai_route_resolver.dart';
import 'package:smart_wrong_notebook/src/domain/services/analysis_job_queue_executor.dart';
import 'package:smart_wrong_notebook/src/domain/services/analysis_planner.dart';
import 'package:smart_wrong_notebook/src/domain/services/exercise_round_service.dart';

abstract interface class AiLearningTaskCoordinator {
  Future<String> answerQuestionFollowUp({
    required QuestionRecord question,
    required String userQuestion,
    List<AiFollowUpMessage> history,
  });

  Future<List<GeneratedExercise>> generateExercisesForQuestion(
      QuestionRecord question,
      {bool forceNew = false});

  Future<bool> judgeAnswer({
    required String question,
    required String userAnswer,
    required String correctAnswer,
    List<String>? options,
  });
}

class DirectAiLearningTaskCoordinator implements AiLearningTaskCoordinator {
  const DirectAiLearningTaskCoordinator(this._service);

  final AiAnalysisService _service;

  @override
  Future<String> answerQuestionFollowUp({
    required QuestionRecord question,
    required String userQuestion,
    List<AiFollowUpMessage> history = const <AiFollowUpMessage>[],
  }) {
    return _service.answerQuestionFollowUp(
      question: question,
      userQuestion: userQuestion,
      history: history,
    );
  }

  @override
  Future<List<GeneratedExercise>> generateExercisesForQuestion(
      QuestionRecord question,
      {bool forceNew = false}) async {
    final generated = await _service.generateExercisesForQuestion(question);
    if (!forceNew) return generated;
    return appendGeneratedExerciseRound(
      questionId: question.id,
      existingExercises: question.savedExercises,
      generatedExercises: generated,
    );
  }

  @override
  Future<bool> judgeAnswer({
    required String question,
    required String userAnswer,
    required String correctAnswer,
    List<String>? options,
  }) {
    return _service.judgeAnswer(
      question: question,
      userAnswer: userAnswer,
      correctAnswer: correctAnswer,
      options: options,
    );
  }
}

class QueuedAiLearningTaskCoordinator implements AiLearningTaskCoordinator {
  QueuedAiLearningTaskCoordinator({
    required SettingsRepository settingsRepository,
    required AnalysisJobRepository repository,
    required AnalysisJobQueueExecutor executor,
    QuestionRepository? questionRepository,
    AnalysisPlanner planner = const AnalysisPlanner(),
    String Function()? requestIdFactory,
  })  : _settingsRepository = settingsRepository,
        _repository = repository,
        _executor = executor,
        _questionRepository = questionRepository,
        _planner = planner,
        _requestIdFactory = requestIdFactory ??
            (() => DateTime.now().microsecondsSinceEpoch.toString());

  final SettingsRepository _settingsRepository;
  final AnalysisJobRepository _repository;
  final AnalysisJobQueueExecutor _executor;
  final QuestionRepository? _questionRepository;
  final AnalysisPlanner _planner;
  final String Function() _requestIdFactory;

  @override
  Future<String> answerQuestionFollowUp({
    required QuestionRecord question,
    required String userQuestion,
    List<AiFollowUpMessage> history = const <AiFollowUpMessage>[],
  }) async {
    final task = _planner.buildFollowUpTask(
      questionId: question.id,
      requestId: _requestIdFactory(),
    );
    final completed = await _enqueueAndWait(
      task,
      jsonEncode(<String, dynamic>{
        'question': question.toJson(),
        'userQuestion': userQuestion,
        'history': history
            .map((message) => <String, dynamic>{
                  'role': message.role,
                  'content': message.content,
                })
            .toList(),
      }),
    );
    return _decodeMap(completed.resultJson!)['answer']?.toString() ?? '';
  }

  @override
  Future<List<GeneratedExercise>> generateExercisesForQuestion(
      QuestionRecord question,
      {bool forceNew = false}) async {
    final latestQuestion =
        await _questionRepository?.getById(question.id) ?? question;
    if (!forceNew && latestQuestion.savedExercises.isNotEmpty) {
      return latestQuestion.savedExercises;
    }

    final activeJob = await _activeExerciseGenerationJob(latestQuestion.id);
    if (activeJob != null) {
      final completed = await _waitForTerminal(activeJob);
      return _decodeExercises(completed);
    }

    final task = _planner.buildExerciseGenerationTask(
      questionId: latestQuestion.id,
      requestId: _requestIdFactory(),
    );
    final completed = await _enqueueAndWait(
      task,
      jsonEncode(<String, dynamic>{
        'question': latestQuestion.toJson(),
        'forceNew': forceNew,
      }),
    );
    return _decodeExercises(completed);
  }

  @override
  Future<bool> judgeAnswer({
    required String question,
    required String userAnswer,
    required String correctAnswer,
    List<String>? options,
  }) async {
    final task = _planner.buildAnswerJudgementTask(
      questionId: 'exercise-answer',
      requestId: _requestIdFactory(),
    );
    final completed = await _enqueueAndWait(
      task,
      jsonEncode(<String, dynamic>{
        'question': question,
        'userAnswer': userAnswer,
        'correctAnswer': correctAnswer,
        'options': options,
      }),
    );
    return _decodeMap(completed.resultJson!)['isCorrect'] as bool? ?? false;
  }

  Future<AnalysisJob> _enqueueAndWait(
    AiTaskSpec task,
    String payloadJson,
  ) async {
    final config = await _settingsRepository.getAiProviderConfig();
    if (config == null ||
        config.baseUrl.isEmpty ||
        config.model.isEmpty ||
        config.apiKey.isEmpty) {
      throw AiAnalysisException('AI 服务未配置，请先在设置中填写 Base URL、模型和 API Key');
    }
    final route = SingleProviderAiRouteResolver(
      routeId: '${config.id}:${config.model}',
      providerConfigId: config.id,
      modelName: config.model,
    ).resolve(task, promptVersion: '${task.type.name}-v1');
    await _executor.enqueue(AnalysisJob.queued(
      id: task.id,
      idempotencyKey: task.id,
      taskSpec: task,
      route: route,
      payloadJson: payloadJson,
      maxAttempts: 2,
      createdAt: DateTime.now(),
    ));

    return _waitForTerminalById(task.parentQuestionId, task.id);
  }

  Future<AnalysisJob> _waitForTerminal(AnalysisJob job) {
    return _waitForTerminalById(job.taskSpec.parentQuestionId, job.id);
  }

  Future<AnalysisJob> _waitForTerminalById(
    String parentQuestionId,
    String jobId,
  ) async {
    final jobs = await _repository
        .watchByParentQuestionId(parentQuestionId)
        .firstWhere((items) => items.any(
              (job) => job.id == jobId && job.isTerminal,
            ));
    final completed = jobs.firstWhere((job) => job.id == jobId);
    if (completed.status != AnalysisJobStatus.completed ||
        completed.resultJson == null) {
      throw AiAnalysisException(
        completed.errorMessage ?? 'AI 任务失败，请重试',
      );
    }
    return completed;
  }

  Future<AnalysisJob?> _activeExerciseGenerationJob(String questionId) async {
    final jobs = await _repository.listAll();
    final active = jobs
        .where((job) =>
            job.taskSpec.parentQuestionId == questionId &&
            job.taskSpec.type == AiTaskType.exerciseGeneration &&
            (job.status == AnalysisJobStatus.queued ||
                job.status == AnalysisJobStatus.running))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return active.isEmpty ? null : active.first;
  }

  List<GeneratedExercise> _decodeExercises(AnalysisJob completed) {
    final result = _decodeMap(completed.resultJson!);
    return (result['exercises'] as List? ?? const <Object>[])
        .whereType<Map>()
        .map((item) => GeneratedExercise.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  Map<String, dynamic> _decodeMap(String source) {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const FormatException('Expected a JSON object.');
  }
}
