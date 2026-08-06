import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/services/question_analysis_coordinator.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/domain/services/ai_route_resolver.dart';
import 'package:smart_wrong_notebook/src/features/home/presentation/background_analysis_section.dart';

void main() {
  QuestionAnalysisTaskSnapshot task(
    String id,
    AnalysisJobStatus status, {
    AnalysisJobProgress? progress,
    int questionCount = 1,
    String? sourceText,
    String? resultText,
    Subject subject = Subject.math,
    Subject? recognizedSubject,
    bool isRecognizing = false,
    List<CandidateAnalysisSnapshot> candidateAnalyses =
        const <CandidateAnalysisSnapshot>[],
  }) {
    final source = QuestionRecord.draft(
      id: id,
      imagePath: '/tmp/$id.jpg',
      subject: subject,
      recognizedText: sourceText ?? '题目 $id',
    );
    final spec = AiTaskSpec(
      id: '$id:first-pass',
      parentQuestionId: id,
      type: AiTaskType.firstPassAnalysis,
      workloadProfile: AiWorkloadProfile.routine,
      requiredCapabilities: const <AiCapability>{
        AiCapability.structuredOutput,
      },
      qualityPolicy: AiQualityPolicy.reliableRequired,
      queuePriority: AiQueuePriority.firstPass,
    );
    final result = source.copyWith(
      contentStatus: ContentStatus.ready,
      candidateAnalyses: candidateAnalyses,
      analysisResult: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: '答案',
        steps: <String>['步骤'],
        aiTags: <String>[],
        knowledgePoints: <String>[],
        mistakeReason: '',
        studyAdvice: '',
      ),
    );
    final job = AnalysisJob(
      id: spec.id,
      idempotencyKey: spec.id,
      taskSpec: spec,
      route: const AiResolvedRoute(
        requestedModelClass: AiModelClass.balanced,
        requestedModelRole: AiModelRole.primary,
        resolvedRouteId: 'default:test',
        providerConfigId: 'default',
        modelName: 'test',
        promptVersion: 'analysis-v1',
        verifierIsIndependent: false,
      ),
      payloadJson: '{}',
      status: status,
      attemptCount: status == AnalysisJobStatus.queued ? 0 : 1,
      maxAttempts: 2,
      resultJson: status == AnalysisJobStatus.completed ? '{}' : null,
      errorMessage: status == AnalysisJobStatus.failed ? '网络失败' : null,
      createdAt: DateTime(2026, 7, 14, 9),
      updatedAt: DateTime(2026, 7, 14, 9),
      progress: progress,
    );
    return QuestionAnalysisTaskSnapshot(
      handle: QuestionAnalysisHandle(
        parentQuestionId: id,
        firstPassJobId: job.id,
      ),
      job: job,
      sourceQuestion: source,
      resultQuestion: status == AnalysisJobStatus.completed
          ? result.copyWith(
              extractedQuestionText: resultText ?? '解析题干 $id',
              normalizedQuestionText: resultText ?? '解析题干 $id',
            )
          : null,
      recognizedSubject: recognizedSubject,
      questionCount: questionCount,
      isRecognizing: isRecognizing,
    );
  }

  testWidgets('shows statuses and opens only actionable tasks', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? openedId;
    String? retriedId;
    String? deletedId;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BackgroundAnalysisSection(
          tasks: <QuestionAnalysisTaskSnapshot>[
            task(
              'running',
              AnalysisJobStatus.running,
              progress: const AnalysisJobProgress(
                stage: AnalysisJobProgressStage.analyzingCandidates,
                completedUnits: 2,
                totalUnits: 3,
              ),
              questionCount: 3,
            ),
            task('completed', AnalysisJobStatus.completed),
            task('failed', AnalysisJobStatus.failed),
          ],
          onOpenResult: (task) => openedId = task.handle.parentQuestionId,
          onRetry: (task) => retriedId = task.handle.parentQuestionId,
          onDelete: (task) => deletedId = task.handle.parentQuestionId,
        ),
      ),
    ));

    expect(find.text('录题进度'), findsOneWidget);
    expect(find.text('数学 · 共 3 道题'), findsOneWidget);
    expect(find.text('题目 running'), findsOneWidget);
    expect(find.text('已完成 2/3，正在解析第 3 题'), findsOneWidget);
    expect(find.text('解析题干 completed'), findsOneWidget);
    expect(find.text('解析好了，待确认'), findsOneWidget);
    expect(find.text('查看结果'), findsOneWidget);
    expect(find.text('解析失败'), findsOneWidget);

    await tester.tap(find.text('查看结果'));
    expect(openedId, 'completed');
    await tester.tap(find.text('重试'));
    expect(retriedId, 'failed');
    await tester.tap(find.byTooltip('删除失败任务'));
    expect(deletedId, 'failed');
  });

  testWidgets('shows an honest recognition fallback instead of a blank title',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BackgroundAnalysisSection(
          tasks: <QuestionAnalysisTaskSnapshot>[
            task(
              'recognizing',
              AnalysisJobStatus.queued,
              sourceText: '',
              isRecognizing: true,
              subject: Subject.chemistry,
            ),
          ],
          onOpenResult: (_) {},
          onRetry: (_) {},
          onDelete: (_) {},
        ),
      ),
    ));

    expect(find.text('化学'), findsOneWidget);
    expect(find.text('正在识别题目内容…'), findsOneWidget);
    expect(find.text('正在识别题目内容'), findsOneWidget);
  });

  testWidgets('shows unknown subject honestly and updates after recognition',
      (tester) async {
    Future<void> pumpTask({Subject? recognizedSubject}) {
      return tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BackgroundAnalysisSection(
            tasks: <QuestionAnalysisTaskSnapshot>[
              task(
                'unknown-subject',
                AnalysisJobStatus.queued,
                sourceText: '',
                isRecognizing: true,
                subject: Subject.unknown,
                recognizedSubject: recognizedSubject,
              ),
            ],
            onOpenResult: (_) {},
            onRetry: (_) {},
            onDelete: (_) {},
          ),
        ),
      ));
    }

    await pumpTask();
    expect(find.text('学科识别中'), findsOneWidget);
    expect(find.text('数学'), findsNothing);

    await pumpTask(recognizedSubject: Subject.english);
    expect(find.text('英语'), findsOneWidget);
    expect(find.text('学科识别中'), findsNothing);
  });

  testWidgets('shows queued tasks as waiting instead of simultaneous parsing',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BackgroundAnalysisSection(
          tasks: <QuestionAnalysisTaskSnapshot>[
            task(
              'active-recognition',
              AnalysisJobStatus.queued,
              sourceText: '第一题',
              isRecognizing: true,
              subject: Subject.unknown,
            ),
            task(
              'queued-recognition',
              AnalysisJobStatus.queued,
              sourceText: '第二题',
              isRecognizing: false,
              subject: Subject.unknown,
            ),
          ],
          onOpenResult: (_) {},
          onRetry: (_) {},
          onDelete: (_) {},
        ),
      ),
    ));

    expect(find.text('第一题'), findsOneWidget);
    expect(find.text('第二题'), findsOneWidget);
    expect(find.text('学科识别中'), findsOneWidget);
    expect(find.text('学科待识别'), findsOneWidget);
    expect(find.text('正在识别题目内容'), findsOneWidget);
    expect(find.text('等待解析'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('keeps one scan card while a failed candidate is retrying',
      (tester) async {
    const answer = AnalysisResult(
      finalAnswer: '答案',
      steps: <String>['步骤'],
      aiTags: <String>[],
      knowledgePoints: <String>[],
      mistakeReason: '',
      studyAdvice: '',
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BackgroundAnalysisSection(
          tasks: <QuestionAnalysisTaskSnapshot>[
            task(
              'partial',
              AnalysisJobStatus.completed,
              questionCount: 3,
              candidateAnalyses: const <CandidateAnalysisSnapshot>[
                CandidateAnalysisSnapshot(
                  candidateId: '1',
                  order: 1,
                  questionText: '第一题',
                  analysisResult: answer,
                ),
                CandidateAnalysisSnapshot(
                  candidateId: '2',
                  order: 2,
                  questionText: '第二题',
                  status: CandidateAnalysisStatus.queued,
                ),
                CandidateAnalysisSnapshot(
                  candidateId: '3',
                  order: 3,
                  questionText: '第三题',
                  status: CandidateAnalysisStatus.failed,
                ),
              ],
            ),
          ],
          onOpenResult: (_) {},
          onRetry: (_) {},
          onDelete: (_) {},
        ),
      ),
    ));

    expect(find.text('已解析 1/3，第 2 题排队中'), findsOneWidget);
    expect(find.text('查看结果'), findsOneWidget);
  });
}
