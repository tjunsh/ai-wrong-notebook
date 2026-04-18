import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

class ReviewController {
  ReviewController();
  factory ReviewController.fake() => ReviewController();

  Future<QuestionRecord> markMastered(String id) async {
    final QuestionRecord base = QuestionRecord.draft(
      id: id,
      imagePath: '/tmp/$id.jpg',
      subject: Subject.math,
      recognizedText: 'sample',
    );

    return QuestionRecord(
      id: base.id,
      imagePath: base.imagePath,
      subject: base.subject,
      recognizedText: base.recognizedText,
      correctedText: base.correctedText,
      tags: base.tags,
      createdAt: base.createdAt,
      updatedAt: DateTime.now(),
      lastReviewedAt: DateTime.now(),
      reviewCount: 1,
      isFavorite: base.isFavorite,
      contentStatus: base.contentStatus,
      masteryLevel: MasteryLevel.mastered,
      analysisResult: base.analysisResult,
    );
  }
}
