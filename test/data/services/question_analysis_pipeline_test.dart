import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/data/services/question_analysis_pipeline.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

void main() {
  const analysis = AnalysisResult(
    subject: Subject.math,
    finalAnswer: '答案',
    steps: <String>['步骤'],
    aiTags: <String>['标签'],
    knowledgePoints: <String>['知识点'],
    mistakeReason: '错因',
    studyAdvice: '建议',
  );

  test('unknown draft adopts the subject returned by extraction', () async {
    final service = TestAiAnalysisService(
      settingsRepository: InMemorySettingsRepository(),
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: 'Read the passage and answer the question.',
        normalizedQuestionText: 'Read the passage and answer the question.',
        subject: Subject.english,
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.english,
        finalAnswer: 'B',
        steps: <String>['Locate the supporting sentence.'],
        aiTags: <String>['reading'],
        knowledgePoints: <String>['detail comprehension'],
        mistakeReason: 'Missed the supporting sentence.',
        studyAdvice: 'Underline key details.',
      ),
    );
    final pipeline = QuestionAnalysisPipeline(service);
    final source = QuestionRecord.draft(
      id: 'unknown-english',
      imagePath: '/tmp/english.jpg',
      subject: Subject.unknown,
      recognizedText: '',
    );

    final result = await pipeline.analyze(source);

    expect(result.subject, Subject.english);
    expect(result.normalizedQuestionText, contains('Read the passage'));
  });

  test('pipeline extracts and returns a ready analysis-only record', () async {
    final service = TestAiAnalysisService(
      settingsRepository: InMemorySettingsRepository(),
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '识别题干',
        normalizedQuestionText: '规范题干',
        subject: Subject.physics,
      ),
      analysisResultValue: analysis,
    );
    final pipeline = QuestionAnalysisPipeline(service);
    final input = QuestionRecord.draft(
      id: 'question-1',
      imagePath: '/tmp/question.jpg',
      subject: Subject.math,
      recognizedText: '',
    );

    final result = await pipeline.analyze(input);

    expect(service.extractionCallCount, 1);
    expect(result.contentStatus, ContentStatus.ready);
    expect(result.normalizedQuestionText, '规范题干');
    expect(result.analysisResult?.finalAnswer, '答案');
    expect(result.savedExercises, isEmpty);
  });

  test('pipeline keeps independent candidate results in source order',
      () async {
    final service = TestAiAnalysisService(
      settingsRepository: InMemorySettingsRepository(),
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '',
        normalizedQuestionText: '',
      ),
      analysisResultValue: analysis,
      candidateAnalysisResults: const <AnalysisResult>[
        analysis,
        AnalysisResult(
          subject: Subject.math,
          finalAnswer: '第二题答案',
          steps: <String>['第二题步骤'],
          aiTags: <String>[],
          knowledgePoints: <String>[],
          mistakeReason: '',
          studyAdvice: '',
        ),
      ],
    );
    final pipeline = QuestionAnalysisPipeline(service);
    final input = QuestionRecord.draft(
      id: 'question-2',
      imagePath: '/tmp/question.jpg',
      subject: Subject.math,
      recognizedText: '1. 第一题\n2. 第二题',
    ).copyWith(
      splitResult: const QuestionSplitResult(
        sourceText: '1. 第一题\n2. 第二题',
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
        ],
      ),
    );

    final result = await pipeline.analyze(input);

    expect(service.analysisCallCount, 2);
    expect(result.candidateAnalyses, hasLength(2));
    expect(
      result.candidateAnalyses.map((item) => item.order),
      <int>[1, 2],
    );
    expect(result.analysisResult?.finalAnswer, '答案');
  });
}
