import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/shared/utils/composite_worksheet_detector.dart';

typedef CandidateAnalysisProgress = void Function(
  int completed,
  int total, {
  int failed,
});

class QuestionAnalysisPipeline {
  const QuestionAnalysisPipeline(this._service);

  final AiAnalysisService _service;

  bool needsExtraction(QuestionRecord source) {
    return source.normalizedQuestionText.isEmpty &&
        !_shouldAnalyzeImageDirectly(source);
  }

  bool requiresImageAnalysis(QuestionRecord source) {
    return _shouldAnalyzeImageDirectly(source) ||
        _shouldUseImageForAnalysis(source);
  }

  Future<QuestionRecord> analyze(
    QuestionRecord source, {
    AiQuestionExtractionResult? extractionResult,
    CandidateAnalysisProgress? onProgress,
  }) async {
    var working = source;
    final shouldAnalyzeImageDirectly = _shouldAnalyzeImageDirectly(working);

    if (needsExtraction(working)) {
      final extraction = extractionResult ??
          await _service.extractQuestionStructure(
            subjectName: working.subject.name,
            imagePath: working.imagePath,
            textHint: working.extractedQuestionText,
          );
      working = working.copyWith(
        extractedQuestionText: extraction.extractedQuestionText,
        normalizedQuestionText: extraction.normalizedQuestionText.isNotEmpty
            ? extraction.normalizedQuestionText
            : extraction.extractedQuestionText,
        subject: extraction.subject ?? working.subject,
        splitResult: extraction.splitResult,
      );
    }

    if (!(working.splitResult?.hasMultipleCandidates ?? false)) {
      final splitSeed = _splitSeedText(working);
      if (splitSeed.isNotEmpty) {
        final splitResult = await _service.splitQuestionCandidates(
          text: splitSeed,
          subjectName: working.subject.name,
        );
        if (splitResult.hasMultipleCandidates) {
          working = working.copyWith(splitResult: splitResult);
        }
      }
    }

    var candidatePayloads = <CandidateAnalysisPayload>[];
    CandidateAnalysisPayload? firstSuccessfulCandidate;
    if (working.splitResult?.hasMultipleCandidates ?? false) {
      onProgress?.call(
        0,
        working.splitResult!.candidates.length,
        failed: 0,
      );
      candidatePayloads = await _service.analyzeSplitCandidates(
        questionId: working.id,
        subjectName: working.subject.name,
        splitResult: working.splitResult!,
        imagePath: working.imagePath,
        onProgress: onProgress,
      );
      firstSuccessfulCandidate = candidatePayloads
          .where((payload) => payload.isSuccessful)
          .cast<CandidateAnalysisPayload?>()
          .firstWhere((payload) => payload != null, orElse: () => null);
      if (firstSuccessfulCandidate == null) {
        throw AiAnalysisException('多题解析全部失败，请重试；系统不会保存缺少解析的子题。');
      }
    }

    final shouldUseImageForAnalysis =
        shouldAnalyzeImageDirectly || _shouldUseImageForAnalysis(working);
    final textForAnalysis = shouldUseImageForAnalysis
        ? working.extractedQuestionText
        : working.correctedText;
    final analysis = firstSuccessfulCandidate?.analysisResult ??
        await _service.analyzeExtractedQuestion(
          correctedText: textForAnalysis,
          subjectName: working.subject.name,
          imagePath: shouldUseImageForAnalysis ? working.imagePath : null,
        );

    if (firstSuccessfulCandidate == null &&
        analysis.reconstructedQuestionText.trim().isNotEmpty) {
      working = working.copyWith(
        extractedQuestionText: analysis.reconstructedQuestionText,
        normalizedQuestionText: analysis.reconstructedQuestionText,
      );
    }

    return working.copyWith(
      contentStatus: ContentStatus.ready,
      analysisResult: analysis,
      savedExercises: const [],
      subject: analysis.subject ?? working.subject,
      aiTags: analysis.aiTags,
      aiKnowledgePoints: analysis.knowledgePoints,
      candidateAnalyses: candidatePayloads.map((payload) {
        return CandidateAnalysisSnapshot(
          candidateId: payload.candidateId,
          order: payload.order,
          questionText: payload.questionText,
          analysisResult: payload.analysisResult,
          savedExercises: const [],
          subject: payload.subject,
          aiTags: payload.aiTags,
          aiKnowledgePoints: payload.aiKnowledgePoints,
          status: payload.status,
          errorMessage: payload.errorMessage,
        );
      }).toList(),
    );
  }

  bool _shouldAnalyzeImageDirectly(QuestionRecord question) {
    final subject = question.subject;
    final text = question.correctedText.trim();
    if (subject == Subject.english ||
        subject == Subject.chinese ||
        subject == Subject.history ||
        subject == Subject.geography ||
        subject == Subject.politics) {
      return text.isEmpty ||
          isCompositeLanguageWorksheet(text, subject: subject);
    }
    return false;
  }

  bool _shouldUseImageForAnalysis(QuestionRecord question) {
    final text = question.correctedText.trim();
    if (_service.isGraphicalQuestion(
      text,
      question.subject.name,
      imagePath: question.imagePath,
    )) {
      return true;
    }
    if (text.length < 20) return true;

    return RegExp(
      '如图|图中|图示|下图|上图|左图|右图|根据图|观察图|函数图像|坐标系|电路图|表格|统计图|示意图',
    ).hasMatch(text);
  }

  String _splitSeedText(QuestionRecord question) {
    final normalized = question.normalizedQuestionText.trim();
    if (normalized.isNotEmpty) return normalized;
    final extracted = question.extractedQuestionText.trim();
    if (extracted.isNotEmpty) return extracted;
    return question.correctedText.trim();
  }
}
