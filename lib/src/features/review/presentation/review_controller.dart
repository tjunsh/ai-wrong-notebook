import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

class ReviewController {
  ReviewController({required QuestionRepository repository})
      : _repository = repository;
  factory ReviewController.fake() => ReviewController(repository: InMemoryQuestionRepository());

  final QuestionRepository _repository;

  Future<QuestionRecord> markMastered(String id) async {
    final question = await _repository.getById(id);
    if (question == null) {
      throw ArgumentError('Question not found: $id');
    }
    final updated = question.copyWith(
      masteryLevel: MasteryLevel.mastered,
      reviewCount: question.reviewCount + 1,
    );
    await _repository.update(updated);
    return updated;
  }

  Future<QuestionRecord> markReviewing(String id) async {
    final question = await _repository.getById(id);
    if (question == null) {
      throw ArgumentError('Question not found: $id');
    }
    final updated = question.copyWith(
      masteryLevel: MasteryLevel.reviewing,
      reviewCount: question.reviewCount + 1,
    );
    await _repository.update(updated);
    return updated;
  }

  Future<QuestionRecord> resetToNew(String id) async {
    final question = await _repository.getById(id);
    if (question == null) {
      throw ArgumentError('Question not found: $id');
    }
    final updated = question.copyWith(
      masteryLevel: MasteryLevel.newQuestion,
    );
    await _repository.update(updated);
    return updated;
  }

  Future<List<QuestionRecord>> getDueQuestions() async {
    final all = await _repository.listAll();
    return all.where((q) => q.masteryLevel != MasteryLevel.mastered).toList();
  }
}
