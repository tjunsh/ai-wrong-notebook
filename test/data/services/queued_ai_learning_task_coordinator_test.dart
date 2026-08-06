import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart'
    hide AnalysisJob, GeneratedExercise, QuestionRecord;
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/drift_analysis_job_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/data/services/ai_learning_task_coordinator.dart';
import 'package:smart_wrong_notebook/src/data/services/app_analysis_job_runner.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/domain/services/analysis_job_queue_executor.dart';

class _LearningTestAiService extends TestAiAnalysisService {
  _LearningTestAiService({required super.settingsRepository})
      : super(
          extractionResult: const AiQuestionExtractionResult(
            extractedQuestionText: '',
            normalizedQuestionText: '',
          ),
          analysisResultValue: const AnalysisResult(
            finalAnswer: '2',
            steps: <String>['步骤'],
            aiTags: <String>[],
            knowledgePoints: <String>[],
            mistakeReason: '',
            studyAdvice: '',
          ),
        );

  int exerciseCallCount = 0;

  @override
  Future<String> answerQuestionFollowUp({
    required QuestionRecord question,
    required String userQuestion,
    List<AiFollowUpMessage> history = const <AiFollowUpMessage>[],
  }) async {
    return '追问回答：$userQuestion';
  }

  @override
  Future<List<GeneratedExercise>> generateExercisesForQuestion(
    QuestionRecord question,
  ) async {
    exerciseCallCount++;
    return <GeneratedExercise>[
      GeneratedExercise(
        id: 'exercise-1',
        questionId: question.id,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '简单',
        question: '练习题',
        answer: 'A',
        explanation: '解析',
        createdAt: DateTime(2026, 7, 13, 19),
      ),
    ];
  }

  @override
  Future<bool> judgeAnswer({
    required String question,
    required String userAnswer,
    required String correctAnswer,
    List<String>? options,
  }) async {
    return userAnswer == correctAnswer;
  }
}

class _DeferredExerciseAiService extends _LearningTestAiService {
  _DeferredExerciseAiService({required super.settingsRepository});

  final Completer<List<GeneratedExercise>> completer =
      Completer<List<GeneratedExercise>>();
  @override
  Future<List<GeneratedExercise>> generateExercisesForQuestion(
    QuestionRecord question,
  ) {
    exerciseCallCount++;
    return completer.future;
  }
}

void main() {
  late AppDatabase database;
  late DriftAnalysisJobRepository repository;
  late InMemoryQuestionRepository questions;
  late QueuedAiLearningTaskCoordinator coordinator;

  setUp(() {
    database = AppDatabase.memory();
    repository = DriftAnalysisJobRepository(database);
    questions = InMemoryQuestionRepository();
    final settings = InMemorySettingsRepository();
    final service = _LearningTestAiService(settingsRepository: settings);
    coordinator = QueuedAiLearningTaskCoordinator(
      settingsRepository: settings,
      repository: repository,
      executor: AnalysisJobQueueExecutor(
        repository: repository,
        runner: AppAnalysisJobRunner(
          service,
          questionRepository: questions,
        ),
      ),
      questionRepository: questions,
      requestIdFactory: () =>
          'request-${DateTime.now().microsecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    await database.close();
  });

  QuestionRecord question() => QuestionRecord.draft(
        id: 'question-1',
        imagePath: '/tmp/question.jpg',
        subject: Subject.math,
        recognizedText: 'x+1=3',
      ).copyWith(
        analysisResult: const AnalysisResult(
          subject: Subject.math,
          finalAnswer: 'x=2',
          steps: <String>['两边减去1'],
          aiTags: <String>['方程'],
          knowledgePoints: <String>['等式性质'],
          mistakeReason: '移项错误',
          studyAdvice: '检查符号',
        ),
      );

  test('follow-up, exercises, and judgement use the persistent queue',
      () async {
    final answer = await coordinator.answerQuestionFollowUp(
      question: question(),
      userQuestion: '为什么移项？',
    );
    final exercises = await coordinator.generateExercisesForQuestion(
      question(),
    );
    final isCorrect = await coordinator.judgeAnswer(
      question: '1+1=?',
      userAnswer: '2',
      correctAnswer: '2',
    );

    expect(answer, '追问回答：为什么移项？');
    expect(exercises.single.question, '练习题');
    expect(isCorrect, isTrue);
    expect(await repository.listAll(), hasLength(3));
  });

  test('exercise generation writes back to question repository', () async {
    final source = question();
    await questions.saveDraft(source);

    final exercises = await coordinator.generateExercisesForQuestion(source);

    expect(exercises.single.question, '练习题');
    final saved = await questions.getById(source.id);
    expect(saved?.savedExercises.single.question, '练习题');
  });

  test('force new exercise generation appends a new round', () async {
    final settings = InMemorySettingsRepository();
    final service = _LearningTestAiService(settingsRepository: settings);
    final source = question().copyWith(
      savedExercises: <GeneratedExercise>[
        GeneratedExercise(
          id: 'question-1-round-1-exercise-1',
          questionId: 'question-1',
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '简单',
          question: '旧练习',
          answer: 'A',
          explanation: '旧解析',
          createdAt: DateTime(2026, 7, 12),
          isCorrect: true,
          userAnswer: 'A',
          roundIndex: 1,
          roundTotal: 1,
          roundGroupId: 'question-1-round-1',
        ),
      ],
    );
    await questions.saveDraft(source);
    final coordinator = QueuedAiLearningTaskCoordinator(
      settingsRepository: settings,
      repository: repository,
      executor: AnalysisJobQueueExecutor(
        repository: repository,
        runner: AppAnalysisJobRunner(
          service,
          questionRepository: questions,
        ),
      ),
      questionRepository: questions,
      requestIdFactory: () =>
          'request-${DateTime.now().microsecondsSinceEpoch}',
    );

    final existing = await coordinator.generateExercisesForQuestion(source);
    expect(existing.single.question, '旧练习');
    expect(service.exerciseCallCount, 0);

    final exercises =
        await coordinator.generateExercisesForQuestion(source, forceNew: true);

    expect(service.exerciseCallCount, 1);
    expect(exercises.map((exercise) => exercise.question), <String>[
      '旧练习',
      '练习题',
    ]);
    expect(exercises.last.roundIndex, 2);
    expect(exercises.last.isCorrect, isNull);
    final saved = await questions.getById(source.id);
    expect(saved?.savedExercises.map((exercise) => exercise.question), <String>[
      '旧练习',
      '练习题',
    ]);
  });

  test('active exercise generation for the same question is reused', () async {
    final settings = InMemorySettingsRepository();
    final service = _DeferredExerciseAiService(settingsRepository: settings);
    final source = question();
    await questions.saveDraft(source);
    final coordinator = QueuedAiLearningTaskCoordinator(
      settingsRepository: settings,
      repository: repository,
      executor: AnalysisJobQueueExecutor(
        repository: repository,
        runner: AppAnalysisJobRunner(
          service,
          questionRepository: questions,
        ),
      ),
      questionRepository: questions,
      requestIdFactory: () =>
          'request-${DateTime.now().microsecondsSinceEpoch}',
    );

    final first = coordinator.generateExercisesForQuestion(source);
    await _waitUntil(() async => service.exerciseCallCount == 1);
    final second = coordinator.generateExercisesForQuestion(source);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(await repository.listAll(), hasLength(1));
    expect(service.exerciseCallCount, 1);

    service.completer.complete(<GeneratedExercise>[
      GeneratedExercise(
        id: 'exercise-1',
        questionId: source.id,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '简单',
        question: '不重复的新练习',
        answer: 'A',
        explanation: '解析',
        createdAt: DateTime(2026, 7, 16),
      ),
    ]);

    final results = await Future.wait(<Future<List<GeneratedExercise>>>[
      first,
      second,
    ]);
    expect(results.first.single.question, '不重复的新练习');
    expect(results.last.single.question, '不重复的新练习');
    expect(service.exerciseCallCount, 1);
    final saved = await questions.getById(source.id);
    expect(saved?.savedExercises.single.question, '不重复的新练习');
  });
}

Future<void> _waitUntil(FutureOr<bool> Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (DateTime.now().isBefore(deadline)) {
    if (await condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition was not met before timeout.');
}
