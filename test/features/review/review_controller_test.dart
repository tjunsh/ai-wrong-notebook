import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/features/review/presentation/review_controller.dart';

QuestionRecord _makeQuestion(String id, {MasteryLevel mastery = MasteryLevel.newQuestion, int reviewCount = 0}) {
  final now = DateTime.now();
  return QuestionRecord(
    id: id,
    imagePath: '/tmp/$id.jpg',
    subject: Subject.math,
    recognizedText: 'sample',
    correctedText: 'corrected',
    tags: const [],
    createdAt: now,
    updatedAt: now,
    lastReviewedAt: null,
    reviewCount: reviewCount,
    isFavorite: false,
    contentStatus: ContentStatus.ready,
    masteryLevel: mastery,
    analysisResult: null,
  );
}

void main() {
  late InMemoryQuestionRepository repo;
  late ReviewController controller;

  setUp(() {
    repo = InMemoryQuestionRepository();
    controller = ReviewController(repository: repo);
  });

  test('markMastered updates mastery and increments reviewCount', () async {
    await repo.saveDraft(_makeQuestion('q-1'));
    final result = await controller.markMastered('q-1');

    expect(result.masteryLevel, MasteryLevel.mastered);
    expect(result.reviewCount, 1);

    final persisted = await repo.getById('q-1');
    expect(persisted!.masteryLevel, MasteryLevel.mastered);
    expect(persisted.reviewCount, 1);
  });

  test('markReviewing transitions from newQuestion to reviewing', () async {
    await repo.saveDraft(_makeQuestion('q-1'));
    final result = await controller.markReviewing('q-1');

    expect(result.masteryLevel, MasteryLevel.reviewing);
    expect(result.reviewCount, 1);

    final persisted = await repo.getById('q-1');
    expect(persisted!.masteryLevel, MasteryLevel.reviewing);
  });

  test('markReviewing increments reviewCount when already reviewing', () async {
    await repo.saveDraft(_makeQuestion('q-1', mastery: MasteryLevel.reviewing, reviewCount: 3));
    final result = await controller.markReviewing('q-1');

    expect(result.masteryLevel, MasteryLevel.reviewing);
    expect(result.reviewCount, 4);
  });

  test('resetToNew sets mastery back to newQuestion', () async {
    await repo.saveDraft(_makeQuestion('q-1', mastery: MasteryLevel.mastered, reviewCount: 5));
    final result = await controller.resetToNew('q-1');

    expect(result.masteryLevel, MasteryLevel.newQuestion);
    expect(result.reviewCount, 5);
  });

  test('markMastered throws when question not found', () async {
    expect(() => controller.markMastered('nonexistent'), throwsArgumentError);
  });

  test('getDueQuestions excludes mastered questions', () async {
    await repo.saveDraft(_makeQuestion('q-1', mastery: MasteryLevel.newQuestion));
    await repo.saveDraft(_makeQuestion('q-2', mastery: MasteryLevel.reviewing));
    await repo.saveDraft(_makeQuestion('q-3', mastery: MasteryLevel.mastered));

    final due = await controller.getDueQuestions();
    expect(due.length, 2);
    expect(due.map((q) => q.id), containsAll(['q-1', 'q-2']));
  });

  test('full review lifecycle: new -> reviewing -> mastered', () async {
    await repo.saveDraft(_makeQuestion('q-1'));

    var result = await controller.markReviewing('q-1');
    expect(result.masteryLevel, MasteryLevel.reviewing);
    expect(result.reviewCount, 1);

    result = await controller.markMastered('q-1');
    expect(result.masteryLevel, MasteryLevel.mastered);
    expect(result.reviewCount, 2);

    final due = await controller.getDueQuestions();
    expect(due.where((q) => q.id == 'q-1'), isEmpty);
  });
}
