import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

class AnalysisController {
  AnalysisController(this._service);

  final AiAnalysisService _service;

  factory AnalysisController.fake() =>
      AnalysisController(AiAnalysisService.fake());

  Future<QuestionRecord> analyze({
    required String questionId,
    required String correctedText,
    required String subjectName,
  }) async {
    final analysis = await _service.analyzeQuestion(
      correctedText: correctedText,
      subjectName: subjectName,
    );

    return QuestionRecord.draft(
      id: questionId,
      imagePath: '/tmp/$questionId.jpg',
      subject: Subject.math,
      recognizedText: correctedText,
    ).copyWith(
      normalizedQuestionText: correctedText,
      contentStatus: ContentStatus.ready,
      analysisResult: analysis,
    );
  }
}
