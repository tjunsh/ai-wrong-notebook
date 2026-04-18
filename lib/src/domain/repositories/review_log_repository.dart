import 'package:smart_wrong_notebook/src/domain/models/review_log.dart';

abstract class ReviewLogRepository {
  Future<void> insert(ReviewLog log);
  Future<List<ReviewLog>> getByQuestionId(String questionId);
  Future<List<ReviewLog>> listAll();
}

class InMemoryReviewLogRepository implements ReviewLogRepository {
  final List<ReviewLog> _items = [];

  @override
  Future<void> insert(ReviewLog log) async => _items.add(log);

  @override
  Future<List<ReviewLog>> getByQuestionId(String questionId) async =>
      _items.where((l) => l.questionRecordId == questionId).toList();

  @override
  Future<List<ReviewLog>> listAll() async => List.unmodifiable(_items);
}
