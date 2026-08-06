import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/data/services/app_analysis_job_runner.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/domain/services/ai_route_resolver.dart';
import 'package:smart_wrong_notebook/src/domain/services/analysis_job_queue_executor.dart';

void main() {
  const result = AnalysisResult(
    subject: Subject.math,
    finalAnswer: 'x=2',
    steps: <String>['移项'],
    aiTags: <String>['方程'],
    knowledgePoints: <String>['等式性质'],
    mistakeReason: '移项错误',
    studyAdvice: '检查符号',
  );

  TestAiAnalysisService service() => TestAiAnalysisService(
        settingsRepository: InMemorySettingsRepository(),
        extractionResult: const AiQuestionExtractionResult(
          extractedQuestionText: '识别题干',
          normalizedQuestionText: '规范题干',
          subject: Subject.math,
        ),
        analysisResultValue: result,
      );

  AnalysisJob job({
    required String id,
    required AiTaskType type,
    required String payloadJson,
    List<String> dependencies = const <String>[],
  }) {
    final spec = AiTaskSpec(
      id: id,
      parentQuestionId: 'question-1',
      type: type,
      workloadProfile: type == AiTaskType.extraction
          ? AiWorkloadProfile.visionHeavy
          : AiWorkloadProfile.routine,
      requiredCapabilities: const <AiCapability>{
        AiCapability.structuredOutput,
      },
      qualityPolicy: AiQualityPolicy.reliableRequired,
      queuePriority: AiQueuePriority.firstPass,
      dependencyJobIds: dependencies,
    );
    const resolver = SingleProviderAiRouteResolver(
      routeId: 'vbcode-gpt-5.5',
      providerConfigId: 'default',
      modelName: 'gpt-5.5',
    );
    return AnalysisJob.queued(
      id: id,
      idempotencyKey: id,
      taskSpec: spec,
      route: resolver.resolve(spec, promptVersion: 'analysis-v1'),
      payloadJson: payloadJson,
      createdAt: DateTime(2026, 7, 13, 18),
    ).copyWith(status: AnalysisJobStatus.running, attemptCount: 1);
  }

  test('runs extraction job and serializes structured text', () async {
    final aiService = service();
    final runner = AppAnalysisJobRunner(aiService);
    final extractionJob = job(
      id: 'question-1:extraction',
      type: AiTaskType.extraction,
      payloadJson: jsonEncode(<String, dynamic>{
        'subjectName': 'math',
        'imagePath': '/tmp/question.jpg',
        'textHint': '',
      }),
    );

    final output = await runner.run(AnalysisJobExecutionContext(
      job: extractionJob,
      dependencyResults: const <String, String>{},
    ));

    expect(aiService.extractionCallCount, 1);
    expect(jsonDecode(output)['normalizedQuestionText'], '规范题干');
  });

  test('first-pass job consumes extraction dependency without repeating OCR',
      () async {
    final aiService = service();
    final runner = AppAnalysisJobRunner(aiService);
    final question = QuestionRecord.draft(
      id: 'question-1',
      imagePath: '/tmp/question.jpg',
      subject: Subject.math,
      recognizedText: '',
    );
    final firstPassJob = job(
      id: 'question-1:first-pass',
      type: AiTaskType.firstPassAnalysis,
      dependencies: const <String>['question-1:extraction'],
      payloadJson: jsonEncode(<String, dynamic>{
        'question': question.toJson(),
      }),
    );

    final output = await runner.run(AnalysisJobExecutionContext(
      job: firstPassJob,
      dependencyResults: <String, String>{
        'question-1:extraction': jsonEncode(
          const AiQuestionExtractionResult(
            extractedQuestionText: '识别题干',
            normalizedQuestionText: '规范题干',
            subject: Subject.math,
          ).toJson(),
        ),
      },
    ));
    final updated = QuestionRecord.fromJson(
      jsonDecode(output) as Map<String, dynamic>,
    );

    expect(aiService.extractionCallCount, 0);
    expect(aiService.analysisCallCount, 1);
    expect(updated.analysisResult?.finalAnswer, 'x=2');
    expect(updated.savedExercises, isEmpty);
  });
}
