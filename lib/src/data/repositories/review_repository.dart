import 'package:smart_wrong_notebook/src/domain/models/review_log.dart';

abstract class ReviewRepository {
  Future<void> logReview(ReviewLog log);
  Future<List<ReviewLog>> getLogsForQuestion(String questionRecordId);
}

class InMemoryReviewRepository implements ReviewRepository {
  final List<ReviewLog> _logs = <ReviewLog>[];

  @override
  Future<List<ReviewLog>> getLogsForQuestion(String questionRecordId) async =>
      _logs.where((log) => log.questionRecordId == questionRecordId).toList();

  @override
  Future<void> logReview(ReviewLog log) async => _logs.add(log);
}
