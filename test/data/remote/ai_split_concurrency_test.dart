import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

class _ConcurrencyTrackingService extends TestAiAnalysisService {
  _ConcurrencyTrackingService()
      : super(
          settingsRepository: InMemorySettingsRepository(),
          extractionResult: const AiQuestionExtractionResult(
            extractedQuestionText: '',
            normalizedQuestionText: '',
          ),
          analysisResultValue: const AnalysisResult(
            subject: Subject.math,
            finalAnswer: '答案',
            steps: <String>['步骤'],
            aiTags: <String>[],
            knowledgePoints: <String>[],
            mistakeReason: '',
            studyAdvice: '',
          ),
        );

  int activeCalls = 0;
  int maxActiveCalls = 0;
  final List<String> startedTexts = <String>[];

  @override
  Future<AnalysisResult> analyzeExtractedQuestion({
    required String correctedText,
    required String subjectName,
    String? imagePath,
  }) async {
    activeCalls++;
    maxActiveCalls =
        activeCalls > maxActiveCalls ? activeCalls : maxActiveCalls;
    startedTexts.add(correctedText);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    activeCalls--;
    return analysisResultValue;
  }
}

class _GatewayFailureService extends TestAiAnalysisService {
  _GatewayFailureService()
      : super(
          settingsRepository: InMemorySettingsRepository(),
          extractionResult: const AiQuestionExtractionResult(
            extractedQuestionText: '',
            normalizedQuestionText: '',
          ),
          analysisResultValue: const AnalysisResult(
            subject: Subject.math,
            finalAnswer: '',
            steps: <String>[],
            aiTags: <String>[],
            knowledgePoints: <String>[],
            mistakeReason: '',
            studyAdvice: '',
          ),
        );

  int attempts = 0;

  @override
  Future<AnalysisResult> analyzeExtractedQuestion({
    required String correctedText,
    required String subjectName,
    String? imagePath,
  }) async {
    attempts++;
    throw AiAnalysisException('AI 服务请求失败 (HTTP 524)');
  }
}

void main() {
  test('split candidate analysis never runs more than one AI call at a time',
      () async {
    if (Platform.environment['AI_ENFORCE_SERIAL_GATE'] != 'true') {
      markTestSkipped(
        'Set AI_ENFORCE_SERIAL_GATE=true while implementing the serial queue.',
      );
      return;
    }
    final service = _ConcurrencyTrackingService();
    const splitResult = QuestionSplitResult(
      sourceText: '1. 第一题\n2. 第二题\n3. 第三题',
      strategy: QuestionSplitStrategy.numbered,
      candidates: <QuestionSplitCandidate>[
        QuestionSplitCandidate(
          id: 'candidate-1',
          order: 1,
          text: '第一题',
          strategy: QuestionSplitStrategy.numbered,
        ),
        QuestionSplitCandidate(
          id: 'candidate-2',
          order: 2,
          text: '第二题',
          strategy: QuestionSplitStrategy.numbered,
        ),
        QuestionSplitCandidate(
          id: 'candidate-3',
          order: 3,
          text: '第三题',
          strategy: QuestionSplitStrategy.numbered,
        ),
      ],
    );

    final results = await service.analyzeSplitCandidates(
      questionId: 'question-batch',
      subjectName: 'math',
      splitResult: splitResult,
    );

    expect(results, hasLength(3));
    expect(service.startedTexts, <String>['第一题', '第二题', '第三题']);
    expect(
      service.maxActiveCalls,
      1,
      reason: 'All AI work must use one global serial execution slot.',
    );
  });

  test('split candidate does not repeat an HTTP 524 analysis', () async {
    final service = _GatewayFailureService();
    const splitResult = QuestionSplitResult(
      sourceText: '第一题',
      strategy: QuestionSplitStrategy.fallback,
      candidates: <QuestionSplitCandidate>[
        QuestionSplitCandidate(
          id: 'candidate-1',
          order: 1,
          text: '第一题',
          strategy: QuestionSplitStrategy.fallback,
        ),
      ],
    );

    final results = await service.analyzeSplitCandidates(
      questionId: 'question-1',
      subjectName: 'math',
      splitResult: splitResult,
    );

    expect(service.attempts, 1);
    expect(results.single.isSuccessful, isFalse);
  });
}
