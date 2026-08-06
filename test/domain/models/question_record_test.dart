import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

void main() {
  test('creates a clean draft when a user corrects question text', () {
    final record = QuestionRecord.draft(
      id: 'q-1',
      imagePath: '/tmp/q-1.jpg',
      subject: Subject.chemistry,
      recognizedText: '原识别题干',
    ).copyWith(
      contentStatus: ContentStatus.ready,
      analysisResult: const AnalysisResult(
        finalAnswer: '原答案',
        steps: <String>['原步骤'],
        aiTags: <String>['化学'],
        knowledgePoints: <String>['质量守恒'],
        mistakeReason: '原错因',
        studyAdvice: '原建议',
      ),
      aiTags: const <String>['化学'],
      aiKnowledgePoints: const <String>['质量守恒'],
      splitResult: const QuestionSplitResult(
        sourceText: '原识别题干',
        strategy: QuestionSplitStrategy.fallback,
        candidates: <QuestionSplitCandidate>[
          QuestionSplitCandidate(
            id: 'candidate-0',
            order: 1,
            text: '原识别题干',
            strategy: QuestionSplitStrategy.fallback,
          ),
        ],
      ),
    );

    final draft = record.createReanalysisDraft(
      correctedText: '混合物总质量为 15.8 g。',
    );

    expect(draft.id, record.id);
    expect(draft.imagePath, record.imagePath);
    expect(draft.subject, Subject.chemistry);
    expect(draft.correctedText, '混合物总质量为 15.8 g。');
    expect(draft.contentStatus, ContentStatus.processing);
    expect(draft.analysisResult, isNull);
    expect(draft.splitResult, isNull);
    expect(draft.candidateAnalyses, isEmpty);
    expect(draft.savedExercises, isEmpty);
    expect(draft.aiTags, isEmpty);
    expect(draft.aiKnowledgePoints, isEmpty);
  });

  test('rejects an empty corrected question text', () {
    final record = QuestionRecord.draft(
      id: 'q-1',
      imagePath: '/tmp/q-1.jpg',
      subject: Subject.chemistry,
      recognizedText: '原识别题干',
    );

    expect(
      () => record.createReanalysisDraft(correctedText: '  '),
      throwsArgumentError,
    );
  });
}
